//
//  literal coercions.swift
//  libiris
//

import Foundation



public struct AsLiteral<T: Value>: SwiftCoercion { // caution: this only works for values that have native syntax (number, string, list, command, etc), not for values that require a constructor command (e.g. range/thru) // TO DO: also define AsLiteralCommand that allows command name and operands to be matched? (while this will be limited due to lack of vararg support in generics, in practice we really only need unary and binary matching as its main use will be matching operator exprs, most of which take one or two operands; alternatively, we could take AsRecord as argument, although that wouldn't support unboxing)
    
    public var swiftLiteralDescription: String { return "\(type(of: self))()" }

    public var name: Symbol { return T.nominalType.name } // TO DO: what should this be?
    
    public var description: String { return "literal \(self.name.label)" }
    
    // if the input Value is an instance of T, it is passed thru as-is without evaluation, otherwise an error is thrown // TO DO: Value.eval() will bypass this (another reason it needs to go away)
    
    public typealias SwiftType = T
    
    public init() { }
    
    public func coerce(_ value: Value, in env: Scope) throws -> SwiftType {
        // important: this type checks then returns the value as-is, without evaluation; e.g. used to get a literal command
        if let result = value as? SwiftType { return result }
        if value is NullValue { // TO DO: this smells
            throw NullCoercionError(value: value, coercion: self.nativeCoercion)
        } else {
            throw TypeCoercionError(value: value, coercion: self)
        }
    }
}



public struct AsLiteralName: SwiftCoercion {
    
    public typealias SwiftType = Symbol
    
    public let name: Symbol = "name" // TO DO: what to call this? "literal_name"? "identifier"?
    
    public var swiftLiteralDescription: String { return "asLiteralName" }
    
    public init() {}
    
    public func coerce(_ value: Value, in env: Scope) throws -> SwiftType {
        if let result = value.asIdentifier() { return result }
        if value is NullValue {
            throw NullCoercionError(value: value, coercion: self.nativeCoercion)
        } else {
            throw TypeCoercionError(value: value, coercion: self)
        }
    }
}


public let asLiteralName = AsLiteralName()




extension NullValue: SwiftCoercion, NativeCoercion { // used as return type where handler returns `nothing`
    
    public var name: Symbol { return "nothing" }
    
    //public var swiftLiteralDescription: String { return "asNothing" }
    
    public typealias SwiftType = Value
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        // calling AsNothing.unbox() is [presumably] an implementation error // TO DO: should it return nullValue instead? or is it best to have explicit error, assuming calling this method is always a bug?
        throw InternalError(description: "AsNothing.unbox() is not supported.")
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return nullValue
    }
}

public typealias AsNothing = NullValue

public let asNothing = nullValue //AsNothing()

