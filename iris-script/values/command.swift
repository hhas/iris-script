//
//  command.swift
//  iris-lang
//

import Foundation

// operators reduce to commands with pre-bound handler from same library as operator syntax

// should environment slots be bind-once? (if mutability is provided by EditableValue class wrapper around immutable Value struct, there's no reason for it not to be; furthermore, the EditableValue may use the underlying value's nominalType as default if no type specified)


// set foo to: [] as editable list of: text

// set foo to: make new: editable list of: text

// set {foo, to: make {new: editable {list {of: text}}}}


// implement `if` as plain command, `e.g. `if…then:do…done`? avoids an operator definition and reads fairly naturally using low-punctuation command syntax, which aides memorization (if so, we need to make sure that `else` operator has lower precedence than low-punctuation command); Q. what about `to`/`when`/`repeat`/etc? (problem with those is that the natural preposition is `do:`/`doing:`, which rules out `do…done` for denoting a block)

// Q. what about `catching` operator? right now this doesn't allow for binding the thrown error to a specific name, nor does it allow for filtering the error type[s] to catch; we could deal with this much as Swift does, binding the error to a predefined name (`error`); or maybe allowing the right operand to be a single-parameter closure, relying on the parameter's optional `as` clause for filtering by error type (if the thrown error can be coerced to the specified error type[s], the error is passed to the closure to process, otherwise it's propagaged); need to give more thought to error management in general (e.g. being able to catch an error, correct the problem, then resume execution from the point it was thrown, all without permanently unrolling the call stack is an especially powerful continuation-style capability; or being able to suspend execution and immediately switch to interactive debugging mode at the initial failure point, regardless of a script's existing error-handling logic [and, bearing in mind, that the debugging console will be running in a separate process to the script itself, requiring IPC to to connect the two])


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

// TO DO: check for nullSymbol as name, duplicate argument labels?

public class Command: ComplexValue {
    
    public var swiftLiteralDescription: String { return "\(type(of: self))(\(self.name.swiftLiteralDescription)\(self.arguments.isEmpty ? "" : ", [\(self.arguments.map{"(\($0.label.swiftLiteralDescription), \($0.value.swiftLiteralDescription))"}.joined(separator: ", "))]"))" }
    
    public typealias Argument = Record.Field
    
    public var description: String {
        // TO DO: PP needs to apply operator syntax/quote name if command's name matches an existing operator (Q. how should operator definitions be scoped? per originating library, or per main script? [if we annotate command in parser, it'll presumably capture originating library's operator syntax])
        return "‘\(self.name.label)’" + (self.arguments.count == 0 ? "" : " {\(self.arguments.map{ "\(["", leftOperand, middleOperand, rightOperand].contains($0) ? "" : "\($0.label): ")\($1)" }.joined(separator: ", "))}")
    }
    
    public static let nominalType: Coercion = asCommand
    
    // TO DO: what about a slot for storing optional operator definition? (or general 'annotations' slot?) we also need to indicate when pp should wrap a command in elective parens (as opposed to required parens, which pp should add automatically as operator precedence dictates)
    
    public let name: Symbol
    public let arguments: [Argument] // TO DO: single, optional argument which is coerced to record and pattern-matched against HandlerInterface.Parameter
    
    public init(_ name: Symbol, _ arguments: [Argument] = []) {
        self.name = name
        self.arguments = arguments
    }
    
    public convenience init(_ name: Symbol, _ record: Record) {
        self.init(name, record.fields)
    }
    
    internal var _handler: Handler = _bindHandlerOnFirstUse

    // TO DO: also capture operator? or leave that to pretty-printer? (it depends: Command.eval() needs operator info to generate decent error messages); suppose Handler might provide operator info itself
    
    // TO DO: this caching won't work if Environment is responsible for call handling; the alternative is for Environment to return stored values wrapped in ValueAccessorHandler struct (that adds a bit of cost: extra call + extra stack frame)
    
    // TO DO: problem: making the eval func mutating doesn't match Value protocol's eval; only solutions are to make Command a class, or for Command struct to use a class-based backing store as its cache
    // one possibility is for Environment.call() to return first call's result plus some sort of closure that can be cached by Command for making subsequent calls more efficiently (e.g. for a non-maskable read-only slot, it can return either handler's call method or a simple closure around constant value; for a non-maskable editable slot, it'd wrap Environment instance containing the slot and forward to that; for maskable slot, it'd return original Environment chain)
    /*
    func eval(in scope: Scope, as coercion: Coercion) throws -> Value {
        print("Command.eval:", self, "as", coercion)
        return try coercion.coerce(value: self, in: scope)
        //return try self._handler.call(with: self, in: scope, as: coercion) // updates self._handler on first call
        //return try coercion.coerce(value: self, in: scope)
    }
    
    // TO DO: SwiftCoercion can only be used in generic methods, which is no use for native run-time coercions, where return type must always be Value
    
    // Q. what about monadic-like behavior, where swiftEval passes an object whose APIs guarantee to return a value of T
    
    func swiftEval<T: SwiftCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
        //return try self._handler.swiftCall(with: self, in: scope, as: coercion) // updates self._handler on first call
        return try coercion.unbox(value: self, in: scope)
    }
    */
    
