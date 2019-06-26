//
//  command value.swift
//  iris-lang
//

import Foundation

// operators reduce to commands with pre-bound handler from same library as operator syntax

// should environment slots be bind-once? (if mutability is provided by EditableValue class wrapper around immutable Value struct, there's no reason for it not to be; furthermore, the EditableValue may use the underlying value's nominalType as default if no type specified)


// set foo to: [] as editable list of: text

// set foo to: make new: editable list of: text

// set {foo, to: make {new: editable {list {of: text}}}}



// commands are effectively right-associative prefix [unary]  operators (use record to pass multiple values); argument is optional (Q. how to distinguish `foo {nothing}` from `foo nothing`/`foo`); if all identifiers are commands, how to distinguish e.g. `foo - 1` from `foo -1`? (if foo can be inspected at parse-time, provide user feedback either by flagging or by rewriting latter as `foo {-1}` for clarity)

// TO DO: should commands capture their lexical scope (c.f. kiwi)? or leave thunking to explicit coercion (e.g. `foo(x) as expression` -> bound `foo(x)` value)

// Q. when populating handler scope with arguments, should they be weakref'd? (@. *can* they be weakref'd, given that structs aren't refcounted, only the backing store; TBH, it's more a question for primitive handlers, where unboxing a native value that is going to be discarded anyway should avoid unnecessary copy-on-writes when manipulating the unboxed primitive)

// tell app "Finder" { get document_file at 1 of home } // Q. if {…} is record, need to decide if blocks can be expressed as records or if they should have distinct syntax (could use parens, as those are for grouping and we can't change that as arithmetic requires it)

// handlers with operator syntax should be non-maskable and non-mutable by default




//

/*
 
 syntax
 
 // command without argument
 foo
 
 // command with unary argument (any type; will be coerced to single-item record)
 foo arg1
 
 // command with multi-value argument (record labels are optional; if omitted, record fields are matched by position)
 foo {arg1, arg2, …}
 foo {label1: arg1,label2: arg2, …}
 
 // command with AE-style labels
 foo {directArg, label1: arg1, label2: arg2, …}
 
 // command with implicit record punctuation (can punctuation be reliably inferred? in case of nested commands, the inner command must either be wholly parenthesized or use explicit record punctuation… assuming that anything after it is parsed as labeled arguments to outer command; if the parser treats subsequent tokens as belonging to inner command then parens become mandatory which rather defeats the point); note: when parsing for editor, parser should be able to disambiguate (or flag for user to do so) given dictionary of known commands
 foo directArg label1: arg1 label2: arg2 …
 foo label1: arg1 label2: arg2 …
 
 
 */


// TO DO: Identifier, aka argument-less command; performs lookup; if handler, calls it, else returns as-is; Q. what if it gets a block?

// Q. mutability? if implementing `editable` as class wrapper with var

class Command: ComplexValue {
    
    typealias Argument = (label: Symbol?, value: Value)
    
    var description: String {
        return self.arguments.count == 0 ? self.name.name : "\(self.name.name) {\(self.arguments.map{ "\($0 == nil ? "" : "\($0!.name):")\($1)" }.joined(separator: ", "))}"
    }

    let nominalType: Coercion = asCommand
    
    let name: Symbol
    let arguments: [Argument] // TO DO: single, optional argument which is coerced to record and pattern-matched against HandlerInterface.Parameter
    
    init(_ name: Symbol, _ arguments: [Argument] = []) {
        self.name = name
        self.arguments = arguments
    }
    
    internal var _handler: Handler = _bindHandlerOnFirstUse

    // TO DO: also capture operator? or leave that to pretty-printer? (it depends: Command.eval() needs operator info to generate decent error messages); suppose Handler might provide operator info itself
    
    // TO DO: this caching won't work if Environment is responsible for call handling; the alternative is for Environment to return stored values wrapped in ValueAccessorHandler struct (that adds a bit of cost: extra call + extra stack frame)
    
    // TO DO: problem: making the eval func mutating doesn't match Value protocol's eval; only solutions are to make Command a class, or for Command struct to use a class-based backing store as its cache
    // one possibility is for Environment.call() to return first call's result plus some sort of closure that can be cached by Command for making subsequent calls more efficiently (e.g. for a non-maskable read-only slot, it can return either handler's call method or a simple closure around constant value; for a non-maskable editable slot, it'd wrap Environment instance containing the slot and forward to that; for maskable slot, it'd return original Environment chain)
    func eval(in scope: Scope, as coercion: Coercion) throws -> Value {
        return try self._handler.call(with: self, in: scope, as: coercion) // updates self._handler on first call
        //return try coercion.coerce(value: self, in: scope)
    }
    func swiftEval<T: BridgingCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
        return try self._handler.swiftCall(with: self, in: scope, as: coercion) // updates self._handler on first call
        //return try coercion.coerce(value: self, in: scope)
    }
    
    // TO DO: if handler is static bound, we don't need to go through all this every time; just check params once and store array of operations to perform: omitted and constant args can be evaluated once and memoized; only exprs need evaled every time, and coercions may be minimized where arg's input coercion is member of expr's output coercion
    
    func value(at index: inout Int, for param: (label: Symbol, coercion: Coercion), in commandEnv: Scope) throws -> Value {
        let i = index
        //print("Unboxing argument \(paramKey)")
        let value: Value
        if index < self.arguments.count {
            let arg = self.arguments[index]
            if arg.label == nil || arg.label == param.label {
                value = arg.value
                index += 1
            } else {
                value = nullValue
            }
        } else {
            value = nullValue
        }
        do {
            return try value.eval(in: commandEnv, as: param.coercion)
        } catch {
            throw BadArgumentError(at: i, of: self).from(error)
        }
    }
    
    
    func swiftValue<T: BridgingCoercion>(at index: inout Int, for param: (label: Symbol, coercion: T), in commandEnv: Scope) throws -> T.SwiftType {
        let i = index
        //print("Unboxing argument \(paramKey)")
        let value: Value
        if index < self.arguments.count {
            let arg = self.arguments[index]
            if arg.label == nil || arg.label == param.label {
                value = arg.value
                index += 1
            } else {
                value = nullValue
            }
        } else {
            value = nullValue
        }
        do {
            return try value.swiftEval(in: commandEnv, as: param.coercion)
        } catch {
            throw BadArgumentError(at: i, of: self).from(error)
        }
    }
}
