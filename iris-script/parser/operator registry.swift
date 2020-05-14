//
//  operators.swift
//  iris-script
//

import Foundation

// TO DO: how to associate library-defined operators with library-defined handlers? (this is particularly troublesome if two libraries define the same operator)


// TO DO: underlying handlers need to be implemented as multimethods (at least for overloaded operators, e.g. +/-, which have different left and/or right operands); the handler name should always be the operator's canonical name (*not* an alias name); note that where two libraries import identically named handlers into same namespace, these should be represented in that space as an mm, assuming dispatch can be done on arguments (what to do if parameters also conflict?)

// eventually all operators defined in compiled libraries should be validated and reduced to quick-loading format; for now, we probably want to validate all operators as they're read (e.g. checking for reserved chars, name/definition collisions within/between libraries, mixed token types in names)




struct OperatorClass: CustomDebugStringConvertible { // all operators that use a given name // TO DO: define as class rather than struct? it would reduce no. of method calls needed to populate PartialMatch tree to one add() per OpClass rather than one add() per OpDef
    
    var debugDescription: String {
        return "<\(self.name.label) \(self.operations.map{String(describing: $0.pattern)}.joined(separator: " "))>"
    }
    
    let name: Symbol // .operatorName(_) needs to include the name of the operator for reporting purposes (i.e. we can't just pass operation array)

    private(set) var operations = [OperatorDefinition]()
    
    init(name: Symbol) {
        self.name = name // this is the name under which the Operation is stored in registry (a single Operation may be stored under multiple names); the name itself it may be canonical name, alias, and/or conjunction for one or more operators; when the tokenizer matches that name, it outputs an .operatorName(OperatorDefinitions) token and it's up to parser to determine which definition it is (e.g. if it's a conjunction in an Operation that's already partially matched, or if it's the start of a new match, or both)
     }
    
    mutating func add(_ operation: OperatorDefinition) {
        // TO DO: how to detect conflicting definitions? (could be tricky, plus it could impact bootstrap times)
        self.operations.append(operation)
    }
}







class OperatorRegistry: CustomDebugStringConvertible { // caution: being a shared resource, this may need locking/copying to prevent modification once populated // TO DO: use a line reader to populate this from `«include: @com.example.mylib.syntax.1»` annotations at top of script? problem: this requires fully parsing all annotations [at least up to the first non-annotation token]
    
    // Q. is `A < B as NF` valid as a trinary operator? [i.e. mixed symbol+word styles] (given that `A comes_before B as case_sensitive_text` would be the likelier form, it's arguable; alternatively, we could throw all caution to the wind and use considering/ignoring blocks, but they create conflicting semantics where application handlers would want to respect them but library handlers generally don't; TBH it's a pig of a situation, but most likely solution is that all application handlers will get extra `timeout:` and `ignoring:` parameters [c.f. appscript] added automatically, and if library handlers want to provide equivalent parameters they must explicitly declare them)
    
    // TO DO: we really want to bind library handler directly to Command, and also attach the operator definition for use by pretty printer; one compromise is for operator definition to point back to library, and leave handler lookup to first call (note: once a script is nominally compiled, it'll retain the Command + library ID, and possibly the operator name that appears in the code for use in error messages, but not the operator definition)
    
    var debugDescription: String { return "OperatorRegistry<\(self.wordOperators.keys) \(self.symbolOperators.keys)>" }
    
    typealias OperatorTable = [String: OperatorClass] // maps a single keyword to all operators that use that keyword
    
    private var wordOperators   = OperatorTable() // whole-token matches
    private var symbolOperators = OperatorTable() // whole-token matches; also need separate longest-match tree
    
    var wordOperatorDefinitions: OperatorTable.Values { return self.wordOperators.values }
    var symbolOperatorDefinitions: OperatorTable.Values { return self.symbolOperators.values }
    
    // TO DO: as alternative to populating match table are parse-time, what about pre-building tables into libraries themselves?
    
    // TO DO: may want longest match for words as well, e.g. autosuggest, autocomplete (including underscore autoinsertion)
    
