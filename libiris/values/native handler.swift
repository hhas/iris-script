//
//  native handler.swift
//  libiris
//

import Foundation


// weak, latent typing (strictly speaking, code is untyped and latent typing is implemented as a library-defined behavior on top of untyped code; performs runtime type-checking by default but should also support compile-time type checking/inference given alternate primitive libraries)

@inline(__always) public func nativeParameter<T: SwiftCoercion>(_ param: (Symbol, Symbol, T)) -> HandlerType.Parameter {
    return (param.0, param.1, param.2.nativeCoercion)
}


struct NativeHandler: Handler {
        
    let interface: HandlerType
    
    let action: Value // usually a Block
    
    //let isStaticBindable = true // quick-n-dirty cheat // TO DO: check this
    
    // TO DO: Scope or MutableScope? also, what other mutable scopes are there other than Environment? (e.g. `tell` block scopes are composed of [primary] target scope and [secondary] lexical scope); one reason not to use Environment is
    
    private weak var lexicalScope: Environment? // this should be assigned when handler is instantiated
    
    internal var _lexicalScope_strong: Environment? = nil // this should be assigned only when handler is captured as closure (note: only the NativeHandler struct instance returned by eval strongly captures the lexical scope; the original instance in the lexical Environment does not; bear this in mind if converting NativeHandler to a class)
    
    init(interface: HandlerType, action: Value, in lexicalScope: Environment) {
        self.interface = interface
        self.action = action
        self.lexicalScope = lexicalScope
    }
    
    func call<T: SwiftCoercion>(with command: Command, in commandScope: Scope, as coercion: T) throws -> T.SwiftType {
        // if this handler defines and returns another handler (closure), the child handler may want to modify this scope so make it fully editable (write barriers are mostly for libraries to use)
        guard let handlerScope = self.lexicalScope?.subscope() as? Environment else { fatalError("BUG: dead scope.") }
        let result: T.SwiftType
        do {
            var index = 0
            for (label, binding, coercion) in self.interface.parameters {
                let argument = try command.value(for: (label, binding, coercion.swiftCoercion), at: &index, in: commandScope)
                handlerScope.bind(name: binding, to: argument)
            }
            if command.arguments.count > index && !self.interface.isEventHandler { // too many arguments
                throw UnknownArgumentError(at: index, of: command, to: self)
            }
            result = try coercion.coerce(self.interface.result.coerce(self.action, in: handlerScope), in: handlerScope) // TO DO: intersect coercions: self.interface.result.intersect(with: coercion) - one of the problems we have with intersecting coercions is that interface.result is a NativeCoercion, which may be a wrapper around primitive coercion (at least in primitive handlers); meanwhile, T may be just about anything, depending on its evaluation context // TO DO: what scope should caller-supplied use?
        } catch {
            throw HandlerError(handler: self, command: command).from(error)
        }
        //print("…got result: \(result)")
        return result
    }
    
    //
    
    // TO DO: FIX: previously used in `some_command_name as handler` so the handler object can be passed around as a closure // TO DO: this is now wrong (it'll infinitely recurse); need a toClosure() method instead
    func eval<T: SwiftCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
        var handler = self
        handler._lexicalScope_strong = self.lexicalScope // this assignment is purely to keep self.lexicalScope alive; use self.lexicalScope! to access it (worth noting: in entoli Environment, slots store handlers as either .unbound(Procedure) or .bound(Closure) - since slots are already enums anyway, the extra case avoids consuming an extra stack frame when calling the closure as the switch unwraps it first; Environment.call() then passes the lexical scope to Handler.call(), avoiding Handler having to capture it itself; whether this is any cheaper than accessing weakref'd NativeHandler.lexicalScope every time is another question)
        // TO DO: how best to break strong refcycle if handler is stored into same scope? (obvious option is for set to compare scopes for equal identity; this won't protect against more convoluted cycles, but it's the most common case); also consider slot assignment if using entoli 'everything is a command' semantics, in which case stored values are a separate enum case to stored handlers
        return try coercion.coerce(handler, in: scope)
    }
}


