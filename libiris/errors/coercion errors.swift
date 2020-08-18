//
//  coercion errors.swift
//  libiris
//

import Foundation


// TO DO: when to use enum vs struct? (e.g. probably makes sense to group all coercion errors except null coercion as a single struct, with enum to indicate exact issue)

public protocol CoercionError: NativeError {
    
    var value: Value { get }
    var coercion: NativeCoercion { get }
    
}

extension CoercionError {
    
    // TO DO: this message is unhelpful when slot lookups fail, e.g. `a of {b:1}`:
    // «handler: ‘of’…» failed on command: ‘of’ {‘a’, {b: 1}}
    // Can’t coerce the following command to handler: ‘a’
    public var description: String {
        return "Can’t coerce the following \(self.value.nominalType) to \(self.coercion): \(self.value)"
    }
}

    
public struct NullCoercionError: CoercionError { // value is `nothing`
    
    // thrown by NullValue.eval(); may be handled by optional/default modifiers
    
    // caution: NullCoercionError must be rethrown as TypeCoercionError if not immediately intercepted by optional/default modifier; it must not propagate beyond the current coercion, e.g. `[1,nothing,3] as list of: optional number default 0` will return `[1,0,3]`, as the `optional` intercepts the NullCoercionError raised on `nothing as number`; however `[1,nothing,3] as optional list of: number` must fail (the `list` coercion catches the NullCoercionError raised on `nothing as number` and rethrows it as a permanent TypeCoercionError which the `optional` applied to the list coercion does not handle)

    public let value: Value
    public let coercion: NativeCoercion
    
    public var description: String {
        return "Can’t coerce `nothing` to \(self.coercion)."
    }
    
    public init(value: Value, coercion: NativeCoercion) {
        self.value = value
        self.coercion = coercion
    }
}

public struct TypeCoercionError: CoercionError { // cannot coerce value to specified type
    
    public let value: Value
    public let coercion: NativeCoercion
    
    public init(value: Value, coercion: NativeCoercion) {
        self.value = value
        self.coercion = coercion
    }
    
    public init<T: SwiftCoercion>(value: Value, coercion: T) {
        self.init(value: value, coercion: coercion.nativeCoercion)
    }
}

public struct ConstraintCoercionError: CoercionError { // value is correct type, but out of allowable range
    
    public let value: Value
    public let coercion: NativeCoercion
    
    public init(value: Value, coercion: NativeCoercion) {
        self.value = value
        self.coercion = coercion
    }
    
    public init<T: SwiftCoercion>(value: Value, coercion: T) {
        self.init(value: value, coercion: coercion.nativeCoercion)
    }
}

