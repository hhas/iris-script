//
//  operator registry.swift
//  iris-script
//

import Foundation

// TO DO: how to associate library-defined operators with library-defined handlers? (this is particularly troublesome if two libraries define the same operator)


// TO DO: underlying handlers need to be implemented as multimethods (at least for overloaded operators, e.g. +/-, which have different left and/or right operands); the handler name should always be the operator's canonical name (*not* an alias name); note that where two libraries import identically named handlers into same namespace, these should be represented in that space as an mm, assuming dispatch can be done on arguments (what to do if parameters also conflict?)

// eventually all operators defined in compiled libraries should be validated and reduced to quick-loading format; for now, we probably want to validate all operators as they're read (e.g. checking for reserved chars, name/definition collisions within/between libraries, mixed token types in names)


// TO DO: is there any use-case where the order of command arguments is *not* the same as order of operands?



class OperatorRegistry: CustomDebugStringConvertible { // caution: being a shared resource, this may need locking/copying to prevent modification once populated // TO DO: use a line reader to populate this from `«include: @com.example.mylib.syntax.1»` annotations at top of script? problem: this requires fully parsing all annotations [at least up to the first non-annotation token]
    
    // Q. is `A < B as NF` valid as a trinary operator? [i.e. mixed symbol+word styles] (given that `A comes_before B as case_sensitive_text` would be the likelier form, it's arguable; alternatively, we could throw all caution to the wind and use considering/ignoring blocks, but they create conflicting semantics where application handlers would want to respect them but library handlers generally don't; TBH it's a pig of a situation, but most likely solution is that all application handlers will get extra `timeout:` and `ignoring:` parameters [c.f. appscript] added automatically, and if library handlers want to provide equivalent parameters they must explicitly declare them)
    
    // TO DO: we really want to bind library handler directly to Command, and also attach the operator definition for use by pretty printer; one compromise is for operator definition to point back to library, and leave handler lookup to first call (note: once a script is nominally compiled, it'll retain the Command + library ID, and possibly the operator name that appears in the code for use in error messages, but not the operator definition)
    
    var debugDescription: String { return "OperatorRegistry<\(self.wordOperators.keys) \(self.symbolOperators.keys)>" }
    
    typealias OperatorTable = [String: OperatorDefinitions] // maps a single keyword to all operators that use that keyword
    
    private var wordOperators   = OperatorTable() // whole-token matches
    private var symbolOperators = OperatorTable() // whole-token matches (this is quicker than sub-token matching when a single symbolic operator is clearly delimited by words/punctuation/whitespace)
    
    var wordOperatorDefinitions: OperatorTable.Values { return self.wordOperators.values }
    var symbolOperatorDefinitions: OperatorTable.Values { return self.symbolOperators.values }
    
    private var symbolMatcher = PartialMatch() // (note: symbolMatcher.description should always be nil) // used by to perform sub-token matches where two or more symbolic operators are written contiguously; e.g. "1<=-2" tokenizes as [.value("1"), .symbols("<=-"), .value("2")], which OperatorReader rewrites to [.value("1"), .operator("<="), .operator("-"), .value("2")]
    
    // TO DO: as alternative to populating match table are parse-time, what about pre-building tables into libraries themselves?
    
    // TO DO: may want longest match for words as well, e.g. autosuggest, autocomplete (including underscore autoinsertion)
    
    struct PartialMatch { // tree structure where each node can match a sequence of symbol characters to an operator class; used to perform longest match of symbol-based operator names
        
        private var matches = [Character: PartialMatch]()
        private var definitions: OperatorDefinitions? // nil if this isn't a complete match
        
        mutating func add(_ name: Substring, _ definition: OperatorDefinitions) {
            if let char = name.first {
                if self.matches[char] == nil { self.matches[char] = PartialMatch() }
                self.matches[char]!.add(name.dropFirst(1), definition)
            } else {
                //assert(self.definitions == nil) // TO DO: could this be troublesome if registry builds partial match tree before all operators have been defined? (as long as the new operator class is a superset of a previous one, no)
                self.definitions = definition
            }
        }
        
