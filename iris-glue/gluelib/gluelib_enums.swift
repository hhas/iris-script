//
//  gluelib_enums.swift
//
//  Bridging code for primitive enums. This file is auto-generated; do not edit directly.
//

import Foundation
import iris

public struct AsAssociativity: SwiftCoercion {
    
    public typealias SwiftType = Associativity
    
    public let name: Symbol = "associativity"
    
    public var swiftLiteralDescription: String { return "asAssociativity" }

    public var literalDescription: String { return self.name.label }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        switch try asSymbol.coerce(value, in: scope) {
        case "left": return .left
        case "right": return .right
        case "none": return .left
        default: throw ConstraintCoercionError(value: value, coercion: self)
        }
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        switch value {
        case .left: return Symbol("left")
        case .right: return Symbol("right")
        case .none: return Symbol("none")
        }
    }
}

public let asAssociativity = AsAssociativity()
