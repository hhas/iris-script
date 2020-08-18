//
//  stdlib_operators.swift
//
//  Coercions for converting native choices to/from Swift enums.
//
//  This file is auto-generated; do not edit directly.
//

import Foundation

public struct AsAssociativity: SwiftCoercion {
    
    public typealias SwiftType = Associativity
    
    public let name: Symbol = "Optional("associativity")"
    
    public var swiftLiteralDescription: String { return "asAssociativity" }

    public var literalDescription: String { return self.name.label }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        switch try asSymbol.coerce(value, in: scope) {
        case Symbol("left"): return .left
        case Symbol("right"): return .right
        case Symbol("none"): return .none
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

public struct AsHandlerScope: SwiftCoercion {
    
    public typealias SwiftType = HandlerScope
    
    public let name: Symbol = "Optional("handler_scope")"
    
    public var swiftLiteralDescription: String { return "asHandlerScope" }

    public var literalDescription: String { return self.name.label }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        switch try asSymbol.coerce(value, in: scope) {
        case Symbol("command"): return .command
        case Symbol("handler"): return .handler
        }
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        switch value {
        case .command: return Symbol("command")
        case .handler: return Symbol("handler")
        }
    }
}

public let asHandlerScope = AsHandlerScope()