        func match(_ value: Substring) -> (endIndex: String.Index, definition: OperatorDefinitions)? {
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
    
    func add(_ definition: OperatorDefinition) {
        for keyword in definition.keywords {
            for name in keyword.allNames {
                assert(!name.isEmpty)
                if name.isSymbolic {
                    if self.symbolOperators[name.key] == nil { self.symbolOperators[name.key] = OperatorDefinitions(name: name) }
                    self.symbolOperators[name.key]!.add(definition)
                    self.symbolMatcher.add(Substring(name.key), self.symbolOperators[name.key]!)
                } else {
                    if self.wordOperators[name.key] == nil { self.wordOperators[name.key] = OperatorDefinitions(name: name) }
                    self.wordOperators[name.key]!.add(definition)
                }
            }
        }
    }
    
    
    // TO DO: should matchWord/matchSymbols take token and return tokens?
    
    func matchWord(_ value: Substring) -> OperatorDefinitions? {
        assert(!value.isEmpty)
        return self.wordOperators[value.lowercased()]
    }
    
    func matchSymbols(_ value: Substring) -> [(Substring, OperatorDefinitions)] { // returned substrings should be slices of same underlying string as value
        assert(!value.isEmpty)
        if let result = self.symbolOperators[String(value)] { return [(value, result)] }
        var symbols = value
        var result = [(Substring, OperatorDefinitions)]()
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
    
    func get(_ name: Symbol) -> OperatorDefinitions? {
        return self.wordOperators[name.key] ?? self.symbolOperators[name.key]
    }
}



extension OperatorRegistry { // convenience methods for standard operator forms
    
    //     registry.prefix("NOT", 400)
    //     registry.infix(Keyword("≤", "<="), 540)
    //     registry.infix("else", 100, .right)
    
    // as in original, need sub-token matching of symbol char sequences

    // `OPNAME`
    func atom(_ name: Keyword, reducer: Parser.ReduceFunc? = nil) {
        self.add(OperatorDefinition(pattern: [.keyword(name)], autoReduce: true, reducer: reducer ?? reduceAtomOperator))
    }
    
    // `OPNAME EXPR`
    func prefix(_ name: Keyword, _ precedence: Precedence, reducer: Parser.ReduceFunc? = nil) {
        self.add(OperatorDefinition(pattern: [.keyword(name), .expression],
                                    precedence: precedence, reducer: reducer ?? reducePrefixOperator))
    }
    
    // `EXPR OPNAME EXPR`
    func infix(_ name: Keyword, _ precedence: Precedence, _ associate: OperatorDefinition.Associativity = .left, reducer: Parser.ReduceFunc? = nil) {
        self.add(OperatorDefinition(pattern: [.expression, .keyword(name), Pattern.expression],
                                    precedence: precedence, associate: associate, reducer: reducer ?? reduceInfixOperator))
    }
    
    // `EXPR OPNAME`
    func postfix(_ name: Keyword, _ precedence: Precedence, reducer: Parser.ReduceFunc? = nil) {
        self.add(OperatorDefinition(pattern: [.expression, .keyword(name)],
                                    precedence: precedence, reducer: reducer ?? reducePostfixOperator))
    }
    
    // `OPNAME EXPR OPNAME EXPR`
    func prefix(_ name: Keyword, conjunction: Keyword, _ precedence: Precedence, reducer: Parser.ReduceFunc? = nil) {
        self.add(OperatorDefinition(pattern: [.keyword(name), .expression, .keyword(conjunction), .expression],
                                    precedence: precedence, reducer: reducer ?? reducePrefixOperatorWithConjunction))
    }

    func prefix(_ name: Keyword, conjunction: Keyword, alternate: Keyword, _ precedence: Precedence, reducer: Parser.ReduceFunc? = nil) {
        self.add(OperatorDefinition(pattern:
            [.keyword(name), .expression, .keyword(conjunction), .expression, .optional([.keyword(alternate), .expression])],
                                    precedence: precedence, reducer: reducer ?? reducePrefixOperatorWithConjunctionAndAlternate))
    }
    
    // `OPNAME DELIM (EXPR DELIM)* OPNAME`
    func prefix(_ name: Keyword, suffix: Keyword, reducer: @escaping Parser.ReduceFunc = reduceKeywordBlock) {
        self.add(OperatorDefinition(pattern:
            [.keyword(name), DELIM, .zeroOrMore([.expression, DELIM]), .keyword(suffix)], // TO DO: LF*
                                    autoReduce: true, reducer: reducer))
    }
    
    // `EXPR OPNAME EXPR OPNAME EXPR`
    func infix(_ name: Keyword, conjunction: Keyword, _ precedence: Precedence, reducer: Parser.ReduceFunc? = nil) {
        self.add(OperatorDefinition(pattern: [.expression, .keyword(name), .expression, .keyword(conjunction), .expression],
                                    precedence: precedence, reducer: reducer ?? reduceInfixOperatorWithConjunction))
    }
    
    /*
    func add(_ pattern: [Pattern], _ precedence: Precedence = Precedence.min,
             _ associate: OperatorDefinition.Associativity = .left,
             autoReduce: Bool = false, reducer: @escaping Parser.ReduceFunc) {
        self.add(OperatorDefinition(pattern: pattern, precedence: precedence, associate: associate, autoReduce: autoReduce, reducer: reducer))
    }*/
}
