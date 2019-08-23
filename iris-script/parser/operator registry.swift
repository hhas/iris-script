//
//  operators.swift
//  iris-script
//

import Foundation

// TO DO: how to associate library-defined operators with library-defined handlers? (this is particularly troublesome if two libraries define the same operator)


// TO DO: underlying handlers need to be implemented as multimethods (at least for overloaded operators, e.g. +/-, which have different left and/or right operands); the handler name should always be the operator's canonical name (*not* an alias name); note that where two libraries import identically named handlers into same namespace, these should be represented in that space as an mm, assuming dispatch can be done on arguments (what to do if parameters also conflict?)

// eventually all operators defined in compiled libraries should be validated and reduced to quick-loading format; for now, we probably want to validate all operators as they're read (e.g. checking for reserved chars, name/definition collisions within/between libraries, mixed token types in names)

typealias ParseFunc = (_ parser: Parser, _ definition: OperatorDefinition, _ leftExpr: Value?, _ allowLooseArguments: Bool) throws -> Value // TO DO: also pass operator name (e.g. for error reporting)? [not too worried about this as final implementation will be table driven, not recursive descent]


struct OperatorClass: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "<\(self.name == nil ? "nil" : String(describing: self.name!)) \([self.atom, self.prefix, self.infix, self.postfix, self.custom].map{$0 == nil ? "0" : "1"}.joined(separator: ""))>"
    }
    
    private(set) var name: OperatorDefinition.Name?
    
    private(set) var atom: OperatorDefinition?      // `OPERATOR_NAME`
    private(set) var prefix: OperatorDefinition?    // `OPERATOR_NAME RIGHT_OPERAND`, e.g. `-expr`
    private(set) var infix: OperatorDefinition?     // `LEFT_OPERAND OPERATOR_NAME RIGHT_OPERAND`, e.g. `expr + expr`
    private(set) var postfix: OperatorDefinition?   // `LEFT_OPERAND OPERATOR_NAME`, e.g. ``
    private(set) var custom: OperatorDefinition?    // custom parsefunc
    
    var isEmpty: Bool { return self.prefix == nil && self.infix == nil && self.postfix == nil && self.atom == nil }
    
    var hasLeftOperand: Bool { return self.infix != nil || self.postfix != nil }
    
    private func definition(for form: OperatorDefinition.Form) -> OperatorDefinition? { // used in add() above
        switch form {
        case .atom: return self.atom
        case .prefix: return self.prefix
        case .infix: return self.infix
        case .postfix: return self.postfix
        case .custom(_): return self.custom
        }
    }
    
    mutating func add(_ definition: OperatorDefinition) {
        if let d = self.definition(for: definition.form) { print("warning: overwriting existing operator definition \(d) with \(definition)") } // TO DO: should this be treated as implementation error if new definition != old definition (i.e. it's possible that two libraries will define the same custom operators to ensure availability whenever one of them is imported; assuming operators adhere to established semantics (e.g. arithmetic, algebraic symbols) then only predecences might mismatch, and assuming libraries are released sequentially then the 2nd library should just use the same precedence values as the first)
        switch definition.form {
        case .atom: self.atom = definition
        case .prefix: self.prefix = definition
        case .infix: self.infix = definition
        case .postfix: self.postfix = definition
        case .custom(_): self.custom = definition
        }
        self.name = definition.name
    }
}



struct OperatorDefinition: CustomDebugStringConvertible {
    
    var debugDescription: String { return "<OperatorDefinition \(self.name)>" }
    
    enum Name: Comparable, Hashable, CustomDebugStringConvertible {
        
        case word(Symbol)
        case symbol(Symbol) // TO DO: rename symbolic(_)? (easier to distinguish from .symbol token)
        
        var debugDescription: String {
            switch self {
            case .word(let s):   return String(describing: s)
            case .symbol(let s): return String(describing: s)
            }
        }
        
