//
//  coercion.swift
//  iris-lang
//

import Foundation

// TO DO: worth interring all/some coercions? (might have performance benefits when evaling lists and records, as membership tests/intersects for any pair of [class-based] Coercions can be calculated once and hashed by instance identity, reducing subsequent tests to hash lookup + null check [although this is still slower than compile-time])


// TO DO: also need generic intersect (Q. which operand should determine returned SwiftType? probably rhs)



protocol Coercion: Value {
    
    var name: Name { get } // TO DO: canonical vs reified name? // TO DO: how to support localization?

    func coerce(value: Value, in scope: Scope) throws -> Value
    
    func isa(_ coercion: Coercion) -> Bool
    
    func intersect(with coercion: Coercion) -> Coercion
    
    func swiftIntersect<T: SwiftCoercion>(with coercion: T) -> T
    
}

extension Coercion {
    
    var description: String { return "\(self.name.label)" } // TO DO: decide what description/debugDescription should show, versus pretty printing; description should include any constraints (constraints aren't included in canonical name)
    
    var nominalType: Coercion { return asCoercion }
    
    func isa(_ coercion: Coercion) -> Bool {
        return self.name == coercion.name // TO DO: implement (same or subset)
    }
    
    func intersect(with coercion: Coercion) -> Coercion {
        return coercion // TO DO: implement
    }
    
    func swiftIntersect<T: SwiftCoercion>(with coercion: T) -> T {
        return coercion // TO DO: implement
    }
}


protocol SwiftCoercion: Coercion {

    associatedtype SwiftType
    
    func box(value: SwiftType, in scope: Scope) -> Value
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType
}


// bridging coercions whose swift type is also a native value only need to implement unbox()

extension SwiftCoercion where SwiftType: Value { // TO DO: this doesn't work on AsValue; why? (we can work around it with `extension SwiftCoercion where SwiftType == Value` below, but that's kinda kludgy)
        
    func coerce(value: Value, in scope: Scope) throws -> Value {
        return try self.unbox(value: value, in: scope)
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}

extension SwiftCoercion where SwiftType == Value {
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        return try self.unbox(value: value, in: scope)
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}


