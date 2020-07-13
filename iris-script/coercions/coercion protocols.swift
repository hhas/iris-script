//
//  coercion.swift
//  iris-lang
//

import Foundation

// TO DO: how to apply AND/OR/NOT to Coercion operands

// TO DO: worth interning all/some coercions? (might have performance benefits when evaling lists and records, as membership tests/intersects for any pair of [class-based] Coercions can be calculated once and hashed by instance identity, reducing subsequent tests to hash lookup + null check [although this is still slower than compile-time type-checking])


// TO DO: also need generic intersect (Q. which operand should determine returned SwiftType? probably rhs)


// important: coercions must always be non-lossy; i.e. while a simpler representation of user data can be coerced to a more complex representation, e.g. `"foo" as list → ["foo"]`, the opposite is not allowed, so `["foo"] as string` → UnsupportedCoercionError()


public protocol Coercion: Value {
    
    var name: Symbol { get } // TO DO: canonical vs reified name? // TO DO: how to support localization?
    
    // TO DO: how best to restrict/validate these? (i.e. generated code must be legal Swift syntax, and restricted to stated purpose [i.e. we need to avoid accidental/deliberate injection of arbitrary logic for obvious reasons])
    var swiftLiteralDescription: String { get }
    
    var swiftTypeDescription: String { get }

    func coerce(value: Value, in scope: Scope) throws -> Value
    
    func isa(_ coercion: Coercion) -> Bool
    
    func intersect(with coercion: Coercion) -> Coercion
    
    func swiftIntersect<T: SwiftCoercion>(with coercion: T) -> T
    
    func swiftCoerce<T>(value: Value, in scope: Scope) throws -> T
}

extension Coercion {
    
    public var swiftLiteralDescription: String { return "\(type(of:self))()" } // TO DO: need to generate Swift source for instantiating a Coercion (also, how to handle Coercions that don't declare SwiftCoercion conformance? presumably these'll need to go in an AsValue-like wrapper, or else be rejected outright)
    
    public var swiftTypeDescription: String { return "Value" }
    
    public var description: String { return "\(self.name.label)" } // TO DO: decide what description/debugDescription should show, versus pretty printing; description should include any constraints (constraints aren't included in canonical name)
    
    public static var nominalType: Coercion { return asCoercion }
    
    public func isa(_ coercion: Coercion) -> Bool {
        return self.name == coercion.name // TO DO: implement (same or subset)
    }
    
    public func intersect(with coercion: Coercion) -> Coercion {
        return coercion // TO DO: implement
    }
    
    public func swiftIntersect<T: SwiftCoercion>(with coercion: T) -> T {
        return coercion // TO DO: implement
    }
}



extension Coercion {
    
    public func swiftCoerce<T>(value: Value, in scope: Scope) throws -> T {
        guard let result = try self.coerce(value: value, in: scope) as? T else {
            throw UnsupportedCoercionError(value: value, coercion: self)
        }
        return result
    }
}

extension SwiftCoercion {
    
    public func swiftCoerce<T>(value: Value, in scope: Scope) throws -> T {
        guard let result = try self.unbox(value: value, in: scope) as? T else {
            throw UnsupportedCoercionError(value: value, coercion: self)
        }
        return result
    }
}


public protocol SwiftCoercion: Coercion {

    associatedtype SwiftType
    
    func box(value: SwiftType, in scope: Scope) -> Value
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType
}

extension SwiftCoercion {

    public var swiftTypeDescription: String { return String(describing: SwiftType.self) }
}



/*
protocol NativeCoercion: SwiftCoercion where SwiftType == Value { // TO DO: stupid type checker still insists NativeCoercion can only be used in generic methods, even though associatedtype SwiftType is fixed as Value
}*/



// bridging coercions whose swift type is also a native value only need to implement unbox()

extension SwiftCoercion where SwiftType: Value { // TO DO: this doesn't work on AsValue; why? (we can work around it with `extension SwiftCoercion where SwiftType == Value` below, but that's kinda kludgy)
        
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        return try self.unbox(value: value, in: scope)
    }
    
    public func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}

extension SwiftCoercion where SwiftType == Value {
    
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        return try self.unbox(value: value, in: scope)
    }
    
    public func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}