        var name: Symbol {
            switch self {
            case .word(let name): return name
            case .symbol(let name): return name
            }
        }
        
        init?(_ name: String) { // returns nil if non-valid characters are found; TO DO: throw instead?
            switch name {
            case nameCharacters:    self = .word(Symbol(name))
            case symbolCharacters:  self = .symbol(Symbol(name))
            default:                return nil
            }
        }
        
        private var key: String {
            switch self {
            case .word(let s): return s.key
            case .symbol(let s):  return s.key
            }
        }
        
        static func < (lhs: OperatorDefinition.Name, rhs: OperatorDefinition.Name) -> Bool {
            return lhs.key < rhs.key
        }
    }
    
    enum Form: Equatable {
        case prefix
        case infix
        case postfix
        case atom
        case custom(ParseFunc)
        
        static func ==(lhs: Form, rhs: Form) -> Bool {
            switch (lhs, rhs) { // TO DO: should custom prefix/infix forms also match standard prefix/infix forms?
            case (.prefix, .prefix): return true
            case (.infix, .infix): return true
            case (.postfix, .postfix): return true
            case (.atom, .atom): return true
            case (.custom(_), .custom(_)): return true // TO DO: what result?
            default: return false
            }
        }
    }
    
    enum Associativity {
        case left
        case right
    }
    
    let name: Name // the operator's canonical name, categorized as .word/.symbol, e.g. `.word(Symbol("if"))`, `.symbol(Symbol("÷"))`
    let aliases: [Name] // any other recognized names (pp will typically reduce these to canonical names), e.g. `.symbol(Symbol("/"))`; in particular, symbolic operators may define a word-based alternative to aid dictation-driven coding, e.g. `.word(Symbol("divided_by"))`
    let form: Form // operand position(s), if any
    let precedence: Precedence
    let associativity: Associativity
    // TO DO: token-matching patterns can generally be inferred from form, with caveat on more specialized operators - e.g. `as`, `if` - where it may be beneficial to supply custom pattern (i.e. if Pair is a native Value, it could wait until eval, or the pattern could express the required type; OTOH, if colon pair is pure syntax construct, it will need to be matched by a pattern [in which case need a `Pattern?` argument that allows default form-derived pattern to be overridden])
    
    init(_ name: String, _ form: Form, precedence: Precedence, associativity: Associativity = .left, aliases: [String] = []) { // native libraries should always use this API; primitive libraries will use it until they can build pre-validated, pre-optimized definitions, at which point they can skip these checks at load-time [except when running in troubleshooting mode]
        guard let n = Name(name) else { fatalError("Invalid operator name: \"\(name)\"") } // TO DO: throw instead?
        self.name = n
        self.form = form
//        if form != .atom && !operatorPrecedences.contains(precedence) { fatalError("Invalid operator precedence: \(precedence)") }
        self.precedence = precedence
        self.associativity = associativity
        self.aliases = aliases.map{ if let name = Name($0) { return name } else { fatalError("Invalid operator name: \"\($0)\"") }} // TO DO: throw instead?
    }
}





class OperatorRegistry: CustomDebugStringConvertible { // caution: being a shared resource, this may need locking/copying to prevent modification once populated // TO DO: use a line reader to populate this from `«include: @com.example.mylib.syntax.1»` annotations at top of script? problem: this requires fully parsing all annotations [at least up to the first non-annotation token]
    
    // Q. is `A < B as NF` valid as a trinary operator? [i.e. mixed symbol+word styles] (given that `A comes_before B as case_sensitive_text` would be the likelier form, it's arguable; alternatively, we could throw all caution to the wind and use considering/ignoring blocks, but they create conflicting semantics where application handlers would want to respect them but library handlers generally don't; TBH it's a pig of a situation, but most likely solution is that all application handlers will get extra `timeout:` and `ignoring:` parameters [c.f. appscript] added automatically, and if library handlers want to provide equivalent parameters they must explicitly declare them)
    
