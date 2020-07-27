//
//  coercion errors.swift
//  libiris
//

import Foundation


// TO DO: when to use enum vs struct? (e.g. probably makes sense to group all coercion errors except null coercion as a single struct, with enum to indicate exact issue)

public protocol CoercionError: NativeError {
    
    var value: Value { get }
    var coercion: Coercion { get }
    
}

extension CoercionError {
    
    public var description: String {
        return "Can’t coerce the following \(self.value.nominalType) to \(self.coercion): `\(self.value)`"
    }
}

// TO DO: NullCoercionError must be rethrown as TypeCoercionError if not handled by optional/default modifier
    
public struct NullCoercionError: CoercionError { // value is `nothing`
    
    public let value: Value
    public let coercion: Coercion
    
    public var description: String {
        return "Can’t coerce `nothing` to \(self.coercion)."
    }
    
    public init(value: Value, coercion: Coercion) {
        self.value = value
        self.coercion = coercion
    }
}

public struct TypeCoercionError: CoercionError { // cannot coerce value to specified type
    
    public let value: Value
    public let coercion: Coercion
    
    public init(value: Value, coercion: Coercion) {
        self.value = value
        self.coercion = coercion
    }
}

public struct ConstraintCoercionError: CoercionError { // value is correct type, but out of allowable range
    
    public let value: Value
    public let coercion: Coercion
    
    public init(value: Value, coercion: Coercion) {
        self.value = value
        self.coercion = coercion
    }
}

