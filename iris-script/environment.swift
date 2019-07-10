//
//  environment.swift
//  iris-lang
//

// Values may implement accessor/mutator protocols, allowing attribute lookups; where mutator is implemented, consider how this interacts with struct's pass-by-value semantics (it is likely that mutable values will be implemented as class wrapper[s] around the original Value)

// scopes are always implemented as classes; these are always pass-by-reference, being common state shared by all dependents of a scope

// Q. to what extent should scripts be able to directly reference scopes? (e.g. `current_scope`, `global_scope`, `scope named NAME`) Q. libraries should all appear in global namespace under a common root, e.g. `XXXXX.com.example.mylib`; e.g. `use_library {com.example.mylib}` would merge the library's symbols into the global namespace [caveat: how do we deal with name collisions?]); think Frontier/Plan9 namespace

import Foundation


// TO DO: Accessor protocol for values that have readable slots

// TO DO: MutableScope protocol (environments need to be mutable for obvious reasons; might consider single-assignment)


protocol Accessor { // slot access // TO DO: adopt Value protocol?
    
    //func get(_ key: Symbol, delegate: Scope?) -> Value?
    func get(_ key: Name) -> Value?
}

extension Accessor {
    
    //func get(_ name: Symbol, delegate: Scope?) -> Value? { // TO DO: redundant if not throwing
    //    return self.get(name) ?? delegate?.get(name)
    //}
    
    // TO DO: where might call be used? should it be on separate Callable protocol?
    //func call(with command: Command, in commandScope: Scope, as coercion: Coercion) throws -> Value {
    //    fatalError()
    //}
    // TO DO: swiftCall?
}


protocol Mutator: Accessor {
    
    func set(_ name: Name, to value: Value) throws
}

protocol Scope: class, Accessor {
    
    func subscope() -> Scope // TO DO: `Self` causes subclasses to barf
    
}

protocol MutableScope: Scope, Mutator {
    
    func set(_ name: Name, to value: Value) throws // TO DO: delegate? thisFrameOnly?
    
    func subscope(withWriteBarrier isLocked: Bool) -> MutableScope
}

extension MutableScope {
    func subscope() -> Scope { return self.subscope(withWriteBarrier: true) }
}



class NullScope: Scope {
    
    // always returns nil (unless there's a delegate)
    func get(_ name: Name) -> Value? {
        return nil
    }
    
    func subscope() -> Scope { return self }
}

let nullScope = NullScope()


// Q. how should global scopes treat imported modules? (each native module is a read-locked environment populated with library-defined handlers and other values; Q. what about primitive modules? could use Environment subclass that populates frame dictionary)


class Environment: MutableScope {
    
    internal let parent: Environment?
    
    internal let isLocked: Bool // can `set` operations initiated on child scopes propagate to this scope?
    
    internal var frame = [Name: Value]() // TO DO: should values be enums? (depends if environment implements `call(command)`)
    
    init(parent: Environment? = nil, withWriteBarrier isLocked: Bool = true) {
        self.parent = parent
        self.isLocked = isLocked
    }
    
    func get(_ name: Name) -> Value? {
        if let result = self.frame[name] { return result }
        while let parent = self.parent {
            if let result = parent.frame[name] { return result }
        }
        return nil
    }
    
    // Q. `set` needs to walk frames in order to overwrite existing binding if found; should it also try delegate? (seems likely)
    
    // TO DO: by checking for name in parent scopes, this must prevent masking *except* where parameter names are concerned
    
    // TO DO: `set` takes slot name only; what if a chunk expr is given, e.g. `set field_name of slot_name to new_value`? probably better to get() slot, and determine action from there (one challenge: get-ing an editable box needs to discard the box if a write-barrier is crossed)
    
    func bind(name: Name, to value: Value) { // called by [Native]Handler.call(); this does not check for name masking/duplicate names (the former is unavoidable, but as the handler controls those parameter names it will know how to address masked globals [either by renaming its parameters or by using a chunk expr to explicitly reference the masked name's scope], while HandlerInterface is responsible for ensuring all parameter and binding names are unique)
        self.frame[name] = value
    }
    
    func set(_ name: Name, to newValue: Value) throws { // TO DO: rethink how this works
        //print(self.frame)
        if let foundValue = self.frame[name] { // if name is bound in current scope [try to] update it
            // TO DO: would it be better to make `set` part of Value protocol, with the default implementation throwing ImmutableValueError? (similarly, `Value.get()` would throw "Can't get \(name) of \(self)" by default); e.g. consider a 'file' object where `get contents of f` and `set contents of f to: newdata` would read and write that file's data
            guard let editableValue = foundValue as? EditableValue else { throw ImmutableValueError(name: name, in: self) }
            try editableValue.set(nullSymbol, to: newValue)
        } else { // check parent scopes; if found, hoist its value to current scope and [try to] update it
            var targetScope: Environment = self // new bindings are created in current scope
            var isLocked = false // write-locked scopes can modify themselves but cannot be modified from sub-scopes
            while let scope = targetScope.parent {
                if scope.isLocked { isLocked = true }
                if let foundValue = scope.frame[name] { // found name in parent scope
                    if isLocked { throw ImmutableScopeError(name: name, in: scope) }
                    self.frame[name] = foundValue // hoisting the found value to the current scope prevents it being masked by `define(…)` // TO DO: this currently discards any write barriers protecting original value; simplest solution is to discard the editable box; another option is to wrap the value in a WriteProtectedValue struct that throws ImmutableScopeError on set(); third option would be not to hoist the value, but simply insert a placeholder in the current frame that prevents subsequent writes while redirecting all lookups to the parent scope
                    guard let editableValue = foundValue as? EditableValue else { throw ImmutableValueError(name: name, in: scope) }
                    try editableValue.set(nullSymbol, to: newValue)
                    return
                }
                targetScope = scope
            }
            self.frame[name] = newValue
        }
    }
    
    func subscope(withWriteBarrier isLocked: Bool) -> MutableScope {
        return Environment(parent: self, withWriteBarrier: isLocked)
    }
    
    // TO DO: implement call()? if adopting entoli-style 'everything is a command' semantics, Commands would call this rather than call Handlers directly, allowing lighterweight storage of 'variable' values (i.e. enum rather than closure)
}



extension Environment {
    
    // unlike `set`, `define` always adds to current frame so does not check for existing names in current/parent scopes
    
    // this assumes environment is initially empty so does not check for existing names
    func define(_ interface: HandlerInterface, _ action: @escaping PrimitiveHandler.Call) {
        self.bind(name: interface.name, to: PrimitiveHandler(interface: interface, action: action, in: self))
    }
    
    func define(_ interface: HandlerInterface, _ action: Block) throws {
        // this checks current frame and throws if slot is already occupied (even if EditableValue)
        if self.frame[interface.name] != nil { throw ExistingNameError(name: interface.name, in: self) }
        self.bind(name: interface.name, to: NativeHandler(interface: interface, action: action, in: self))
    }
}




class TellScope: MutableScope {
    
    internal let target: Accessor
    internal let parent: Environment
    
    init(target: Accessor, parent: Environment) {
        self.target = target
        self.parent = parent
    }
    
    func get(_ name: Name) -> Value? {
        return self.target.get(name) ?? self.parent.get(name)
    }
    func set(_ name: Name, to value: Value) throws {
        try self.parent.set(name, to: value)
    }
    func subscope(withWriteBarrier isLocked: Bool) -> MutableScope {
        return TellScope(target: self.target, parent: self.parent.subscope(withWriteBarrier: isLocked) as! Environment)
    }
}
