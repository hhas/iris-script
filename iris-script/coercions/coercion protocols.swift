//
//  coercion.swift
//  iris-lang
//

import Foundation


// TO DO: how to support localization?

func == (lhs: Coercion, rhs: Coercion) -> Bool {
    return lhs.name == rhs.name // TO DO: how to compare coercions for equality? (note: we need to avoid making Coercion protocol generic); also need to implement set operators (isMember, intersect, etc)
}

protocol Coercion: Value {
    
    var name: Symbol { get } // TO DO: Symbol? (canonical name should be case-insensitive)

    func coerce(value: Value, in scope: Scope) throws -> Value
}

extension Coercion {
    
    var description: String { return "\(self.name.name)" } // TO DO: decide what description/debugDescription should show, versus pretty printing; description should include any constraints (constraints aren't included in canonical name)
    
    var nominalType: Coercion { return asCoercion }
    

}


protocol BridgingCoercion: Coercion {

    associatedtype SwiftType
    
    func box(value: SwiftType, in scope: Scope) -> Value // TO DO: confirm that box() can never fail
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType
}


// bridging coercions whose swift type is also a native value only need to implement unbox()

extension BridgingCoercion where SwiftType: Value { // TO DO: this doesn't work on AsValue; why? (we can work around it with `extension BridgingCoercion where SwiftType == Value` below, but that's kinda kludgy)
        
    func coerce(value: Value, in scope: Scope) throws -> Value {
        return try self.unbox(value: value, in: scope)
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}

extension BridgingCoercion where SwiftType == Value {
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        return try self.unbox(value: value, in: scope)
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}


