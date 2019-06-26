//
//  complex coercions.swift
//  iris-lang
//

import Foundation

// TO DO: what would it take to replace current double-dispatch implementation with a [global] coercion table?


// TO DO: this is a little dicey as it assumes values cannot coerce to complex types; would be safer to implement Value.toComplex(in:as:), with the default implementation throwing if not same type (this allows values to implement their own toComplex where appropriate)

struct AsComplex<T: Value>: BridgingCoercion { // T must be concrete struct or class; abstract protocols aren't accepted
    
    let name: Symbol
    
    typealias SwiftType = T
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        if !(value is T) { throw UnknownCoercionError(value: value, coercion: self) }
        return value
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = value as? SwiftType else { throw UnknownCoercionError(value: value, coercion: self) }
        return result
    }
}


struct AsKey: BridgingCoercion { // unwraps Symbol as normalized String
    
    let name: Symbol = "name"
    
    typealias SwiftType = String
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        if !(value is Symbol) { throw UnknownCoercionError(value: value, coercion: self) }
        return value
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return Symbol(value)
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let name = value as? Symbol else { throw UnknownCoercionError(value: value, coercion: self) }
        return name.key
    }
}

struct AsSymbol: BridgingCoercion {
    
    var name: Symbol { return Symbol("name") } // avoid creating cycle between Symbol and AsSymbol when initializing them
    
    typealias SwiftType = Symbol
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        if !(value is Symbol) { throw UnknownCoercionError(value: value, coercion: self) }
        return value
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let name = value as? Symbol else { throw UnknownCoercionError(value: value, coercion: self) }
        return name
    }
}


struct AsHandler: BridgingCoercion { // (can't use AsComplex<Handler> as Handler isn't concrete type; however, we'll need some custom implementation anyway)
    
    let name: Symbol = "handler"
    
    typealias SwiftType = Handler
    
    // TO DO: when should handlers capture their lexical scope? and when should that capture be strongref vs weakref?
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        if !(value is Handler) { throw UnknownCoercionError(value: value, coercion: self) }
        // TO DO: return strongrefd handler?
        return value
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = value as? SwiftType else { throw UnknownCoercionError(value: value, coercion: self) }
        // TO DO: return strongrefd handler?
        return result
    }
}


// TO DO (complex types generally only coerce to Any or Self)
let asCommand = AsComplex<Command>(name: "command")
let asSymbol = AsSymbol()
let asKey = AsKey()
let asHandlerInterface = AsComplex<Command>(name: "handler_interface")
let asHandler = AsHandler()
let asBlock = AsComplex<Block>(name: "block")


// TO DO
let asParameter = asValue
let asIs = asAnything



extension Bool: Value {
    
    var nominalType: Coercion { return asBool }
    
    func toBool(in scope: Scope, as coercion: Coercion) throws -> Bool {
        return self
    }
}

let asBool = AsComplex<Bool>(name: "boolean")






struct AsCoercion: BridgingCoercion {
    
    let name: Symbol = "coercion"
    
    typealias SwiftType = Coercion
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        if !(value is Coercion) { throw UnknownCoercionError(value: value, coercion: self) }
        return value
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = value as? SwiftType else { throw UnknownCoercionError(value: value, coercion: self) }
        return result
    }
}


let asCoercion = AsCoercion() // can't use AsComplex<Coercion> as generics require concrete types, not protocols




let asRecord = AsComplex<Record>(name: "record")




struct AsError: BridgingCoercion {
    
    let name: Symbol = "error"
    
    typealias SwiftType = NativeError
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        if !(value is Coercion) { throw UnknownCoercionError(value: value, coercion: self) }
        return value
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = value as? SwiftType else { throw UnknownCoercionError(value: value, coercion: self) }
        return result
    }
}

let asError = AsError()

