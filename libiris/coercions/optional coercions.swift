//
//  optional coercions.swift
//  libiris
//

import Foundation


public struct AsSwiftOptional<ElementType: SwiftCoercion>: SwiftCoercion {
    
    public typealias SwiftType = ElementType.SwiftType?
    
    public let name: Symbol = "optional"
    
    public var swiftLiteralDescription: String { return "AsSwiftOptional(\(self.elementType.swiftLiteralDescription))" }
    
    public var literalDescription: String { return "‘optional’ {\(self.elementType.literalDescription)}" }
    
    public let elementType: ElementType
    
    public init(_ elementType: ElementType) {
        self.elementType = elementType
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        do { // NullValue will self-evaluate by throwing a NullCoercionError which is intercepted here
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
    
    public let name: Symbol = "default"
    
    public var swiftLiteralDescription: String {
        return "AsSwiftDefault(\(self.elementType.swiftLiteralDescription), \(formatSwiftLiteral(self.defaultValue)))"
    }
    
    public var literalDescription: String {
        return "‘optional’ {\(self.elementType.literalDescription), default: \(self.elementType.wrap(self.defaultValue, in: nullScope))}"
    }
    
    public let elementType: ElementType
    public let defaultValue: ElementType.SwiftType
    
    public init(_ elementType: ElementType, _ defaultValue: ElementType.SwiftType) {
        self.elementType = elementType
        self.defaultValue = defaultValue
    }
    
    public init(_ elementType: ElementType, defaultValue: Value) { // KLUDGE: AsOptional is currently unable to convert default native value to Swift value; TO DO: how to remedy this?
        self.init(elementType, try! elementType.coerce(defaultValue, in: nullScope))
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        do {
            return try self.elementType.coerce(value, in: scope)
        } catch is NullCoercionError {
            return self.defaultValue
        }
    }
    
    // caution: wrap() doesn't allow caller to pass nil; caller must pass defaultValue itself
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return self.elementType.wrap(value, in: scope)
    }
}



public struct AsOptional: NativeCoercion {
    
    public var swiftLiteralDescription: String {
        if self.defaultValue is NullValue {
            return "AsSwiftOptional(\(self.elementType.swiftLiteralDescription))"
        } else {
            return "AsSwiftDefault(\(self.elementType.swiftLiteralDescription), defaultValue: \(formatSwiftLiteral(self.defaultValue)))" // KLUDGE: see AsSwiftDefault TODO
        }
    }
    
    public var literalDescription: String {
        var arguments = [String]()
        if !(self.elementType is AsValue) { arguments.append(self.elementType.literalDescription) }
        if !(self.defaultValue is NullValue) { arguments.append("with_default: \(literal(for: self.defaultValue))") }
        return "‘\(self.name.label)’\(arguments.isEmpty ? "" : " {\(arguments.joined(separator:", "))}")"
    }
    
    public typealias SwiftType = Value
    
    public let name: Symbol = "optional"
    
    public let elementType: NativeCoercion
    private let defaultValue: Value
    
    public init(_ elementType: NativeCoercion = asValue, default defaultValue: Value = nullValue) {
        self.elementType = elementType
        self.defaultValue = defaultValue
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        do { 
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

