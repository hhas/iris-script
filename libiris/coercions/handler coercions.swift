//
//  handler coercions.swift
//  libiris
//

import Foundation



public struct AsHandler: SwiftCoercion {
    
    public typealias SwiftType = Handler
    
    public let name: Symbol = "handler"
    
    public var swiftLiteralDescription: String { return "asHandler" }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        if let v = value as? SelfEvaluatingProtocol { return try v.eval(in: scope, as: self) }
        if let v = value as? Handler { return v }
        throw TypeCoercionError(value: value, coercion: self)
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}


public struct AsError: SwiftCoercion {
    
    public typealias SwiftType = NativeError
    
    public let name: Symbol = "error"
    
    public var swiftLiteralDescription: String { return "asError" }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        if let v = value as? SelfEvaluatingProtocol { return try v.eval(in: scope, as: self) }
        if let v = value as? NativeError { return v }
        throw TypeCoercionError(value: value, coercion: self)
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}


public struct AsCoercion: SwiftCoercion {
    
    public typealias SwiftType = NativeCoercion
    
    public let name: Symbol = "coercion"
    
    public var swiftLiteralDescription: String { return "asCoercion" }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        do {
            if let v = value as? SelfEvaluatingProtocol { return try v.eval(in: scope, as: self) }
            if let v = value as? NativeCoercion { return v }
            throw TypeCoercionError(value: value, coercion: self)
        } catch is NullCoercionError {
            return nullValue
        }
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}


public let asHandler = AsHandler()
public let asError = AsError()
public let asCoercion = AsCoercion()

//


func unpackSignature(_ value: Value, in env: Scope) throws -> (Symbol, [HandlerInterface.Parameter]) {
    let name: Symbol, parameters: [HandlerInterface.Parameter]
    switch value {
    case let command as Command: // name with optional params
        name = command.name
        parameters = try unpackParameters(command.arguments, in: env)
    case let record as Record: // params only
        name = nullSymbol
        parameters = try unpackParameters(record.data, in: env)
    default:
        print("unpackSignature failed on", type(of:value))
        throw TypeCoercionError(value: value, coercion: asHandlerInterface)
    }
    return (name, parameters)
}

// TO DO: sort out errors; this should throw simple, descriptive errors indicating type of error; caller should raise full coercion error with complete signature


func unpackParameters(_ parameters: [Record.Field], in env: Scope) throws -> [HandlerInterface.Parameter] {
    var uniqueLabels = Set<Symbol>(), uniqueBindings = Set<Symbol>()
    let result = try parameters.map{ (label: Symbol, value: Value) throws -> HandlerInterface.Parameter in
        // label may be nullSymbol, in which case use binding name
        var label = label, binding: Symbol, coercion: NativeCoercion
        switch value {
        case let command as Command:
            if command.name == "as" {
                let args = command.arguments
                // TO DO: need simpler way to convert command to identifier
                guard args.count == 2, let name = args[0].value.asIdentifier() else {
                    print("Bad `as` operator.")
                    throw TypeCoercionError(value: Record(parameters, as: asRecord), coercion: asHandlerInterface)
                }
                binding = name
                coercion = try asCoercion.coerce(args[1].value, in: env)
            } else {
                guard let name = command.asIdentifier() else {
                    print("Bad name:",command)
                    throw TypeCoercionError(value: Record(parameters, as: asRecord), coercion: asHandlerInterface)
                }
                binding = name
                coercion = asValue.nativeCoercion
            }
        default:
            print("unpackParameters failed on", type(of:value),value)
            throw TypeCoercionError(value: try Record(parameters), coercion: asHandlerInterface)
        }
        if binding == nullSymbol { binding = label }
        if label == nullSymbol { label = binding }
        uniqueLabels.insert(label)
        uniqueBindings.insert(binding)
        return (label, binding, coercion)
    }
    //
    if uniqueLabels.contains(nullSymbol) || uniqueLabels.count != parameters.count || uniqueBindings.count != parameters.count {
        print("unpackParameters found bad labels")
        throw TypeCoercionError(value: Record(parameters, as: asRecord), coercion: asHandlerInterface)
    }
    return result
}

func unpackCoercion(_ value: Value, in env: Scope) throws -> NativeCoercion {
    // value may be Coercion, Command, or Record
    return try asCoercion.coerce(value, in: env)
}



func unpackHandlerInterface(_ signature: Value, in env: Scope, isEventHandler: Bool = false) throws -> HandlerInterface {
    let name: Symbol, parameters: [HandlerInterface.Parameter], returnType: NativeCoercion
    switch signature {
    case let command as Command:
        if command.name == "returning" {
            let args = command.arguments
            if args.count != 2 {
                print("Bad `returning` operator")
                throw TypeCoercionError(value: signature, coercion: asHandlerInterface)
            }
            (name, parameters) = try unpackSignature(args[0].value, in: env)
            returnType = try unpackCoercion(args[1].value, in: env)
        } else {
            (name, parameters) = try unpackSignature(command, in: env)
            returnType = asAnything.nativeCoercion
        }
    case let record as Record: // TO DO: how to distinguish parameters-only record, e.g. `{p1,p2}:action` from full HandlerInterface record {name:…,input:…,output:…,handler_type:#command}
        (name, parameters) = try unpackSignature(record, in: env)
        returnType = asAnything.nativeCoercion
    default:
        print("unpackHandlerInterface failed on",type(of:signature), signature)
        throw TypeCoercionError(value: signature, coercion: asHandlerInterface)
    }
    return HandlerInterface(name: name, parameters: parameters, result: returnType, isEventHandler: isEventHandler)
}


func commandToHandlerInterface(value: Command, in scope: Scope) throws -> HandlerInterface {
    let name: Symbol, parameters: [HandlerInterface.Parameter], returnType: NativeCoercion
    if value.name == "returning" {
        let args = value.arguments
        if args.count != 2 {
            print("Bad `returning` operator")
            throw TypeCoercionError(value: value, coercion: asHandlerInterface)
        }
        (name, parameters) = try unpackSignature(args[0].value, in: scope)
        returnType = try unpackCoercion(args[1].value, in: scope)
    } else {
        (name, parameters) = try unpackSignature(value, in: scope)
        returnType = asAnything.nativeCoercion
    }
    return HandlerInterface(name: name, parameters: parameters, result: returnType, isEventHandler: false)
}



public struct AsHandlerInterface: SwiftCoercion {
    
    public typealias SwiftType = HandlerInterface
    
    public var name: Symbol = "handler_interface"
    
    public var swiftLiteralDescription: String { return "asHandlerInterface" }

    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        if let v = value as? Command { return try commandToHandlerInterface(value: v, in: scope) }
        throw TypeCoercionError(value: value, coercion: self)
    }
}


public let asHandlerInterface = AsHandlerInterface()
