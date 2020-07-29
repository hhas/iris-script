//
//  command bindings.swift
//  libiris
//

// conceptually a command is a right-associative unary operator with arbitrary name and fixed precedence, where operand is always a record (non-record values are coerced to single-field record upon evaluation); in practice, the current Command implementation is an atomic structure comprising a name and Array of fields, plus internal caching (while it could be implemented as a Command(Symbol,Record) struct, this does not lend itself to dynamic [run-time] optimization; the tradeoff is increased code complexity)


// TO DO: what about, say, interpolated strings? we don't provide a syntax for that in core punctuation, so can't be optimized at compile-time; should primitive handler definitions have the ability to supply a custom binding struct


// note that late binding and an immutable AST* do not lend themselves to compile-time optimzations such as constant folding (*unless AST nodes are explicitly wrapped in EditableValue, which is the sort of thing the code editor/debugger might want to do); the obvious way to perform AST transforms is to eval the AST against an alternate set of primitive libraries (e.g. this is probably how native->Swift cross-compilation will be done) - when parsing code for that purpose, the parser could use an alternate Value source that provides wrapped versions of some or all Value types [c.f. kiwi parser, caveat we'll need a ValueConstructorProtocol so that different sources can be swapped in]; thus code analysis is code evaluation, just with [class-based] Values that gather 'usage' information (no doubt it'll be much slower than a conventional optimizing compiler design, but has the advantage of being completely library-driven and -extensible, using the exact same library extension mechanisms that supply library-defined handlers and operator sugar in run-time use)


import Foundation

// TO DO: what about wildcard matching of record fields/command arguments, c.f. `(a,b,*rest)`/`foo(c,d,**rest)` in Python?

/*
 
 consider the following
 
    do
        foo
    done catching do, done
 
    to foo do, done

    foo

 */



struct MemoizedStaticValue: Handler {
    // slot contains a non-handler value; the command still invokes `call()`, but no argument processing is performed, just evaluation+coercion of the value to the requested type if not already of that type
    
    var description: String { return "\(self.result)" }
    
    let value: Value
    let coercion: NativeCoercion // constrained type of result (effectively result.constrainedType)
    let result: Value
    
    func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
       
        return try coercion.coerce(self.value, in: scope)
        //return self.coercion.isa(coercion) ? self.result : try coercion.coerce(self.value, in: scope) // TO DO: if value is memoizable, what about caching results of eval, using coercion as cache key? e.g. if value is a non-constant expr, e.g. a block, it must be evaled every time, but if value.isMemoizable then there's no need to coerce every time [if the coercion succeeds, then it can cache and return that result every time; if coercion fails, then it can cache and rethrow that coercion error every time])
    }
}


// TO DO: also DynamicallyBoundNonMaskableHandler? (this would capture Scope, avoiding full lookup every time); Q. is this still needed? late binding allows a command call to fail if handler isn't yet defined; once handler is defined, first call to Environment.get() will lift it to current scope to prevent subsequent masking (Q. what about non-environment scopes?) [note: where multiple parent scopes are persistent, the invoking scope can still end up binding handler from a different parent, depending on the order in which the parents populate the named slot - IOW there is something to be said for AppleScript's static slot definitions over Python/JS-style runtime slot insertions/deletions, which allow crazy runtime customizability at cost of static machine/human reasoning]


struct DynamicallyBoundHandler: Handler { // e.g. when looking up a slot on a Value
    
    var description: String { return "<DynamicallyBoundHandler>" }
    
    func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        // TO DO: command should be able to build a cache table of preprocessed arg lists using handler.interface as key
        guard let handler = scope.get(command.name) as? Handler else {
            throw UnknownNameError(name: command.name, in: scope)
        }
        return try handler.call(with: command, in: scope, as: coercion)
    }
}
let _dynamicallyBoundHandler = DynamicallyBoundHandler()


//


struct BindHandlerOnFirstUse: Handler {
    
    var description: String { return "<BindHandlerOnFirstUse>" }
    
    // TO DO: not sure about this; may be cheaper to make Command._handler an enum (static/dynamic/unbound) and take the switch hit on every call vs an extra stack frame allocation for every dynamic call (switch also reduces load on Swift stack)
    
    // TO DO: what happens if the handler is found in a delegate (e.g. secondary, lexical, scope after a tell block's primary target scope)? any situations where static-binding it on first use could bite us? (as long as primary scope is immutable, then no; however, it is possible for target to be a mutable value)
    
    // beware: if handler is assigned to writable slot, binding MUST be dynamic (although it could capture scope if non-maskable) // here's the thing: if we use EditableValue boxes for mutability, all slots should be write-once; the alternative is to use simple EditableValue struct/enum wrapper, which coercion adds; when the value is stored, the wrapper is discarded and the value stored in an editable slot
    
    // TO DO: is it possible for coercion to change? (in theory, yes)
    
    func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        // TO DO: fix this guard (casting is separate issue; if not a handler then confirm no arguments in command and return the value)
        guard let value = scope.get(command.name) else { throw UnknownNameError(name: command.name, in: scope) }
        if let handler = value as? Handler {
            command._handler = handler.isStaticBindable ? handler : _dynamicallyBoundHandler // dynamic lookup adds ~20%
            // if static bound, we can also memoize partially processed argument list, matching labels and coercing null (omitted) and literal arguments once; expr arguments may also be partially reduced by intersecting each expr-based argument's output coercion with parameter's input coercion (Q. where handlers are dynamically bound, chances are there are a relatively small number of handlers involved, in which case caching partially processed parameters against handler identity may be worth doing)
            
            // if static bound or otherwise memoizable, ask Handler for staticCall(for: Command,…); this will balance argument list, evaling arguments where possible (e.g. arguments that are literal values only need coerced once)
            return try handler.call(with: command, in: scope, as: coercion)
        } else {
            // Q. if first lookup finds stored value, is it worth returning as StoredValueHandler? this might capture value (if read-only, non-maskable), or scope (if mutable, non-maskable), or dynamic lookup
            if command.arguments.count != 0 { throw UnknownArgumentError(at: 0, of: command) }
            let result = try coercion.coerce(value, in: scope)
            if value.isMemoizable {
  //              command._handler = MemoizedStaticValue(value: value, coercion: coercion, result: result) // TO DO
            }
            return result
        }
    }
}

let _bindHandlerOnFirstUse = BindHandlerOnFirstUse()

