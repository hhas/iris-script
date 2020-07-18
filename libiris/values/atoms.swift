//
//  atoms.swift
//  iris-lang
//

import Foundation



extension Bool: AtomicValue {
    
    public var swiftLiteralDescription: String { return String(self) }
    
    public static let nominalType: Coercion = asBool
    
    public func toBool(in scope: Scope, as coercion: Coercion) throws -> Bool {
        return self
    }
}



// TO DO: might want to implement as enum, allowing specialized null values (e.g. `did_nothing`, `test_failed`) to be expressed

public struct NullValue: AtomicValue { // expanding `nothing` always throws transient NullCoercionError; this may be intercepted by coercion modifiers to supply default value, otherwise it'll be rethrown as permanent EvaluationError
    
    // TO DO: need an easier way to rethrow NullCoercionError, regardless of which toTYPE method is called
    
    public var swiftLiteralDescription: String { return "nullValue" }
    
    public var description: String { return "nothing" }
    
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




struct NullAction: AtomicValue { // TO DO: get rid of this? (need to make decision on flow control operators and whether or not it’s practical to compose using independent `…else…` operator)
    
    // TO DO: need an easier way to rethrow NullCoercionError, regardless of which toTYPE method is called
    
    var swiftLiteralDescription: String { return "nullAction" }
    
    var description: String { return "did_nothing" }
    
    static let nominalType: Coercion = asNothing // TO DO: not sure about this - did_nothing should always reduce to nothing
    
    func toValue(in scope: Scope, as coercion: Coercion) throws -> Value {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    
    func toTYPE<T>(in scope: Scope, as coercion: Coercion) throws -> T {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    
    func toRawRecord(in scope: Scope, as coercion: RecordCoercion) throws -> Record {
        throw NullCoercionError(value: self, coercion: coercion) // TO DO: confirm this is correct (as opposed to returning an empty record); probably, as `optional record` requires null coercion error
    }
}



let nullAction = NullAction()


