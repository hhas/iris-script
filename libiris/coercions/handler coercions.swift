//
//  handler coercions.swift
//  libiris
//

import Foundation



public struct AsHandler: SwiftCoercion {
    
    public typealias SwiftType = Callable
    
    public let name: Symbol = "handler"
    
    public var swiftLiteralDescription: String { return "asHandler" }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        // TO DO: is this appropriate? should the order of tests be reversed? (i.e. if value is Callable, don't eval it? but if we don't eval it, how can we ensure it strongly binds its lexical scope to form closure? we probably need to eval it, and trust eval to do the right thing in case of, e.g., callable coercions which should remain in callable form if coercion is asHandler, but discard the callable wrapper if not)
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        if let v = value as? SwiftType { return v }
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
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        if let v = value as? SwiftType { return v }
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
            if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
            if let v = value as? SwiftType { return v }
            throw TypeCoercionError(value: value, coercion: self)
        } catch is NullCoercionError {
            return nullValue // TO DO: not entirely sure about this: NullValue is a NativeCoercion, but only intended for use as return type to indicate that nothing is returned (since native handlers that do not declare an explicit return type will automatically return the result of the last expression evaluated, i.e. their return type is `anything`); used anywhere else, however, `nothing` is intended to indicate an omitted value (i.e. throw NullCoercionError and leave it to parent coercion, if any, to substitute with default value or else rethrow as a permanent TypeCoercionError)
        }
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}


public let asHandler = AsHandler()
public let asError = AsError()
public let asCoercion = AsCoercion()


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

// TO DO: for metaprogramming, may be better to provide a separate constructor handler that takes name, parameters, etc as arguments, avoiding need to compose out of literal commands (which, being literals, can’t be parameterized at run-time)
func handlerInterface(for command: Command, in scope: Scope) throws -> HandlerInterface {
    let name: Symbol, parameters: [HandlerInterface.Parameter], returnType: NativeCoercion
    if command.name == "returning" {
        let args = command.arguments
        if args.count != 2 {
            print("Bad `returning` operator")
            throw TypeCoercionError(value: command, coercion: asHandlerInterface)
        }
        // TO DO: should really use standard argument match+unpack method here for consistency of behavior throughout
        (name, parameters) = try unpackSignature(args[0].value, in: scope)
        returnType = try asCoercion.coerce(args[1].value, in: scope)
    } else {
        (name, parameters) = try unpackSignature(command, in: scope)
        returnType = asAnything.nativeCoercion
    }
    return HandlerInterface(name: name, parameters: parameters, result: returnType, isEventHandler: false)
}



public struct AsHandlerInterface: SwiftCoercion {
    
    public typealias SwiftType = HandlerInterface
    
    public var name: Symbol = "handler_interface"
    
    public var swiftLiteralDescription: String { return "asHandlerInterface" }

    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        if let v = value as? Command { return try handlerInterface(for: v, in: scope) }
        throw TypeCoercionError(value: value, coercion: self)
    }
}


public let asHandlerInterface = AsHandlerInterface()
