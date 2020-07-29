//
//  atoms.swift
//  libiris
//

import Foundation



extension Bool: AtomicValue, LiteralConvertible {
    
    public var literalDescription: String { return self ? "true" : "false" }
    public var swiftLiteralDescription: String { return String(self) }
    
    public static let nominalType: NativeCoercion = asBool.nativeCoercion
    
    public func toBool(in scope: Scope, as coercion: NativeCoercion) throws -> Bool {
        return self
    }
}


public struct NullValue: AtomicValue, LiteralConvertible {
    
    public var literalDescription: String { return "nothing" }
    
    public var swiftLiteralDescription: String { return "nullValue" }
        
    public static let nominalType: NativeCoercion = asNothing
    
    public func eval<T: SwiftCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
        return try coercion.defaultValue(in: scope)
    }
}

public let nullValue = NullValue()

