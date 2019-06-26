//
//  environment.swift
//  iris-lang
//

// Values may implement accessor/mutator protocols, allowing attribute lookups; where mutator is implemented, consider how this interacts with struct's pass-by-value semantics (it is likely that mutable values will be implemented as class wrapper[s] around the original Value)

// scopes are always implemented as classes; these are always pass-by-reference, being common state shared by all dependents of a scope

import Foundation


// TO DO: Accessor protocol for values that have readable slots

// TO DO: MutableScope protocol (environments need to be mutable for obvious reasons; might consider single-assignment)


protocol Accessor { // slot access
    
    func get(_ key: Symbol, delegate: Scope?) -> Value?
    func get(_ key: Symbol) -> Value?
}

extension Accessor {
    
    func get(_ name: Symbol, delegate: Scope?) -> Value? {
        return self.get(name) ?? delegate?.get(name)
    }
    
    // TO DO: where might call be used? should it be on separate Callable protocol?
    //func call(with command: Command, in commandScope: Scope, as coercion: Coercion) throws -> Value {
    //    fatalError()
    //}
    // TO DO: swiftCall?
}


protocol Mutator: Accessor {
    
    func set(_ name: Symbol, to value: Value) throws
}

// TO DO: how to implement mutable values? generic class wrapper for immutable struct?


protocol Scope: class, Accessor {
    
    func subscope() -> Scope // TO DO: `Self` causes subclasses to barf
    
}

protocol MutableScope: Scope, Mutator {
    
    func set(_ name: Symbol, to value: Value) throws // TO DO: delegate? thisFrameOnly?
    
    func subscope(withWriteBarrier: Bool) -> MutableScope
}

extension MutableScope {
    func subscope() -> Scope { return self.subscope(withWriteBarrier: true) }
}



class NullScope: Scope {
    
    // always returns nil (unless there's a delegate)
    func get(_ name: Symbol) -> Value? {
        return nil
    }
    
    func subscope() -> Scope { return self }
}

let nullScope = NullScope()


// Q. how should global scopes treat imported modules? (each native module is a read-locked environment populated with library-defined handlers and other values; Q. what about primitive modules? could use Environment subclass that populates frame dictionary)


class Environment: MutableScope {
    
    internal let parent: Environment?
    
    internal let isWriteBoundary: Bool // can `set` operations initiated on child scopes propagate to this scope?
    
    internal var frame = [String: Value]() // TO DO: should values be enums? (depends if environment implements `call(command)`)
    
    init(parent: Environment? = nil, withWriteBarrier: Bool = true) {
        self.parent = parent
        self.isWriteBoundary = withWriteBarrier
    }
    
    func get(_ name: Symbol) -> Value? {
        if let result = self.frame[name.key] { return result }
        while let parent = self.parent {
            if let result = parent.frame[name.key] { return result }
        }
        return nil
    }
    
    // Q. `set` needs to walk frames in order to overwrite existing binding if found; should it also try delegate? (seems likely)
    
    // TO DO: by checking for name in parent scopes, this must prevent masking *except* where parameter names are concerned
    
    // TO DO: `set` takes slot name only; what if a chunk expr is given, e.g. `set field_name of slot_name to new_value`? probably better to get() slot, and determine action from there (one challenge: get-ing an editable box needs to discard the box if a write-barrier is crossed)
    
    func set(_ name: Symbol, to value: Value) throws {
        var targetScope: Environment = self // new bindings are created in current scope
        if self.frame[name.key] == nil { // if name is not bound in current scope, check parent scopes; if found, update there
            var isLocked = false // write-locked scopes can modify themselves but cannot be modified from sub-scopes
            while let scope = targetScope.parent {
                if scope.isWriteBoundary { isLocked = true }
                if let foundValue = scope.frame[name.key] { // found name in parent scope
                    if isLocked { throw ImmutableScopeError(name: name, in: scope) }
                    guard let editableValue = foundValue as? EditableValue else { throw ImmutableValueError(name: name, in: scope) }
                    try editableValue.set(nullSymbol, to: value)
                    return
                }
                targetScope = scope
            }
        }
        targetScope.frame[name.key] = value // what if slot is already defined?
    }
    
    func addParameter() {
        
    }
    
    func subscope(withWriteBarrier: Bool) -> MutableScope {
        return Environment(parent: self, withWriteBarrier: withWriteBarrier)
    }
    
    // TO DO: implement call()? if adopting entoli-style 'everything is a command' semantics, Commands would call this rather than call Handlers directly, allowing lighterweight storage of 'variable' values (i.e. enum rather than closure)
}



extension Environment {
    
    func addPrimitiveHandler(_ interface: HandlerInterface, _ action: @escaping PrimitiveHandler.Call) throws {
        try self.set(interface.name, to: PrimitiveHandler(interface: interface, action: action, in: self))
    }
    
    func addNativeHandler(_ interface: HandlerInterface, _ action: Block) throws {
        try self.set(interface.name, to: NativeHandler(interface: interface, action: action, in: self))
    }
    
    func addHandler(_ handler: Handler) throws {
        try self.set(handler.interface.name, to: handler)
    }
}
