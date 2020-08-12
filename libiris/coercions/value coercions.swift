//
//  value coercions.swift
//  libiris
//

import Foundation

 // TO DO: lists and records that contain unevaluated expressions also need to self-evaluate; e.g. currently runScript("[foo].") returns `[‘foo’]` which is not what we want; alternative is to check if value isMemoizable: if false, always fully evaluate it

public struct AsAnything: SwiftCoercion, NativeCoercion { // any value or `nothing`; equivalent to `AsOptional(asValue)`

    public var swiftTypeDescription: String { return String(describing: SwiftType.self) }
    
    public typealias SwiftType = Value
    
    public let name: Symbol = "anything"
    
    public var swiftLiteralDescription: String { return "asAnything" }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        do {
            if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
            return value
        } catch is NullCoercionError {
            return nullValue
        }
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
    
    @inlinable public func coerceFunc(for valueType: Value.Type) -> CoerceFunc {
        return self.coerce
    }
}

public let asAnything = AsAnything()



public struct AsValue: SwiftCoercion, NativeCoercion { // any value except `nothing`

    public var swiftTypeDescription: String { return String(describing: SwiftType.self) }
    
    public typealias SwiftType = Value
    
    public let name: Symbol = "value"
    
    public var swiftLiteralDescription: String { return "asValue" }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        return value
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
    
    @inlinable public func coerceFunc(for valueType: Value.Type) -> CoerceFunc {
        return self.coerce
    }
}

public let asValue = AsValue()



public struct AsThunk<ElementType: SwiftCoercion>: SwiftCoercion {
    
    public typealias SwiftType = ElementType.SwiftType
    
    public let name: Symbol = "lazy"
    
    public var swiftLiteralDescription: String { return "AsThunk(\(self.elementType.swiftLiteralDescription))" }
    
    public let elementType: ElementType
    
    public init(_ elementType: ElementType) {
        self.elementType = elementType
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        fatalError()
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return Thunk(value: self.elementType.wrap(value, in: scope), in: scope, as: self.elementType)
    }
}

public let asThunk = AsThunk(asAnything)



public struct AsIs: SwiftCoercion { // no evaluation; value is returned unbound, so should either be evaluated by primitive handler in the current context, or thunked with that context if evaluation is to take place after the handler returns
    
    public typealias SwiftType = Value
    
    public let name: Symbol = "expression"
    
    public var swiftLiteralDescription: String { return "asIs" }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        return value
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}

public let asIs = AsIs()