    struct PartialMatch  { // tree structure where each node can match a sequence of symbol characters to an operator class; used to perform longest match of symbol-based operator names
        
        private var matches = [Character: PartialMatch]()
        private var definitions: OperatorClass? // nil if this isn't a complete match
        
        mutating func add(_ name: Substring, _ definition: OperatorClass) {
            if let char = name.first {
                if self.matches[char] == nil { self.matches[char] = PartialMatch() }
                self.matches[char]!.add(name.dropFirst(1), definition)
            } else {
                //assert(self.definitions == nil) // TO DO: could this be troublesome if registry builds partial match tree before all operators have been defined? (as long as the new operator class is a superset of a previous one, no)
                self.definitions = definition
            }
        }
        
        func match(_ value: Substring) -> (endIndex: String.Index, definition: OperatorClass)? {
            guard let char = value.first else { // else reached end
                if let definitions = self.definitions {
                    return (value.endIndex, definitions)
                } else {
                    return nil
                }
            }
            if let fullMatch = self.matches[char]?.match(value.dropFirst(1)) {
                return fullMatch
            } else if let definitions = self.definitions {
                return (value.startIndex, definitions) // TO DO: check this isn't off-by-one
            } else {
                return nil
            }
        }
    }
    
    private var symbolMatcher = PartialMatch() // (note: symbolMatcher.description should always be nil)
    
    
    func add(_ definition: OperatorDefinition) {
        for name in definition.keywords {
            assert(!name.isEmpty)
            if name.isSymbolic {
                // TO DO: any performance difference using string rather than symbol as dictionary keys? (if not, use Symbol)
                if self.symbolOperators[name.key] == nil { self.symbolOperators[name.key] = OperatorClass(name: name) }
                self.symbolOperators[name.key]!.add(definition)
                self.symbolMatcher.add(Substring(name.key), self.symbolOperators[name.key]!)
            } else {
                if self.wordOperators[name.key] == nil { self.wordOperators[name.key] = OperatorClass(name: name) }
                self.wordOperators[name.key]!.add(definition)
            }
        }
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



extension OperatorRegistry {
    
    
    //     registry.prefix("NOT", 400)
    //     registry.infix(Keyword("≤", "<="), 540)
    //     registry.infix("else", 100, .right)
    
    // as in original, need sub-token matching of symbol char sequences

    func prefix(_ name: Keyword, _ precedence: Precedence, _ associate: OperatorDefinition.Associativity = .left) {
        self.add(OperatorDefinition(pattern: [.keyword(name), .expression], precedence: precedence, associate: associate))
    }
    func infix(_ name: Keyword, _ precedence: Precedence, _ associate: OperatorDefinition.Associativity = .left) {
        self.add(OperatorDefinition(pattern: [.expression, .keyword(name), Pattern.expression], precedence: precedence, associate: associate))
    }
    func postfix(_ name: Keyword, _ precedence: Precedence, _ associate: OperatorDefinition.Associativity = .left) {
        self.add(OperatorDefinition(pattern: [.expression, .keyword(name)], precedence: precedence, associate: associate))
    }
    func atom(_ name: Keyword, _ precedence: Precedence, _ associate: OperatorDefinition.Associativity = .left) {
        self.add(OperatorDefinition(pattern: [.keyword(name)], precedence: precedence, associate: associate))
    }
    func prefix(_ name: Keyword, conjunction: Keyword, _ precedence: Precedence, _ associate: OperatorDefinition.Associativity = .left) {
        self.add(OperatorDefinition(pattern: [.keyword(name), .expression, .keyword(conjunction), .expression], precedence: precedence, associate: associate))
    }
    func prefix(_ name: Keyword, terminator: Keyword, _ precedence: Precedence, _ associate: OperatorDefinition.Associativity = .left) {
        self.add(OperatorDefinition(pattern: [.keyword(name), .expression, .keyword(terminator)], precedence: precedence, associate: associate))
    }
    
    func add(_ pattern: [Pattern], _ precedence: Precedence = -100, _ associate: OperatorDefinition.Associativity = .left) {
        self.add(OperatorDefinition(pattern: pattern, precedence: precedence, associate: associate))
    }
}
