//
//  stdlib record stubs.swift
//
//  Swift structs that bridge to native records. Copy and modify as needed.
//
//  This file is auto-generated; do not edit directly.
//

import Foundation

public struct HandlerGlueRequirements {
    public let canError: Bool
    public let useScopes: [HandlerScope]
    public let swiftConstructor: Command?
    public let operatorDefinition: OperatorDefinition?
    
    public init(canError: Bool, useScopes: [HandlerScope], swiftConstructor: Command?, operator operatorDefinition: OperatorDefinition?) {
        self.canError = canError
        self.useScopes = useScopes
        self.swiftConstructor = swiftConstructor
        self.operatorDefinition = operatorDefinition
    }
}

public struct OperatorDefinition {
    public let pattern: Pattern
    public let precedence: Int
    public let associate: Associativity
    public let reducer: String?
    
    public init(pattern: Pattern, precedence: Int, associate: Associativity, reducer: String?) {
        self.pattern = pattern
        self.precedence = precedence
        self.associate = associate
        self.reducer = reducer
    }
}

public struct RecordGlueRequirements {
    public let canError: Bool
    public let swiftConstructor: Command?
    
    public init(canError: Bool, swiftConstructor: Command?) {
        self.canError = canError
        self.swiftConstructor = swiftConstructor
    }
}