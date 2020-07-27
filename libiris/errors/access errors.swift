//
//  access errors.swift
//  libiris
//

import Foundation


// Environment errors

public struct UnknownNameError: NativeError {
    
    public var description: String { return "Can’t find `\(self.name.label)` in \(self.scope)" }
    
    let name: Symbol
    let scope: Accessor
    
    public init(name: Symbol, in scope: Accessor) {
        self.name = name
        self.scope = scope
    }
}


public struct ImmutableScopeError: NativeError {
    
    public var description: String { return "Can’t modify `\(self.name.label)` in immutable \(self.scope)" }
    
    let name: Symbol
    let scope: Accessor
    
    public init(name: Symbol, in scope: Accessor) {
        self.name = name
        self.scope = scope
    }
}

public struct ExistingNameError: NativeError {
    
    public var description: String { return "Can’t replace existing value named `\(self.name.label)` in \(self.scope)" }
    
    let name: Symbol
    let scope: Accessor
    
    public init(name: Symbol, in scope: Accessor) {
        self.name = name
        self.scope = scope
    }
}

public struct ImmutableValueError: NativeError {
    
    public var description: String { return "Can’t modify immutable value named `\(self.name.label)` in \(self.scope)" }
    
    let name: Symbol
    let scope: Accessor
    
    public init(name: Symbol, in scope: Accessor) {
        self.name = name
        self.scope = scope
    }
}

