//
//  value modifiers.swift
//  libiris
//

import Foundation


// TO DO: Boolean type might be implemented as boxes around values, where true encapsulates any value except 'test failed' and false encapsulates 'test failed'; this'd give us Icon-style Boolean test semantics while preserving the visual clarity and convenience of `true`/`false` constants and display (main concern is this doesn't create a hole to sneak complex 'sensitive' data out of an API/library under pretence of it being a simple boolean; as with EditableValue we want to limit how far it can travel before it's reduced to a simpler 'safe' representation)

// TO DO: how best to represent annotations (e.g. when preserving non-code data in parsed AST: comments, user docs, etc)? sylvia defined an annotation collection in Value base class, but iris uses structs so it would need to be defined on every iris-defined value type [excepting Int/Double, which are existing Swift types so can't be extended], plus it'd probably want to use Foundation classes so that progressively attached metadata is shared across all instances of that value (which means added refcounting); alternative is to use AnnotatedValue wrapper class similar to EditableValue, which can be added only where needed (and since the AST will probably end up being incrementally parsed, we may want something that enables AST subtrees to be modified in-place)


// Q. need to make sure values don't get double-boxed by accident (e.g. EditableValue.set(EditableValue(…)), or when evaling the boxed value returns another box); lastly, we do need to consider how native code (bind-once + editable boxes) will cross-compile to Swift (let/var + pass-by-value structs, pass-by-reference classes, and reference-backed structs)

// Q. what about editable collections? may be more efficient to implement as dedicated EditableTYPE classes, which box or extend Swift's Foundation Array/Dictionary/Set classes, in which case EditableValue probably wants to be a protocol instead


// to keep mutability semantics conceptually simple, there should be no distinction between mutable value and mutable storage. All environments slots are write-once, so inherently immutable; [im]mutability is purely a function of the content of a slot: if the slot's value allows editability, either because it's an EditableValue 'box' or something equivalent, then attributes of that value [if it's a list or record] should appear mutable as well. The simplest [though not necessarily efficient] way to achieve this is to replace the box's current value with the new value. If implementing a more parsimonious mechanism [to minimize CPU overheads due to copying] where the box's value is itself mutatable [e.g. a struct with a `var data:Array<>`] then this mutation may need to be mediated by the box—what we don't want is for the mutable struct to 'escape' into an immutable context; i.e. there should be no equivalent to Swift's storing a mutable class in a `let` slot, or an immutable list in an editable box. (At least with Swift collection structs, their copy-on-write[-if-needed] behavior should protect against shared state escaping editable boundaries.) One option may be for list/record mutator methods to return the modified value (either a new value or the current value with in-place changes) which the editable box automatically stores in place of the previous version (though we'll need to watch out for excessive copying, as Swift is liable to think the underlying Array is not unique and so re-copy it on every write)

//      (caveat to the above: when the value is a chunk expression that points to some external state; e.g. consider an application specifier: while explicit get/set should make it clear that the local value is distinct to the referenced object, the referenced object's state can still change over time regardless of the local value's immutability; this is why, even with ubiquitous immutability, we can't have nice things like any guarantees of referential transparency [except, perhaps, in simple handlers that only consume the built-in data types and never deal with external state or invoke commands that could])

// TO DO: beware cases where an [e.g.] immutable List could contain EditableValue items; might want to enforce item [im]mutability solely at the scope slot level; thus `set x to 3 as editable value, set y to [] as editable list, set end of y to x` would automatically de-box the 3 upon inserting it into the list


public class EditableValue: Handler, Mutator { // TO DO: Handler or Callable?
    
    public var swiftLiteralDescription: String { return "\(type(of: self))(\(self.data.swiftLiteralDescription), as: \(self.coercion.swiftLiteralDescription))" }
    
    // get() and call() behaviors are pass-thrus to the underlying Value; set() replaces the current Value with a new Value
    
    public static let nominalType: NativeCoercion = asEditable.nativeCoercion
    
    public var description: String { return "editable \(self.data)" }
    
    private(set) var data: Value
    public let coercion: NativeCoercion // the type of the underlying value
    
    public init(_ data: Value, as coercion: NativeCoercion) { // called by AsEditable
        self.data = data
        self.coercion = coercion
    }
    
    //
    
