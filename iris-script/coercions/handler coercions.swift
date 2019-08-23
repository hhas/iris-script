//
//  handler coercions.swift
//  iris-script
//

import Foundation


// TO DO: coercions don't yet work right


func unpackSignature(_ value: Value, in env: Environment) throws -> (Symbol, [HandlerInterface.Parameter]) {
    let name: Symbol, parameters: [HandlerInterface.Parameter]
    switch value {
    case let command as Command: // name with optional params
        name = command.name
        parameters = try unpackParameters(command.arguments, in: env)
    case let record as Record: // params only
        name = nullSymbol
        parameters = try unpackParameters(record.fields, in: env)
    default:
        throw UnsupportedCoercionError(value: value, coercion: asHandlerInterface)
    }
    return (name, parameters)
}

func unpackParameters(_ parameters: [Record.Field], in env: Environment) throws -> [HandlerInterface.Parameter] {
    return try parameters.map{ (label: Symbol, value: Value) throws -> HandlerInterface.Parameter in
        // label may be nullSymbol, in which case use binding name
        let binding: Symbol, coercion: Coercion
        switch value {
        case let command as Command:
            if command.name == "as" {
                let args = command.arguments
                guard args.count != 2, let cmd = args[0].value as? Command, cmd.arguments.isEmpty else {
                    throw UnsupportedCoercionError(value: try Record(parameters), coercion: asHandlerInterface)
                }
                binding = cmd.name
                coercion = try args[1].value.swiftEval(in: env, as: asCoercion)
            } else {
                if !command.arguments.isEmpty {
                    throw UnsupportedCoercionError(value: try Record(parameters), coercion: asHandlerInterface)
                }
                binding = command.name
                coercion = asValue
            }
        default:
            throw UnsupportedCoercionError(value: try Record(parameters), coercion: asHandlerInterface)
        }
        return (label, binding, coercion)
    }
    //
}

func unpackCoercion(_ value: Value, in env: Environment) throws -> Coercion {
    // value may be Coercion, Command, or Record
    return try value.swiftEval(in: env, as: asCoercion)
}



func unpackHandlerInterface(_ signature: Value, in env: Environment, isEventHandler: Bool = false) throws -> HandlerInterface {
    let name: Symbol, parameters: [HandlerInterface.Parameter], returnType: Coercion
    switch signature {
    case let command as Command:
        if command.name == "returning" {
            let args = command.arguments
            if args.count != 2 {
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
        throw UnsupportedCoercionError(value: signature, coercion: asHandlerInterface)
    }
    return HandlerInterface(name: name, parameters: parameters, result: returnType, isEventHandler: isEventHandler)
}



let asHandlerInterface = AsComplex<HandlerInterface>(name: "handler_interface") // TO DO: handler interface can be coerced to/from Record



let nullHandlerInterface = HandlerInterface(name: nullSymbol, parameters: [], result: asAnything)



struct AsHandler: SwiftCoercion {
    
    let name: Symbol = "handler"
    
    typealias SwiftType = Handler
    
    // TO DO: when should handlers capture their lexical scope? and when should that capture be strongref vs weakref?
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        let env = scope as! Environment // TO DO: fix
        // TO DO: return strongrefd handler?
        switch value {
        case let handler as Handler: return handler
        case let pair as Pair:
            //let interface = try pair.key.swiftEval(in: env, as: asHandlerInterface)
            let interface = try unpackHandlerInterface(pair.key, in: env)
            return NativeHandler(interface: interface, action: pair.value, in: env)
        case let block as Block:
            return NativeHandler(interface: nullHandlerInterface, action: block, in: env)
        default: throw UnsupportedCoercionError(value: value, coercion: self)
        }
    }
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        return try self.unbox(value: value, in: scope)
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}

let asHandler = AsHandler()

