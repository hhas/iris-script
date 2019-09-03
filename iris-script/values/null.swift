//
//  null.swift
//  iris-lang
//

import Foundation


// TO DO: might want to implement as enum, allowing specialized null values (e.g. `did_nothing`, `test_failed`) to be expressed


struct NullValue: Value { // expanding `nothing` always throws transient NullCoercionError; this may be intercepted by coercion modifiers to supply default value, otherwise it'll be rethrown as permanent EvaluationError
    
    // TO DO: need an easier way to rethrow NullCoercionError, regardless of which toTYPE method is called
    
    var swiftLiteralDescription: String { return "nullValue" }
    
    var description: String { return "nothing" }
    
    static let nominalType: Coercion = asNothing
    
    func toValue(in scope: Scope, as coercion: Coercion) throws -> Value {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    
    func toTYPE<T>(in scope: Scope, as coercion: Coercion) throws -> T {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    
    func toRecord(in scope: Scope, as coercion: RecordCoercion) throws -> Record {
        throw NullCoercionError(value: self, coercion: coercion) // TO DO: confirm this is correct (as opposed to returning an empty record); probably, as `optional record` requires null coercion error 
    }
}

let nullValue = NullValue()




struct NullAction: Value {
    
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
    
    func toRecord(in scope: Scope, as coercion: RecordCoercion) throws -> Record {
        throw NullCoercionError(value: self, coercion: coercion) // TO DO: confirm this is correct (as opposed to returning an empty record); probably, as `optional record` requires null coercion error
    }
}



let nullAction = NullAction()

