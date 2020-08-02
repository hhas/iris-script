//
//  value coercions.swift
//  libiris
//

import Foundation


public struct AsAnything: SwiftCoercion { // any value or `nothing`; equivalent to `AsOptional(asValue)`
    
    public typealias SwiftType = Value
    
    public let name: Symbol = "anything"
    
    public var swiftLiteralDescription: String { return "asAnything" }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        do {
            if let v = value as? SelfEvaluatingProtocol { return try v.eval(in: scope, as: self) }
            return value // TO DO: what about array and other collection types? should they also self-evaluate?
        } catch is NullCoercionError {
            return nullValue
        }
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}

public let asAnything = AsAnything()



public struct AsValue: SwiftCoercion { // any value except `nothing`
    
    public typealias SwiftType = Value
    
    public let name: Symbol = "value"
    
    public var swiftLiteralDescription: String { return "asValue" }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        if let v = value as? SelfEvaluatingProtocol { return try v.eval(in: scope, as: self) }
        return value
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
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



public struct AsIs: SwiftCoercion { // no evaluation
    
    public typealias SwiftType = Value
    
    public let name: Symbol = "expression" // TO DO
    
    public var swiftLiteralDescription: String { return "asIs" }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        return value
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}

public let asIs = AsIs()

