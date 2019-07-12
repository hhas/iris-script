//
//  command bindings.swift
//  iris-lang
//

// conceptually a command is a right-associative unary operator with arbitrary name and fixed precedence, where operand is always a record (non-record values are coerced to single-field record upon evaluation); in practice, the current Command implementation is an atomic structure comprising a name and Array of fields, plus internal caching (while it could be implemented as a Command(Name,Record) struct, this does not lend itself to dynamic [run-time] optimization; the tradeoff is increased code complexity)


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
    
    var description: String { return "\(self.result)" }
    
    let value: Value
    let coercion: Coercion
    let result: Value
    
    func call(with command: Command, in scope: Scope, as coercion: Coercion) throws -> Value {
        return self.coercion.isa(coercion) ? self.result : try self.value.eval(in: scope, as: coercion)
    }
    func swiftCall<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        fatalError() // TO DO: this unboxes as T; how practical/useful to cache returned value
    }
}


// TO DO: also DynamicallyBoundNonMaskableHandler? (this would capture Scope, avoiding full lookup every time)

struct DynamicallyBoundHandler: Handler {
    
    var description: String { return "<DynamicallyBoundHandler>" }
    
    func call(with command: Command, in scope: Scope, as coercion: Coercion) throws -> Value {
        // TO DO: command should be able to build a cache table of preprocessed arg lists using handler.interface as key
        guard let handler = scope.get(command.name) as? Handler else { throw UnknownNameError(name: command.name, in: scope) }
        return try handler.call(with: command, in: scope, as: coercion)
    }
    
    func swiftCall<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        fatalError()
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
    
    func call(with command: Command, in scope: Scope, as coercion: Coercion) throws -> Value {
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
            let result = try value.eval(in: scope, as: coercion)
            if value.isMemoizable {
                command._handler = MemoizedStaticValue(value: value, coercion: coercion, result: result)
            }
            return result
        }
    }
    
    func swiftCall<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        return try coercion.unbox(value: self.call(with: command, in: scope, as: coercion), in: scope)
    }
}

let _bindHandlerOnFirstUse = BindHandlerOnFirstUse()