    public func toValue(in scope: Scope, as coercion: Coercion) throws -> Value {
        return try self.toTYPE(in: scope, as: coercion)
    }
    
    public func toTYPE<T>(in scope: Scope, as coercion: Coercion) throws -> T {
        //print("Command.toTYPE", self, "as", T.self, type(of:coercion))
        if T.self is Value {
            return try self._handler.call(with: self, in: scope, as: coercion) as! T
        } else {
            return try self._handler.swiftCallAs(with: self, in: scope, as: coercion)
//            fatalError("TODO")
        }
    }

    // TO DO: if handler is static bound, we don't need to go through all this every time; just check params once and store array of operations to perform: omitted and constant args can be evaluated once and memoized; only exprs need evaled every time, and coercions may be minimized where arg's input coercion is member of expr's output coercion (this being said, it remains to be seen how much run-time optimization is warranted; e.g. if transpiling to Swift proves to be common practice then slow interpretation is much less of a concern)

    private func value(at index: inout Int, named label: Symbol) -> Value {
        if index < self.arguments.count {
            let arg = self.arguments[index]
            if arg.label.isEmpty || arg.label == label {
                index += 1
                return arg.value
            }
        }
        return nullValue
    }
        
    internal func value(at index: inout Int, for param: (label: Symbol, coercion: Coercion), in commandEnv: Scope) throws -> Value {
        let i = index
        do {
            return try self.value(at: &index, named: param.label).eval(in: commandEnv, as: param.coercion)
        } catch {
            throw BadArgumentError(at: i, of: self).from(error)
        }
    }
    
    // TO DO: really need to attach handler (or at least its interface)
    internal func swiftValue<T: SwiftCoercion>(at index: inout Int, for param: (label: Symbol, coercion: T), in commandEnv: Scope) throws -> T.SwiftType {
        let i = index
        do {
            //print("Command.swiftValue() for:", param, "from", self.arguments)
            return try self.value(at: &index, named: param.label).swiftEval(in: commandEnv, as: param.coercion)
        } catch { // TO DO: this catches both label mismatches and eval/coercion errors
            //print("Command.swiftValue() failed:", error)
            // TO DO: fix this; error message is misleading where command args are unlabeled
            let labels = self.arguments.map{$0.label}
            if labels.contains(param.label) {
                throw BadArgumentError(at: i, of: self).from(error) // TO DO: need better error description that compares expected labels to found labels, indicating mismatch
            } else {
                print(self)
                print(self._handler.interface)
                print(param)
                print("Couldn't match the `\(self.name.label)` handler’s `\(param.label.label)` parameter to any of the `\(self.name.label)` command’s labeled arguments: `\(self.arguments.map{$0.label.label}.filter{!$0.isEmpty}.joined(separator: ", "))`")
                throw UnknownArgumentError(at: i, of: self).from(error) // TO DO: need better error description that compares expected labels to found labels, indicating mismatch
            }
        }
    }
}


// TO DO: get rid of these
let leftOperand   = Symbol("left")
let middleOperand = Symbol("middle")
let rightOperand  = Symbol("right")

extension Command {
    
    // TO DO: also annotate Command instance with operator definition for use in error messages/pp
    
    convenience init(_ definition: PatternDefinition) {
        self.init(definition.name)
    }
    convenience init(_ definition: PatternDefinition, left: Value) { // TO DO: get rid of keywords; pass Values as Array and/or varargs and rely on PatternDefinition to supply correct arg labels (we need arg labels to distinguish overloaded operators, e.g. `op arg` vs `arg op`)
        self.init(definition.name, [(leftOperand, left)])
    }
    convenience init(_ definition: PatternDefinition, middle: Value) {
        self.init(definition.name, [(middleOperand, middle)])
    }
    convenience init(_ definition: PatternDefinition, right: Value) {
        self.init(definition.name, [(rightOperand, right)])
    }
    convenience init(_ definition: PatternDefinition, left: Value, right: Value) {
        self.init(definition.name, [(leftOperand, left), (rightOperand, right)])
    }
    convenience init(_ definition: PatternDefinition, left: Value, middle: Value, right: Value) {
        self.init(definition.name, [(leftOperand, left), (middleOperand, middle), (rightOperand, right)])
    }
}


extension Value { // parser converts all names to commands; provide convenience method to convert back
    
    func asIdentifier() -> Symbol? {
        if let cmd = self as? Command, cmd.arguments.isEmpty { return cmd.name } else { return nil }
    }
}