    // TO DO: we really want to bind library handler directly to Command, and also attach the operator definition for use by pretty printer; one compromise is for operator definition to point back to library, and leave handler lookup to first call (note: once a script is nominally compiled, it'll retain the Command + library ID, and possibly the operator name that appears in the code for use in error messages, but not the operator definition)
    
    var debugDescription: String { return "OperatorRegistry<\(self.wordOperators.keys) \(self.symbolOperators.keys)>" }
    
    typealias OperatorTable = [String: OperatorClass]
    
    private var wordOperators   = OperatorTable() // whole-token matches
    private var symbolOperators = OperatorTable() // whole-token matches; also need separate longest-match tree
    
    var wordOperatorDefinitions: OperatorTable.Values { return self.wordOperators.values }
    var symbolOperatorDefinitions: OperatorTable.Values { return self.symbolOperators.values }
    
    // TO DO: as alternative to populating match table are parse-time, what about pre-building tables into libraries themselves?
    
    // TO DO: may want longest match for words as well, e.g. autosuggest, autocomplete (including underscore autoinsertion)
    
    struct PartialMatch  {
        
        private var matches = [Character: PartialMatch]()
        private var definitions = OperatorClass()
        
        mutating func add(_ name: Substring, _ definition: OperatorDefinition) {
            if let char = name.first {
                if self.matches[char] == nil { self.matches[char] = PartialMatch() }
                self.matches[char]!.add(name.dropFirst(1), definition)
            } else {
                self.definitions.add(definition)
            }
        }
        
        func match(_ value: Substring) -> (endIndex: String.Index, definition: OperatorClass)? {
            guard let char = value.first else { // else reached end
                if !self.definitions.isEmpty {
                    return (value.endIndex, self.definitions)
                } else {
                    return nil
                }
            }
            if let fullMatch = self.matches[char]?.match(value.dropFirst(1)) {
                return fullMatch
            }
            if !self.definitions.isEmpty {
                return (value.startIndex, self.definitions) // TO DO: check this isn't off-by-one
            }
            return nil
        }
    }
    
    private var symbolMatcher = PartialMatch() // (note: symbolMatcher.description should always be nil)
    
    
    private func add(_ name: OperatorDefinition.Name, _ definition: OperatorDefinition) {
        switch name {
        case .word(let n):
            assert(!n.isEmpty)
            if self.wordOperators[n.key] == nil { self.wordOperators[n.key] = OperatorClass() }
            self.wordOperators[n.key]!.add(definition)
        case .symbol(let n):
            assert(!n.isEmpty)
            if self.symbolOperators[n.key] == nil { self.symbolOperators[n.key] = OperatorClass() }
            self.symbolOperators[n.key]!.add(definition)
            self.symbolMatcher.add(Substring(n.key), definition)
        }
    }
    
    func add(_ definition: OperatorDefinition) {
        self.add(definition.name, definition)
        for name in definition.aliases { self.add(name, definition) }
    }
    
    
    // TO DO: should matchWord/matchSymbols take token and return tokens?
    
    func matchWord(_ value: Substring) -> OperatorClass? {
        assert(!value.isEmpty)
        return self.wordOperators[value.lowercased()]
    }
    
    func matchSymbols(_ value: Substring) -> [(Substring, OperatorClass)] { // returned substrings should be slices of same underlying string as value
        assert(!value.isEmpty)
        if let result = self.symbolOperators[String(value)] { return [(value, result)] }
        var symbols = value
        var result = [(Substring, OperatorClass)]()
        while !symbols.isEmpty {
            if let (endIndex, definitions) = self.symbolMatcher.match(symbols) {
                result.append((symbols.prefix(upTo: endIndex), definitions))
                symbols = symbols.suffix(from: endIndex)
            } else {
                symbols = symbols.dropFirst(1)
            }
        }
        return result
    }
    
    func get(_ name: Symbol) -> OperatorClass? {
        return self.wordOperators[name.key] ?? self.symbolOperators[name.key]
    }
}



