//
//  optional coercions.swift
//  iris-lang
//

import Foundation


// TO DO: need to decide naming convention

// TO DO: AsNullIntersection (empty set) that always throws on coerce/unbox


struct AsNothing: Coercion { // used in HandlerInterface.result to return `nothing`
    
    let name: Symbol = "nothing"
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        let _ = try asAnything.coerce(value: value, in: scope) // this still needs to evaluate value asAnything, discarding result (if value is scalar, it can be discarded immediately)
        return nullValue
    }
}

//

struct AsOptional: BridgingCoercion { // this returns native Value; for Optional<Value> use MayBeNil
    
    let name: Symbol = "optional"
    
    var description: String { return "\(self.coercion) or nothing" }
    
    typealias SwiftType = Value
    
    let coercion: Coercion
    
    init(_ coercion: Coercion) {
        self.coercion = coercion
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        do {
            return try self.coercion.coerce(value: value, in: scope)
        } catch is NullCoercionError {
            return nullValue
        }
    }
}

struct AsSwiftOptional<T: BridgingCoercion>: BridgingCoercion {
    
    let name: Symbol = "optional"
    
    var description: String { return "\(self.coercion) or nothing" }
    
    typealias SwiftType = T.SwiftType?
    
    let coercion: T
    
    init(_ coercion: T) {
        self.coercion = coercion
    }
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        do {
            return try self.coercion.coerce(value: value, in: scope)
        } catch is NullCoercionError {
            return nullValue
        }
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        do {
            return try self.coercion.unbox(value: value, in: scope)
        } catch is NullCoercionError {
            return nil
        }
    }
    func box(value: SwiftType, in scope: Scope) -> Value {
        guard let value = value else { return nullValue }
        return self.coercion.box(value: value, in: scope)
    }
}

//

struct AsDefault: Coercion {
    
    let name: Symbol = "default"
    
    var description: String { return "\(self.coercion) or \(self.defaultValue)" }
    
    let coercion: Coercion
    let defaultValue: Value
    
    init(_ coercion: Coercion = asValue, defaultValue: Value) {
        self.coercion = coercion
        self.defaultValue = defaultValue // TO DO: this should be member of coercion; how/where to check this? also need to consider how collections/exprs might be used here
    }
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        do {
            return try self.coercion.coerce(value: value, in: scope)
        } catch is NullCoercionError {
            return try self.coercion.coerce(value: self.defaultValue, in: scope)
        }
    }
}

struct AsSwiftDefault<T: BridgingCoercion>: BridgingCoercion {
    
    let name: Symbol = "default"
    
    var description: String { return "\(self.coercion) or \(self.defaultValue)" }
    
    typealias SwiftType = T.SwiftType?
    
    let coercion: T
    let defaultValue: Value
    
    init(_ coercion: T, defaultValue: Value) {
        self.coercion = coercion
        self.defaultValue = defaultValue // TO DO: this should be member of coercion; how/where to check this? also need to consider how collections/exprs might be used here
    }

    func coerce(value: Value, in scope: Scope) throws -> Value {
        do {
            return try self.coercion.coerce(value: value, in: scope)
        } catch is NullCoercionError {
            return try self.coercion.coerce(value: self.defaultValue, in: scope)
        }
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        do {
            return try self.coercion.unbox(value: value, in: scope)
        } catch is NullCoercionError {
            return try self.coercion.unbox(value: self.defaultValue, in: scope)
        }
    }
    func box(value: SwiftType, in scope: Scope) -> Value {
        guard let value = value else { return nullValue }
        return self.coercion.box(value: value, in: scope)
    }
}



let asNothing = AsNothing()

let asAnything = AsOptional(asValue)




struct AsEditable: BridgingCoercion {

    // experimental; in effect, environment binds a box containing the actual value, giving behavior similar to Swift's pass-by-reference semantics using structs
    
    let name: Symbol = "editable"
    
    var description: String { return "editable \(self.coercion)" }
    
    typealias SwiftType = EditableValue
    
    let coercion: Coercion // the type to which the EditableValue instance's content should be coerced when setting it
    
    init(_ coercion: Coercion = asAnything) {
        self.coercion = coercion
    }
    
    // seems a bit odd; goal here is really to wrap value in box; Q. when value is already editable, how do we avoid double-boxing? note that coercing a boxed value to a non-editable value needs to ask the value for an immutable representation of self
    
    // really need to think this through: AsEditable boxes the value; the resulting box is then bound in environment; getting the stored box retrieves it, evaling the boxed value updates the box's content to the resulting value and returns it (this is something to be aware of when passing the box between scopes)
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType { // TO DO: what if value is already editable? shouldn't this keep the same box?
        return EditableValue(try self.coercion.coerce(value: value, in: scope), as: self.coercion)
    }
}


let asEditable = AsEditable()

