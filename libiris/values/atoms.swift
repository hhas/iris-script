//
//  atoms.swift
//  iris-lang
//

import Foundation



extension Bool: AtomicValue, LiteralConvertible {
    
    public var literalDescription: String { return self ? "true" : "false" }
    public var swiftLiteralDescription: String { return String(self) }
    
    public static let nominalType: Coercion = asBool
    
    public func toBool(in scope: Scope, as coercion: Coercion) throws -> Bool {
        return self
    }
}



// TO DO: might want to implement as enum, allowing specialized null values (e.g. `did_nothing`, `test_failed`) to be expressed

public struct NullValue: AtomicValue, LiteralConvertible { // expanding `nothing` always throws transient NullCoercionError; this may be intercepted by coercion modifiers to supply default value, otherwise it'll be rethrown as permanent EvaluationError
    
    // TO DO: need an easier way to rethrow NullCoercionError, regardless of which toTYPE method is called
    
    public var literalDescription: String { return "nothing" }
    public var swiftLiteralDescription: String { return "nullValue" }
        
    public static let nominalType: Coercion = asNothing
    
    public func toValue(in scope: Scope, as coercion: Coercion) throws -> Value {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    
    public func toTYPE<T>(in scope: Scope, as coercion: Coercion) throws -> T {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    
    public func toRawRecord(in scope: Scope, as coercion: RecordCoercion) throws -> Record {
        throw NullCoercionError(value: self, coercion: coercion) // TO DO: confirm this is correct (as opposed to returning an empty record); probably, as `optional record` requires null coercion error 
    }
}

public let nullValue = NullValue()

