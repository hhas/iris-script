//
//  handler coercions.swift
//  libiris
//

import Foundation


// TO DO: AsHandler should be parameterizable with HandlerType; HandlerType should be constructable using `command returning type` operator, with underlying command `callable_type {named: name as optional symbol, input as record_type, output as coercion, is_event_handler as optional boolean with_default false}`; main challenge is deciding conformation


public struct AsHandler: SwiftCoercion {
    
    public typealias SwiftType = Callable
    
    public let name: Symbol = "handler"
    
    public var swiftLiteralDescription: String { return "asHandler" }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        // TO DO: FIX: `lowercase as handler` isn’t working correctly (`lowercase{}` is being evaluated here as a command, instead this should look up "lowercase" handler in env and return that)
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        if let v = value as? SwiftType { return v }
        throw TypeCoercionError(value: value, coercion: self)
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}

public let asHandler = AsHandler()



public struct AsHandlerType: SwiftCoercion {
    
    public typealias SwiftType = HandlerType
    
    public var name: Symbol = "handler_interface"
    
    public var swiftLiteralDescription: String { return "asHandlerType" }
    
    private func unpackSignature(_ value: Value, in env: Scope) throws -> (Symbol, [HandlerType.Parameter]) {
        let name: Symbol, parameters: [HandlerType.Parameter]
        switch value {
        case let command as Command: // name with optional params
            name = command.name
            parameters = try command.arguments.toRecordType(in: env).fields
        case let record as Record: // params only (anonymous callable) // TO DO: constructing anonymous functions natively is not currently supported
            name = nullSymbol
            parameters = try record.data.toRecordType(in: env).fields
        default:
            print("unpackSignature failed on", type(of:value)) // DEBUG
            throw TypeCoercionError(value: value, coercion: self)
        }
        return (name, parameters)
    }

    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        // TO DO: this implementation assumes the handler interface is defined using literal `name {param,…} returning type` syntax, which is not conducive constructing handler interfaces programmatically; for metaprogramming, provide a separate handler [interface] constructor that takes name, parameters, etc as arguments, as alternative to describing handler interface using literal commands (which, being literals, can’t be parameterized at run-time)
        // TO DO: sort out error reporting; this should catch individual errors when unpacking parameters and return type and rethrow chained to a coercion error describing the entire interface
        guard let command = value as? Command else { throw TypeCoercionError(value: value, coercion: self) }
        let name: Symbol, parameters: [HandlerType.Parameter], returnType: NativeCoercion
        if command.name == "returning" {
            let args = command.arguments
            if args.count != 2 {
                print("Bad `returning` operator")
                throw TypeCoercionError(value: command, coercion: self)
            }
            // TO DO: should really use standard argument match+unpack method here for consistency of behavior throughout
            (name, parameters) = try self.unpackSignature(args[0].value, in: scope)
            returnType = try asReturnType.coerce(args[1].value, in: scope) // return type may be `nothing`, in which case handler *always* returns `nothing`
        } else {
            (name, parameters) = try self.unpackSignature(command, in: scope)
            returnType = asAnything.nativeCoercion
        }
        return HandlerType(name: name, parameters: parameters, result: returnType, isEventHandler: false)
    }
}

public let asHandlerType = AsHandlerType()


//

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

public let asError = AsError()



public struct AsCoercion: SwiftCoercion {
    
    public typealias SwiftType = NativeCoercion
    
    public let name: Symbol = "coercion"
    
    public var swiftLiteralDescription: String { return "asCoercion" }
    
    public init() { }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        // caution: this will throw NullCoercionError when value is `nothing` (which is both a Value and a Coercion, aka `nullValue`, aka `asNothing`); to accept `nothing` as a coercion instead of rejecting it as a “missing value”, use `asReturnType`
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        if let v = value as? SwiftType { return v }
        // TO DO: also allow lists and records to act as descriptive “templates”, as in e.g. `foo as [string]`, `bar as {x as number,y as number,z as number}`
        throw TypeCoercionError(value: value, coercion: self)
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}

public let asCoercion = AsCoercion()

public let asReturnType = AsSwiftDefault(asCoercion, asNothing) // in most use-cases `nothing` (which is both a Value and a Coercion) signifies an omitted value so should trigger a NullCoercionError; however, when explicitly passed as the return type in handler interface it represents `asNothing` instead


