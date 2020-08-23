//
//  coercion modifiers.swift
//  libiris
//

import Foundation


// TO DO: implement AND, OR, XOR, NOT on coercions (these would need to be multimethods that dispatch on type alone, given operands are either 2 booleans or 2 coercions; probably best to test for Coercion first, with special case for `nothing` if we wish to treat that as a Boolean false); Q. when coercing a value to one of `a OR b OR c`, should this attempt each coercion in turn? (one challenge is where value is an expr that may have side effects or be slow to evaluate; in principle the entire coercion should be passed to perform during final step of its operation, though that assumes robust implementation)


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

