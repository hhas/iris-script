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
        throw TypeCoercionError(value: value, coercion: self)
    }
}



public struct AsLiteralName: SwiftCoercion {
    
    public typealias SwiftType = Symbol
    
    public let name: Symbol = "name" // TO DO: what to call this? "literal_name"? "identifier"?
    
    public var swiftLiteralDescription: String { return "asLiteralName" }
    
    public init() {}
    
    public func coerce(_ value: Value, in env: Scope) throws -> SwiftType {
        if let result = value.asIdentifier() { return result }
        throw TypeCoercionError(value: value, coercion: self)
    }
}


public let asLiteralName = AsLiteralName()
