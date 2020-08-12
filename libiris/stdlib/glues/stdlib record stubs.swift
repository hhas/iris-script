//
//  stdlib record stubs.swift
//
//  Swift structs that bridge to native records. Copy and modify as needed.
//
//  This file is auto-generated; do not edit directly.
//

import Foundation

public struct OperatorSyntax {
    public let pattern: Pattern
    public let precedence: Int
    public let associate: Value
    public let reducer: Value
    
    public init(pattern: Pattern, precedence: Int, associate: Value, reducer: Value) {
        self.pattern = pattern
        self.precedence = precedence
        self.associate = associate
        self.reducer = reducer
    }
}