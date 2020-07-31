//
//  native coercion wrapper.swift
//  libiris
//

import Foundation

// TO DO: Coercion.primitiveCoercion


public struct NativizedCoercion<ElementType: SwiftCoercion>: NativeCoercion {
    
    public typealias SwiftType = Value
    
    public var name: Symbol { return self.elementType.name }
    
    // TO DO: the returned Swift code may or may not be appropriate to context
    public var swiftLiteralDescription: String { return self.elementType.swiftLiteralDescription }
    
    public let elementType: ElementType
    
    public init(_ elementType: ElementType) {
        self.elementType = elementType
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        return try self.elementType.wrap(self.elementType.coerce(value, in: scope), in: scope)
    }
    public func wrap(_ value: Value, in scope: Scope) -> Value {
        return value
    }
}


public struct PrimitivizedCoercion: SwiftCoercion {
    
    public typealias SwiftType = Value
    
    public var name: Symbol { return self.elementType.name }
    
    // TO DO: the returned Swift code may or may not be appropriate to context
    public var swiftLiteralDescription: String { return self.elementType.swiftLiteralDescription }
    
    public let elementType: NativeCoercion
    
    public init(_ elementType: NativeCoercion) {
        self.elementType = elementType
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        return try self.elementType.coerce(value, in: scope)
    }
    public func wrap(_ value: Value, in scope: Scope) -> Value {
        return value
    }
}

