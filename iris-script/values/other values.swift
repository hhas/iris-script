//
//  other values.swift
//  iris-lang
//

import Foundation


struct NullValue: Value { // expanding `nothing` always throws transient NullCoercionError; this may be intercepted by coercion modifiers to supply default value, otherwise it'll be rethrown as permanent EvaluationError
    
    var description: String { return "nothing" }
    
    let nominalType: Coercion = asNothing
    
    func toValue(in scope: Scope, as coercion: Coercion) throws -> Value {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    
    func toScalar(in scope: Scope, as coercion: Coercion) throws -> ScalarValue {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    
    func toString(in scope: Scope, as coercion: Coercion) throws -> String {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    
    func toList(in scope: Scope, as coercion: CollectionCoercion) throws -> List {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    
    func toArray<T: BridgingCollectionCoercion>(in scope: Scope, as coercion: T) throws -> [T.ElementCoercion.SwiftType] {
        throw NullCoercionError(value: self, coercion: coercion)
    }
}

let nullValue = NullValue()

//let didNothing = DidNothing() // TO DO: rename nullAction; similar in implementation to nullValue, but can be detected by `else` clause to trigger alternate action

