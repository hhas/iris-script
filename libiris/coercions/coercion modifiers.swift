//
//  coercion modifiers.swift
//  libiris
//

import Foundation


// TO DO: move callability to separate coercion wrapper; this wrapper should be applied to parameterizable coercions when storing them in environment slots; once invoked (either by call or eval) the wrapper is discarded and only the underlying coercion is returned (TO DO: how to allow callable coercions to be passed around as handlers? is asHandler sufficient to keep them in callable form?)



public struct AsSwiftOptional<ElementType: SwiftCoercion>: SwiftCoercion {
    
    public typealias SwiftType = ElementType.SwiftType?
    
    public let name: Symbol = "optional" // TO DO
    
    public var swiftLiteralDescription: String { return "AsSwiftOptional(\(self.elementType.swiftLiteralDescription))" }
    
    public let elementType: ElementType
    
    public init(_ elementType: ElementType) {
        self.elementType = elementType
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        // NullValue self-evaluates by calling AsSwiftOptional.defaultValue(in:) and returning the result
       // if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        do {
            return try self.elementType.coerce(value, in: scope)
        } catch is NullCoercionError {
            return nil
        }
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        if let v = value { return self.elementType.wrap(v, in: scope) }
        return nullValue
    }
    
    public var nativeCoercion: NativeCoercion { // TO DO: why is SwiftCoercion's extension being called? (probably because of how it’s typed in NativizedCoercion: as <T:SwiftCoercion>)
        return AsOptional(self.elementType.nativeCoercion)
    }
}



public struct AsSwiftDefault<ElementType: SwiftCoercion>: SwiftCoercion {
    
    public typealias SwiftType = ElementType.SwiftType
    
    public let name: Symbol = "default" // TO DO
    
    public var swiftLiteralDescription: String {
        return "AsSwiftDefault(\(self.elementType.swiftLiteralDescription), \(formatSwiftLiteral(self.defaultValue)))"
    }
    
    public let elementType: ElementType
    public let defaultValue: ElementType.SwiftType
    
    public init(_ elementType: ElementType, _ defaultValue: ElementType.SwiftType) {
        self.elementType = elementType
        self.defaultValue = defaultValue
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        // NullValue self-evaluates by calling AsSwiftDefault.defaultValue(in:) and returning the result
        //if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        do {
            return try self.elementType.coerce(value, in: scope)
        } catch is NullCoercionError {
            return self.defaultValue
        }
    }
    
    // caution: wrap() doesn't caller to pass nil; it's assumed they will pass the default value itself
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return self.elementType.wrap(value, in: scope)
    }
}



public struct AsSwiftPrecis<ElementType: SwiftCoercion>: SwiftCoercion {
    
    public typealias SwiftType = ElementType.SwiftType
    
    public var name: Symbol { return Symbol(self._description) }
    
    public var swiftLiteralDescription: String {
        return "AsSwiftPrecis(\(self.elementType.swiftLiteralDescription), \(self._description.debugDescription))"
    }
    
    public let elementType: ElementType
    private let _description: String
    
    public init(_ elementType: ElementType, _ description: String) {
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


public struct AsOptional: NativeCoercion {
    
    public var swiftLiteralDescription: String {
        if self.defaultValue is NullValue {
            return "AsSwiftOptional(\(self.elementType.swiftLiteralDescription))"
        } else {
            return "AsSwiftDefault(\(self.elementType.swiftLiteralDescription), \(formatSwiftLiteral(self.defaultValue)))"
        }
    }
    
    public var literalDescription: String {
        if self.defaultValue is NullValue {
            return "optional {\(self.elementType.literalDescription)}"
        } else {
            return "optional {\(self.elementType.literalDescription), default: \(literal(for: self.defaultValue))}"
        }
    }
    
    public typealias SwiftType = Value
    
    public let name: Symbol = "optional"
    
    public let elementType: NativeCoercion
    private let defaultValue: Value
    
    public init(_ elementType: NativeCoercion, defaultValue: Value = nullValue) {
        self.elementType = elementType
        self.defaultValue = defaultValue
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        do { // NullValue will self-evaluate by throwing a NullCoercionError which is intercepted here
            return try self.elementType.coerce(value, in: scope)
        } catch is NullCoercionError {
            return self.defaultValue
        }
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return self.elementType.wrap(value, in: scope)
    }
}

let asOptional = AsOptional(asValue)

