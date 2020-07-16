//
//  handler coercions.swift
//  iris-script
//

import Foundation


// TO DO: coercions don't yet work right


func unpackSignature(_ value: Value, in env: Scope) throws -> (Symbol, [HandlerInterface.Parameter]) {
    let name: Symbol, parameters: [HandlerInterface.Parameter]
    switch value {
    case let command as Command: // name with optional params
        name = command.name
        parameters = try unpackParameters(command.arguments, in: env)
    case let record as Record: // params only
        name = nullSymbol
        parameters = try unpackParameters(record.fields, in: env)
    default:
        print("unpackSignature failed on", type(of:value))
        throw UnsupportedCoercionError(value: value, coercion: asHandlerInterface)
    }
    return (name, parameters)
}

// TO DO: sort out errors; this should throw simple, descriptive errors indicating type of error; caller should raise full coercion error with complete signature


func unpackParameters(_ parameters: [Record.Field], in env: Scope) throws -> [HandlerInterface.Parameter] {
    var uniqueLabels = Set<Symbol>(), uniqueBindings = Set<Symbol>()
    let result = try parameters.map{ (label: Symbol, value: Value) throws -> HandlerInterface.Parameter in
        // label may be nullSymbol, in which case use binding name
        var label = label, binding: Symbol, coercion: Coercion
        switch value {
        case let command as Command:
            if command.name == "as" {
                let args = command.arguments
                // TO DO: need simpler way to convert command to identifier
                guard args.count == 2, let name = args[0].value.asIdentifier() else {
                    print("Bad `as` operator.")
                    throw UnsupportedCoercionError(value: Record(parameters, as: asRecord), coercion: asHandlerInterface)
                }
                binding = name
                coercion = try args[1].value.swiftEval(in: env, as: asCoercion)
            } else {
                guard let name = command.asIdentifier() else {
                    print("Bad name:",command)
                    throw UnsupportedCoercionError(value: Record(parameters, as: asRecord), coercion: asHandlerInterface)
                }
                binding = name
                coercion = asValue
            }
        default:
            print("unpackParameters failed on", type(of:value),value)
            throw UnsupportedCoercionError(value: try Record(parameters), coercion: asHandlerInterface)
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
        throw UnsupportedCoercionError(value: Record(parameters, as: asRecord), coercion: asHandlerInterface)
    }
    return result
}

func unpackCoercion(_ value: Value, in env: Scope) throws -> Coercion {
    // value may be Coercion, Command, or Record
    return try value.swiftEval(in: env, as: asCoercion)
}



func unpackHandlerInterface(_ signature: Value, in env: Scope, isEventHandler: Bool = false) throws -> HandlerInterface {
    let name: Symbol, parameters: [HandlerInterface.Parameter], returnType: Coercion
    switch signature {
    case let command as Command:
        if command.name == "returning" {
            let args = command.arguments
            if args.count != 2 {
                print("Bad `returning` operator")
                throw UnsupportedCoercionError(value: signature, coercion: asHandlerInterface)
            }
            (name, parameters) = try unpackSignature(args[0].value, in: env)
            returnType = try unpackCoercion(args[1].value, in: env)
        } else {
            (name, parameters) = try unpackSignature(command, in: env)
            returnType = asAnything
        }
    case let record as Record: // TO DO: how to distinguish parameters-only record, e.g. `{p1,p2}:action` from full HandlerInterface record {name:…,input:…,output:…,handler_type:#command}
        (name, parameters) = try unpackSignature(record, in: env)
        returnType = asAnything
    default:
        print("unpackHandlerInterface failed on",type(of:signature), signature)
        throw UnsupportedCoercionError(value: signature, coercion: asHandlerInterface)
    }
    return HandlerInterface(name: name, parameters: parameters, result: returnType, isEventHandler: isEventHandler)
}



public let asHandlerInterface = AsHandlerInterface() // TO DO: handler interface can be coerced to/from Record (problem: records may also describe argument list in minimal handler sig; if coercion matches {name:,input:,output:} as handler interface, user will need to include a handler name or `returning` clause if they want it treated as arg list; alternative is we always treat records as arg lists, and use a command or other constructor to build a signature from a record)



public let nullHandlerInterface = HandlerInterface(name: nullSymbol, parameters: [], result: asAnything)



public struct AsHandlerInterface: SwiftCoercion {
    
    public let name: Symbol = "handler_interface"
    
    public typealias SwiftType = HandlerInterface
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        //print("AsHandlerInterface.unbox:", value)
        return try unpackHandlerInterface(value, in: scope)
    }

    
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        return try self.unbox(value: value, in: scope)
    }
    
    public func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}


public struct AsHandler: SwiftCoercion {
    
    public let name: Symbol = "procedure"
    
    public typealias SwiftType = Handler
    
    // TO DO: when should handlers capture their lexical scope? and when should that capture be strongref vs weakref?
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        let env = scope as! Environment // TO DO: fix (NativeHandler currently takes Environment argument [effectively an activation record]; why?)
        // TO DO: return strongrefd handler?
        
        // TO DO: update this
        
        switch value {
        case let handler as Handler: return handler
//        case let pair as Pair:
            //let interface = try pair.key.swiftEval(in: env, as: asHandlerInterface)
//            let interface = try unpackHandlerInterface(pair.key, in: env)
//            return NativeHandler(interface: interface, action: pair.value, in: env)
        case let block as Block:
            return NativeHandler(interface: nullHandlerInterface, action: block, in: env)
        default:
            print("AsHandler.unbox failed.")
            throw UnsupportedCoercionError(value: value, coercion: self)
        }
    }
    
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        return try self.unbox(value: value, in: scope)
    }
    
    public func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}

public let asHandler = AsHandler()

