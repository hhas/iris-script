//
//  coercion modifiers.swift
//  libiris
//

import Foundation



public struct AsSwiftPrecis<ElementType: SwiftCoercion>: SwiftCoercion {
    
    public typealias SwiftType = ElementType.SwiftType
    
    public var name: Symbol { return Symbol(self._description) }
    
    public var swiftLiteralDescription: String {
        return "AsSwiftPrecis(\(self.elementType.swiftLiteralDescription), \(self._description.debugDescription))"
    }
    
    public let elementType: ElementType
    private let _description: String
    
    public init(_ elementType: ElementType, _ description: String) { // caution: description must be valid identifier
        self.elementType = elementType
        self._description = description
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        return try self.elementType.coerce(value, in: scope)
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return self.elementType.wrap(value, in: scope)
    }
}

