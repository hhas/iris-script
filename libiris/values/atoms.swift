//
//  atoms.swift
//  libiris
//

import Foundation



extension Bool: AtomicValue {
    
    public var literalDescription: String { return self ? "true" : "false" }
    
    public var swiftLiteralDescription: String { return String(self) }
    
    public static let nominalType: NativeCoercion = asBool.nativeCoercion
}


public struct NullValue: AtomicValue, SelfEvaluatingProtocol {
    
    public var literalDescription: String { return "nothing" }
    
    public var swiftLiteralDescription: String { return "nullValue" }
    
    public static let nominalType: NativeCoercion = asNothing
    
    public func eval<T: SwiftCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
        throw NullCoercionError(value: self, coercion: coercion.nativeCoercion)
    }
}

public let nullValue = NullValue()

