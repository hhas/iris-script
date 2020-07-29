//
//  primitive handler.swift
//  libiris
//

import Foundation


// TO DO: should be ok with an extra `lexicalScope` slot that's assigned as needed (Q. how to weakref/strongref? we need to watch out for circular refs in backing stores: a handler defined in a context should maintain a weakref to that context; evaling `handler_name as handler` [closure] should return strongref'd copy that can be returned for use outside that context; storing that strongref'd copy back in same context should re-weakref it; anything more convoluted will probably just leak cycles refunless we have a GC to break those)

// TO DO: assuming primitive handlers can have editable parameters, need to decide how best to support these


public struct PrimitiveHandler: Handler {
    
    public typealias Call = (_ command: Command, _ commandEnv: Scope, _ handler: Handler, _ handlerEnv: Scope, _ coercion: NativeCoercion) throws -> Value // all generated `procedure_NAME_PARAMS` functions in _handlers.swift glue have this signature
        
    public let interface: HandlerInterface
    
    private let action: Call
    
    public init(interface: HandlerInterface, action: @escaping Call, in handlerScope: Scope) {
        self.interface = interface
        self.action = action
        self.lexicalScope = handlerScope
    }
    
    private var lexicalScope: Scope // this should be assigned when handler is instantiated
    
    
    public let isStaticBindable = true // quick-n-dirty cheat as long as all primitive handlers are defined on environments, not on values // TO DO: handlers defined on values (aka methods) must not be static bound to invoking commands for obvious reasons, so we will need to make this setting customizable in future (probably by passing it in init, or maybe making it part of interface definition alongside command/event flag and other [meta]info)
    
    
    public func call<T: SwiftCoercion>(with command: Command, in commandScope: Scope, as coercion: T) throws -> T.SwiftType {
        // TO DO: double-coercing returned values (once in self.call() and again in coercion.unbox()) is a pain, but should mostly go away once Coercions can be intersected (hopefully, intersected Coercions created within static expressions can eventually be memoized, or the AST rewritten by the interpreter to use them in future, avoiding the need to recreate those intersections every time they're used)
        let result: Value
        do {
            // TO DO: KLUDGE: typealias Call above currently returns Value
            result = try self.action(command, commandScope, self, self.lexicalScope, coercion.nativeCoercion) // TO DO: function wrapper currently ignores `coercion` (it's passed here on assumption that glue code will eventually intersect it with its interface.returnType, but see below TODO)
        } catch {
            throw HandlerError(handler: self, command: command).from(error)
        }
        return try coercion.coerce(result, in: commandScope) // TO DO: see above TODO on action(…)
    }
    
    // Q. how to bypass result coercion in call? (move `Coercion.box()` up to `call()`?) bear in mind that box doesn't do constraint checking (which we really should do)
}