    public var immutableValue: Value { return self.data } // this is kinda tricky: if self.data is, say, a OrderedList of editable values, those values also need to be made immutable (ideally, collections should never contain EditableValue items; only the topmost value should be boxed, but we need to give more thought to that)
    
    
    public func eval<T: SwiftCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
        let result = try coercion.coerce(self.data, in: scope) // TO DO: this needs to intersect the given coercion with self.coercion and pass the resulting coercion to self.data.eval(…); Q. how should intersecting [e.g.] AsScalar with AsOrderedList work out?
        //        self.data = result // this is wrong; only mutator operations should modify editable box's content [in the case of editable parameters to a command, the handler should eval and update the box's content when binding it to the handler's scope] // Q. what if coercion is AsEditable? we don't want to create a second box
        return result
    }
    
    // func toEditable(in scope: Scope, as coercion: AsEditable) throws -> EditableValue {
    //      return self
    //  }
    
    public func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        // iris follows entoli's 'everything is a command' UX philosophy, but doesn't implement separate Identifier and Command classes underneath (although it maybe should for efficiency/clarity/robustness);

        // if not a handler, it's stored value; we already looked it up by name, so check
        if let handler = self.data as? Callable { // handler; Q. what are correct semantics when slot contains a replaceable handler? calling the handler won't update the slot's value; only way to change behavior is to replace the handler with another value; Q. what if handler is replaced with non-handler? should we forbid that? (or limit box to AsOptional(asHandler)?)
            return try handler.call(with: command, in: scope, as: coercion)
        } else if command.arguments.count == 0 { // stored value
            return try coercion.coerce(self.data, in: scope) // problem: this discards original editable box, so changes made by handler won't propagate back; are we sure that's what we want?
        } else {
            throw UnknownArgumentError(at: 0, of: command, to: self)
        }
    }
    
    
    public func set(_ name: Symbol, to value: Value) throws { // TO DO: is there ever any situation where name can be anything other than nullSymbol? (Q. should the slot name always be passed here, c.f. call() which always passes the full Command even though the receiving handler ignores the command's name?)
        if name == nullSymbol {
            self.data = value // TO DO: this needs to apply self.coercion, throwing if the given value does not fit box's original type and constraints
        } else {
            throw NotYetImplementedError()
        }
    }
    
    public func get(_ name: Symbol) -> Value? {
        return self.data.get(name)
    }
    
    public func set(to value: Value) {
        try! self.set(nullSymbol, to: value)
    }
}




public struct ScopeLockedValue: Handler, Mutator { // experimental
    
    // Handler and Accessor behaviors are pass-thrus to the underlying Value
    
    public static let nominalType: NativeCoercion = asValue.nativeCoercion
    public let nominalType: NativeCoercion
    
    public var description: String { return "editable \(self.data)" }
    
    private let data: Value
    private let scope: Scope
    
    public init(_ data: Value, in scope: Scope) {
        self.data = data
        self.scope = scope
        self.nominalType = data.nominalType
    }
    
    //
    /*
    public func eval(in scope: Scope, as coercion: Coercion) throws -> Value {
        return try self.data.eval(in: scope, as: coercion)
    }
    
    public func swiftEval<T: SwiftCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
        return try self.data.swiftEval(in: scope, as: coercion)
    }
    
    // func toEditable(in scope: Scope, as coercion: AsEditable) throws -> EditableValue {
    //      return self
    //  }
    
     */
    
    public func call<T: SwiftCoercion>(with command: Command, in commandScope: Scope, as coercion: T) throws -> T.SwiftType {
        if let handler = self.data as? Callable { // handler; Q. what are correct semantics when slot contains a replaceable handler? calling the handler won't update the slot's value; only way to change behavior is to replace the handler with another value; Q. what if handler is replaced with non-handler? should we forbid that? (or limit box to AsOptional(asHandler)?)
            return try handler.call(with: command, in: commandScope, as: coercion)
        } else if command.arguments.count == 0 { // stored value
            return try coercion.coerce(self.data, in: commandScope) // problem: this discards original editable box, so changes made by handler won't propagate back; are we sure that's what we want?
        } else {
            throw UnknownArgumentError(at: 0, of: command, to: self)
        }
    }
    
    public func set(_ name: Symbol, to value: Value) throws {
        throw ImmutableScopeError(name: name, in: self.scope)
    }
    
    public func get(_ name: Symbol) -> Value? {
        return self.data.get(name)
    }
}
