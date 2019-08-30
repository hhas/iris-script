//
//  primitive handler.swift
//  iris-lang
//

import Foundation


// TO DO: should be ok with an extra `lexicalScope` slot that's assigned as needed (Q. how to weakref/strongref? we need to watch out for circular refs in backing stores: a handler defined in a context should maintain a weakref to that context; evaling `handler_name as handler` [closure] should return strongref'd copy that can be returned for use outside that context; storing that strongref'd copy back in same context should re-weakref it; anything more convoluted will probably just leak cycles refunless we have a GC to break those)

// TO DO: assuming primitive handlers can have editable parameters, need to decide how best to support these


struct PrimitiveHandler: Handler {
    
    typealias Call = (_ command: Command, _ commandEnv: Scope, _ handler: Handler, _ handlerEnv: Scope, _ coercion: Coercion) throws -> Value // all generated `procedure_NAME_PARAMS` functions in _handlers.swift glue have this signature
        
    let interface: HandlerInterface
    
    private let action: Call
    
    init(interface: HandlerInterface, action: @escaping Call, in handlerScope: Scope) {
        self.interface = interface
        self.action = action
        self.lexicalScope = handlerScope
    }
    
    private var lexicalScope: Scope // this should be assigned when handler is instantiated
    
    
    let isStaticBindable = true // quick-n-dirty cheat as long as all primitive handlers are defined on environments, not on values // TO DO: handlers defined on values (aka methods) must not be static bound to invoking commands for obvious reasons, so we will need to make this setting customizable in future (probably by passing it in init, or maybe making it part of interface definition alongside command/event flag and other [meta]info)
    
    
    func call(with command: Command, in commandEnv: Scope, as coercion: Coercion) throws -> Value {
        // TO DO: double-coercing returned values (once in self.call() and again in coercion.coerce()) is a pain, but should mostly go away once Coercions can be intersected (hopefully, intersected Coercions created within static expressions can eventually be memoized, or the AST rewritten by the interpreter to use them in future, avoiding the need to recreate those intersections every time they're used)
        let result: Value
        do {
            result = try self.action(command, commandEnv, self, self.lexicalScope, coercion) // TO DO: function wrapper currently ignores `coercion` (it's passed here on assumption that glue code will eventually intersect it with its interface.returnType, but see below TODO)
        } catch {
            throw HandlerError(handler: self, command: command).from(error)
        }
        return try coercion.coerce(value: result, in: commandEnv) // TO DO: see above TODO on action(…)
    }
    
    // Q. how to bypass result coercion in swiftCall? (move `Coercion.box()` up to `call()`?) bear in mind that box doesn't do constraint checking (which we really should do)
    
    func swiftCall<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        // TO DO: how will this intersect coercions? do we need a separate swiftFunc wrapper that supports generics? we could presumably sneak out the primitive result in a Value wrapper, relying on runtime casts rather than generics, but that's a kludge; the problem is that swiftEval code paths need to use unbox instead of coerce (trying to achieve a single unified code path for both native->native and native->primitive [c.f. kiwi] proved to be an endless rabbit hole in entoli, hence the switch to separate code paths; only way to reduce code duplication would be to pass the coerce/unbox step as a closure argument, but again that will likely get silly); the alternative, given that most Values are now nice cheap structs [caveat that collection values currently hold each element as a Value, not a Swift primitive, making full unboxing an O(n) operation; the swiftEval code path avoids creating this extra work], would be to use Value throughout, and only unbox at the very end (much depends on if/how iris implements sylvia-style Value annotations, as constructing and storing [relatively expensive] annotations is a waste of time if the end result is the unboxed Swift value)
        throw NotYetImplementedError()
    }
}



