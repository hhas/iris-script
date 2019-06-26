//
//  native handler.swift
//  iris-lang
//

import Foundation



struct NativeHandler: Handler {
    
    var description: String { return "\(self.interface)" }
    
    let interface: HandlerInterface
    
    let action: Block
    
    // TO DO: Scope or MutableScope? also, what other mutable scopes are there other than Environment? (e.g. `tell` block scopes are composed of [primary] target scope and [secondary] lexical scope); one reason not to use Environment is
    
    private weak var lexicalScope: Environment? // this should be assigned when handler is instantiated
    
    internal var _lexicalScope_strong: Environment? = nil // this should be assigned only when handler is captured as closure (note: only the NativeHandler struct instance returned by eval strongly captures the lexical scope; the original instance in the lexical Environment does not; bear this in mind if converting NativeHandler to a class)
    
    init(interface: HandlerInterface, action: Block, in lexicalScope: Environment) {
        self.interface = interface
        self.action = action
        self.lexicalScope = lexicalScope
    }
    
    func call(with command: Command, in commandScope: Scope, as coercion: Coercion) throws -> Value {
        // if this handler defines and returns another handler (closure), the child handler may want to modify this scope so make it fully editable (write barriers are mostly for libraries to use)
        guard let handlerScope = self.lexicalScope?.subscope() as? Environment else { fatalError("BUG: dead scope.") }
        // TO DO: bind command arguments to handlerScope
        let result: Value
        do {
            var index = 0
            let arguments = command.arguments
            for (label, binding, coercion) in self.interface.parameters {
                // TO DO: don't use `set` as we need to bind to current frame (Q. how do we deal with masking?)
                try handlerScope.set(binding, to: try command.value(at: &index, for: (label, coercion), in: commandScope))
            }
            if arguments.count > index && !self.interface.isEventHandler { // too many arguments
                throw UnknownArgumentError(at: index, of: command)
            }
            result = try self.action.eval(in: handlerScope, as: self.interface.result) // TO DO: any reason to go through eval here? (if we restrict body type to Block then in principle no…)
            //result = try self.interface.result.coerce(value: self.action, in: handlerScope) // (…in which case use this to reduce stack pressure) … except that Block implements eval, not toTYPE methods
            // note: the result coercion only applies to returned value (e.g. if return type is Thunk, it won't actually do anything as the Block's eval loop has already forced the result of each expr)
        } catch {
            throw HandlerError(handler: self, command: command).from(error)
        }
        //print("…got result: \(result)")
        return result
    }
    
    func swiftCall<T: BridgingCoercion>(with command: Command, in dynamicScope: Scope, as coercion: T) throws -> T.SwiftType {
        return try coercion.unbox(value: self.call(with: command, in: dynamicScope, as: coercion), in: dynamicScope) // ick
    }
    
    //
    
    func eval(in scope: Scope, as coercion: Coercion) throws -> Value {
        var handler = self
        handler._lexicalScope_strong = self.lexicalScope // this assignment is purely to keep self.lexicalScope alive; use self.lexicalScope! to access it (worth noting: in entoli Environment, slots store handlers as either .unbound(Procedure) or .bound(Closure) - since slots are already enums anyway, the extra case avoids consuming an extra stack frame when calling the closure as the switch unwraps it first; Environment.call() then passes the lexical scope to Handler.call(), avoiding Handler having to capture it itself; whether this is any cheaper than accessing weakref'd NativeHandler.lexicalScope every time is another question)
        // TO DO: how best to break strong refcycle if handler is stored into same scope? (obvious option is for set to compare scopes for equal identity; this won't protect against more convoluted cycles, but it's the most common case); also consider slot assignment if using entoli 'everything is a command' semantics, in which case stored values are a separate enum case to stored handlers
        return try coercion.coerce(value: handler, in: scope)
    }
    
    func swiftEval<T: BridgingCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
        return try coercion.unbox(value: self, in: scope)
    }
    
}


