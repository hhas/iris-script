//
//  handler protocols.swift
//  iris-lang
//

import Foundation


// TO DO: what jargon to use for an unbound handler? ('procedure'?) e.g. in `do…done catching {error}: do…done`, or `some_list; map {item, count}: do…done`

// TO DO: need to decide where `isEventHandler` flag should go; whereas rest of HandlerInterface (name, parameters, return type) is constructed from left-side of Pair, whether to behave as command or event handler is determined by context to which proc is bound (e.g. in right-side of `catching` operator, the `error` param can be omitted; in right-side of `map` [or whatever it's called], the `count` param can be omitted [as can the `item` param])

// Q. multimethods? (we may want to divorce param+return types from name, associating type sig with callable)


// Q. should parameters be struct with pattern-matching built in?


// TO DO: call()/swiftCall() needs to implement special-case behavior when coercion is AsHandler and command has no arguments, in which case return the handler itself without calling it (Q. what about when the handler being called returns a handler? which one do we want to capture? we can always determine this by checking if command has an explicit argument, e.g. `foo as handler` returns the #foo handler whereas `foo {} as handler` calls the #foo handler coercing its output to a handler)


// TO DO: Handler protocol needs public API for getting its Scope for reporting purposes (this is slightly complicated as primitive vs native handlers capture their host environment in different ways)


protocol Handler: ComplexValue {
    
    var interface: HandlerInterface { get }
    
    var isStaticBindable: Bool { get }
    
    func call(with command: Command, in scope: Scope, as coercion: Coercion) throws -> Value
    
    func swiftCall<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType
    
    func swiftCallAs<T>(with command: Command, in scope: Scope, as coercion: Coercion) throws -> T
    
}



extension Handler {
    
    var description: String { return "\(self.interface):do…done" }

    static var nominalType: Coercion { return asHandler }
    
    var interface: HandlerInterface { return HandlerInterface() } // null interface
    
    var isStaticBindable: Bool { return false } // TO DO: module-defined handlers are normally instantiated at startup, permanently bound to a single scope, stored in a read-only slot, and cannot be masked in sub-scopes, so only need looked up on first call, after which they can be captured by command for reuse (Q. since any slot can, in principle, be explicitly masked in subscope, how do we ensure this? [one reason we want to avoid masking library handlers is that the library may also define operator syntax for those handlers, and replacing one without the other is likely to cause confusion/errors]); caution: rebinding a module handler to a writable slot requires dynamic binding (although it should be okay to capture the environment as long as it's non-maskable, which at least reduces it to single dictionary lookup)
    
    func swiftCallAs<T>(with command: Command, in scope: Scope, as coercion: Coercion) throws -> T {
        let value = try self.call(with: command, in: scope, as: coercion)
        return try coercion.swiftCoerce(value: value, in: scope)
    }
    
}



