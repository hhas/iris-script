//
//  editable value.swift
//  iris-lang
//

import Foundation


// Q. need to make sure values don't get double-boxed by accident (e.g. EditableValue.set(EditableValue(…)), or when evaling the boxed value returns another box); lastly, we do need to consider how native code (bind-once + editable boxes) will cross-compile to Swift (let/var + pass-by-value structs, pass-by-reference classes, and reference-backed structs)

// Q. what about editable collections? may be more efficient to implement as dedicated EditableTYPE classes, which box or extend Swift's Foundation Array/Dictionary/Set classes, in which case EditableValue probably wants to be a protocol instead


// to keep mutability semantics conceptually simple, there should be no distinction between mutable value and mutable storage. All environments slots are write-once, so inherently immutable; [im]mutability is purely a function of the content of a slot: if the slot's value allows editability, either because it's an EditableValue 'box' or something equivalent, then attributes of that value [if it's a list or record] should appear mutable as well. The simplest [though not necessarily efficient] way to achieve this is to replace the box's current value with the new value. If implementing a more parsimonious mechanism [to minimize CPU overheads due to copying] where the box's value is itself mutatable [e.g. a struct with a `var data:Array<>`] then this mutation may need to be mediated by the box—what we don't want is for the mutable struct to 'escape' into an immutable context; i.e. there should be no equivalent to Swift's storing a mutable class in a `let` slot, or an immutable list in an editable box. (At least with Swift collection structs, their copy-on-write[-if-needed] behavior should protect against shared state escaping editable boundaries.) One option may be for list/record mutator methods to return the modified value (either a new value or the current value with in-place changes) which the editable box automatically stores in place of the previous version (though we'll need to watch out for excessive copying, as Swift is liable to think the underlying Array is not unique and so re-copy it on every write)


class EditableValue: Handler, Mutator {
    
    // Handler and Accessor behaviors are pass-thrus to the underlying Value
    
    let nominalType: Coercion = asEditable
    
    var description: String { return "editable \(self.data)" }
    
    private(set) var data: Value
    private let coercion: Coercion // the type of the underlying value
    
    init(_ data: Value, as coercion: Coercion) { // called by AsEditable
        self.data = data
        self.coercion = coercion
    }
    
    //
    
    func eval(in scope: Scope, as coercion: Coercion) throws -> Value {
        let result = try self.data.eval(in: scope, as: coercion) // TO DO: this needs to intersect the given coercion with self.coercion and pass the result to self.data.eval(…); Q. how should intersecting [e.g.] AsScalar with AsList work out?
        self.data = result
        return result
    }
    
    func swiftEval<T: BridgingCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
        let result = try self.eval(in: scope, as: coercion)
        return try coercion.unbox(value: result, in: scope)
    }
    
    // func toEditable(in scope: Scope, as coercion: AsEditable) throws -> EditableValue {
    //      return self
    //  }
    
    func call(with command: Command, in commandScope: Scope, as coercion: Coercion) throws -> Value {
        // iris follows entoli's 'everything is a command' UX philosophy, but doesn't implement separate Identifier and Command classes underneath (although it maybe should for efficiency/clarity/robustness);

        // if not a handler, it's stored value; we already looked it up by name, so check
        if let handler = self.data as? Handler { // handler; Q. what are correct semantics when slot contains a replaceable handler? calling the handler won't update the slot's value; only way to change behavior is to replace the handler with another value; Q. what if handler is replaced with non-handler? should we forbid that? (or limit box to AsOptional(asHandler)?)
            return try handler.call(with: command, in: commandScope, as: coercion)
        } else if command.arguments.count == 0 { // stored value
            return try self.data.eval(in: commandScope, as: coercion) // problem: this discards original editable box, so changes made by handler won't propagate back; are we sure that's what we want?
        } else {
            throw UnknownArgumentError(at: 0, of: command)
        }
    }
    
    func swiftCall<T: BridgingCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        fatalError()
    }
    
    
    func set(_ name: Symbol, to value: Value) throws {
        if name == nullSymbol {
            self.data = value // TO DO: this needs to apply self.coercion, throwing if the given value does not fit box's original type and constraints
        } else {
            throw NotYetImplementedError()
        }
    }
    
    func get(_ key: Symbol) -> Value? {
        return (self.data as? Accessor)?.get(key)
    }
}
