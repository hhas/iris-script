//
//  command.swift
//  libiris
//

import Foundation

// operators reduce to commands with pre-bound handler from same library as operator syntax

// set foo to: [] as editable list of: text

// set foo to: make new: editable list of: text

// set {foo, to: make {new: editable {list {of: text}}}}

// Q. what about `catching` operator? right now this doesn't allow for binding the thrown error to a specific name, nor does it allow for filtering the error type[s] to catch; we could deal with this much as Swift does, binding the error to a predefined name (`error`); or maybe allowing the right operand to be a single-parameter closure, relying on the parameter's optional `as` clause for filtering by error type (if the thrown error can be coerced to the specified error type[s], the error is passed to the closure to process, otherwise it's propagaged); need to give more thought to error management in general (e.g. being able to catch an error, correct the problem, then resume execution from the point it was thrown, all without permanently unrolling the call stack is an especially powerful continuation-style capability; or being able to suspend execution and immediately switch to interactive debugging mode at the initial failure point, regardless of a script's existing error-handling logic [and, bearing in mind, that the debugging console will be running in a separate process to the script itself, requiring IPC to to connect the two])

// commands are effectively right-associative prefix [unary]  operators (use record to pass multiple values); argument is optional (Q. how to distinguish `foo {nothing}` from `foo nothing`/`foo`)

// Q. when populating handler scope with arguments, should they be weakref'd? (@. *can* they be weakref'd, given that structs aren't refcounted, only the backing store; TBH, it's more a question for primitive handlers, where unboxing a native value that is going to be discarded anyway should avoid unnecessary copy-on-writes when manipulating the unboxed primitive)

// handlers with operator syntax should be non-maskable and non-mutable by default

// labels permit decoupling of interface from implementation in native handlers, so probably best not to use binding names as fallback when matching labeled arguments; rather, avoid unnecessary labels in primitive signatures (where label is omitted, the binding name—which is purely for documentation there—is automatically used as label); Q. should packaged native libraries require/add labels and/or coercions automatically?


// TO DO: also attach handler (or at least its interface) to command errors

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


public class Command: ComplexValue, LiteralConvertible, SelfEvaluatingValue {
    
    public typealias Argument = Record.Field
    public typealias Arguments = [Argument]
    
    public var swiftLiteralDescription: String {
        let args = self.arguments.isEmpty ? "" : ", \(self.arguments.swiftLiteralDescription)"
        // this ignores operatorPattern so transpiled code will use plain command syntax in error messages
        return "\(type(of: self))(\(self.name.label.debugDescription)\(args))"
    }
    
    public var literalDescription: String {
        // TO DO: PP needs to apply operator syntax/quote name if command's name matches an existing operator (Q. how should operator definitions be scoped? per originating library, or per main script? [if we annotate command in parser, it'll presumably capture originating library's operator syntax])
        return "‘\(self.name.label)’" + (self.arguments.count == 0 ? "" : " {\(self.arguments.map{ "\($0.isEmpty ? "" : "\($0.label): ")\($1)" }.joined(separator: ", "))}")
    }
    public var description: String { return self.literalDescription }
    
    public static let nominalType: NativeCoercion = asCommand.nativeCoercion
    
    public let name: Symbol
    public let arguments: Arguments // TO DO: single, optional argument which is coerced to record and pattern-matched against HandlerType.Parameter
    let operatorPattern: PatternMatch? // if the command was constructed from a matched operator, store that operator pattern for PP’s use // TO DO: what about using operator syntax in error messages? (note: error messages also require command to capture its position in source code [caveat relying on source string character offsets is suboptimal as those will change when code is pretty-printed; better to uniquely identify the AST node, perhaps with AST maintaining a lookup table from which to locate every Command node in tree without requiring a full recursive search; this all ties in with IDE support and queryable AST])
    
    public init(_ name: Symbol, _ arguments: Arguments = [], operatorPattern: PatternMatch? = nil) {
        // TO DO: check for nullSymbol as name, duplicate argument labels?
        self.name = name
        self.arguments = arguments
        self.operatorPattern = operatorPattern
    }
    
    public convenience init(_ name: Symbol, _ arguments: Record, operatorPattern: PatternMatch? = nil) {
        self.init(name, arguments.data, operatorPattern: operatorPattern)
    }
    
    internal var _handler: Callable = _bindHandlerOnFirstUse
    
    // TO DO: this caching won't work if Environment is responsible for call handling; the alternative is for Environment to return stored values wrapped in ValueAccessorHandler struct (that adds a bit of cost: extra call + extra stack frame)
    
    public func eval<T: SwiftCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
        return try self._handler.call(with: self, in: scope, as: coercion)
    }

    // TO DO: if handler is static bound, we don't need to go through all this every time; just check params once and store array of operations to perform: omitted and constant args can be evaluated once and memoized; only exprs need evaled every time, and coercions may be minimized where arg's input coercion is member of expr's output coercion (this being said, it remains to be seen how much run-time optimization is warranted; e.g. if transpiling to Swift proves to be common practice then slow interpretation is much less of a concern)
    
    public func value<T: SwiftCoercion>(for param: (label: Symbol, binding: Symbol, coercion: T), at index: inout Int, in commandEnv: Scope) throws -> T.SwiftType { // used by handler to unpack command’s arguments
        return try self.arguments.coerce(param: param, at: &index, in: commandEnv)
    }
}


public extension Command {
    
    convenience init(_ match: PatternMatch) {
        self.init(match.name, operatorPattern: match)
    }
    
    convenience init(_ match: PatternMatch, _ arguments: [Argument]) {
        self.init(match.name, arguments, operatorPattern: match)
    }
        
    convenience init(_ match: PatternMatch, _ arguments: Value...) {
        assert(arguments.count == match.argumentLabels.count) // these should _always_ be the same (any optional operands omitted in script will not appear in the final exact match); anything else is a bug
        // caution: this assumes operands will always have same ordering as parameters // TO DO: are there any use cases where operands may appear in different order to parameters? if so, reducefunc will also need HandlerType to reorder the arguments correctly
        self.init(match, [(Symbol, Value)](zip(match.argumentLabels, arguments)))
    }
}


public extension Value { // parser converts all names to commands; provide convenience method to convert back
    
    func asIdentifier() -> Symbol? {
        if let cmd = self as? Command, cmd.arguments.isEmpty { return cmd.name } else { return nil }
    }
}

