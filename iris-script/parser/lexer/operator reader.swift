//
//  operator reader.swift
//  iris-script
//

import Foundation


// TO DO: given undifferentiated .symbols token, decompose into one or more .symbols and/or .operator(OperatorDefinition) tokens and unpop back onto token stream


// - word-based operators (e.g. `mod`) are whole-token match against .letters, caveat where word has contiguous `:` suffix indicating it's a record field/argument label


// - symbol-based operators (e.g. `≠`) require both whole-token matching and longest-substring-match of .symbol content (note that: whole-token matching of .symbol is just an opportunistic shortcut for a longest match that consumes all chars; it may or may not be worth the effort in practice, though seeing as it's one quick Dictionary lookup it hardly increases implementation complexity or performance overhead)


// Q. should we disallow digits within operator names? (probably: it'll keep operator matching much simpler; contiguous sequences of digits [and words] after a non-operator word can then unambiguously be reduced to single Name lexeme)

// note: 'longest match' cannot resolve ambiguous combinations where a .symbols content can be matched as either a long operator + unknown symbol or a shorter operator + longer operator; however, inclined to keep it that way as it makes grammar rules simple for user to memorize ("for alternate interpretation, stick a space in")


// Q. what about currency and measurement prefixes/suffixes? should they have their own single-task reader, or be provided as part of operator reader? (given that units attach directly to literal numbers and aren't meant to be parameterizable with arbitrary exprs [cf prefix/postfix operators], it's probably best to make them their own reader that adjoins the numeric reader)


// Q. when is a word not an operator? A. when it's a argument/field label; Addendum: also [probably] when it's part of a reverse domain name-style reference, e.g. `com.example.mod` should not treat `mod` as modulus operator or it's going to get messy [note: if user writes same reference using `of` operator, they will need to single-quote 'mod' to disambiguate]. Main gotcha here is that a postfix operator followed by a period looks awfully similar (however, if period is an expr delimiter it should have whitespace after it to disambiguate)


// Q. should `use` annotation automatically import syntax? (if so, how to ensure reliable syntax versioning?) also be aware that when importing syntax from >1 library [including stdlib], conflicting operator definitions will need to be resolved (this may be a reason to make `.syntax[.version]` mandatory: a library that starts out without operators but adds them later defeats the versioning)

// Q. if library A defines `*` and `**`, and library B defines `***`, how do we disambiguate? they won't report as a conflict when added to operator matching tables [since they don't terminate at the same node], and checking for all possible combination-based clashes is not scalable


// Q. how should e.g. `mod123` be parsed - as word operator + digits, or as [command] name?


// eventually all operators defined in compiled libraries should be validated and reduced to quick-loading format; for now, we probably want to validate all operators as they're read (e.g. checking for reserved chars, name/definition collisions within/between libraries, mixed token types in names)


struct OperatorDefinition: Lexeme, CustomStringConvertible {
    
    // TO DO: this may be better expressed as a pattern, which can be loaded directly into parser's matching table (Q. how do we deal with trinary operators? second name may be matched as another operator, or as letters/symbols)
    
    var description: String { return "Lexeme(\(self.name))" }
    
    enum Name {
        case word(Symbol)
        case symbol(Symbol)
        
        init?(_ name: String) {
            switch name {
            case wordCharacters:    self = .word(Symbol(name))
            case symbolCharacters:  self = .symbol(Symbol(name))
            default:                return nil
            }
        }
    }
    
    let name: Name
    let aliases: [Name]
    
    init?(_ name: String, aliases: [String] = []) { // native libraries should always use this API; primitive libraries will use it until they can build pre-validated, pre-optimized definitions, at which point they can skip these checks at load-time [except when running in troubleshooting mode]
        guard let name = Name(name) else { return nil }
        self.name = name
        self.aliases = [] // TO DO
    }
    
    
    // Q. what about operand positions? Q. what about multi-part names in trinary+ operators (e.g. `A ? B : C`)? (entoli/sylvia used custom parsefuncs that, once matched on first token and invoked, could do anything they liked thereafter; this time around, we want to avoid open-ended/non-introspectable behaviors, which means we really want to match against table-defined patterns, e.g. standard infix is `[operand, operator, operand]`; right-associative might put a modifier on the right operand) Q. what about overloaded operators, e.g. +/- (should they share single definition that can hold multiple patterns, or separate definitions with single-definition storage)?
    
}



// TO DO: once primitive libraries support pre-built operator tables (presumably as prepopulated registry instances), we'll need some way to composite multiple such tables into one (Q. how to conflict-check? probably do that lazily, getting all tables to match a given token, checking there are no conflicting results, then caching that mapping/match to avoid need for conflict-checks on subsequent matches)

class OperatorRegistry { // caution: being a shared resource, this may need locking/copying to prevent modification once populated // TO DO: use a line reader to populate this from `«include: @com.example.mylib.syntax.1»` annotations at top of script? problem: this requires fully parsing all annotations [at least up to the first non-annotation token]
    
    // Q. is `A < B as NF` valid as a trinary operator? [i.e. mixed symbol+word styles] (given that `A comes_before B as case_sensitive_text` would be the likelier form, it's arguable; alternatively, we could throw all caution to the wind and use considering/ignoring blocks, but they create conflicting semantics where application handlers would want to respect them but library handlers generally don't; TBH it's a pig of a situation, but most likely solution is that all application handlers will get extra `timeout:` and `ignoring:` parameters [c.f. appscript] added automatically, and if library handlers want to provide equivalent parameters they must explicitly declare them)
    
    // TO DO: we really want to bind library handler directly to Command, and also attach the operator definition for use by pretty printer; one compromise is for operator definition to point back to library, and leave handler lookup to first call (note: once a script is nominally compiled, it'll retain the Command + library ID, and possibly the operator name that appears in the code for use in error messages, but not the operator definition)
    
    private var wordOperators   = [String: OperatorDefinition]() // whole-token matches
    private var symbolOperators = [String: OperatorDefinition]() // whole-token matches; also need separate longest-match tree
    
    // TO DO: as alternative to populating match table are parse-time, what about pre-building tables into libraries themselves?
    
    // TO DO: may want longest match for words as well, e.g. autosuggest, autocomplete (including underscore autoinsertion)
    
    struct PartialMatch  { // TO DO: main parser needs a variation on this to match complex expr patterns (literal tokens/parameterized exprs, optional/repeating units)
        
        private var nextMatch = [Character: PartialMatch]()
        private var definition: OperatorDefinition? // problem: what about overloaded operators which have >1 fixity (e.g. +/-)? or do we punt the problem, leaving it to parsefunc to determine which operand[s] are missing/present? or do we leave it a glorious free-for-all, where libraries can attach any number of operator definitions to an operator name, and it's up to parser to sort them out/complain about conflicts (Q. where there is a conflict, how can user disambiguate? or do we just say to avoid importing the problem syntax and invoke the underlying command within a `tell LIBRARY…` block?)
        
        mutating func add(_ name: Substring, _ definition: OperatorDefinition) {
            if let char = name.first {
                if self.nextMatch[char] == nil { self.nextMatch[char] = PartialMatch() }
                self.nextMatch[char]!.add(name.dropFirst(1), definition)
            } else {
                self.definition = definition
            }
        }
        
        func match(_ value: Substring) -> (endIndex: String.Index, definition: OperatorDefinition)? {
            if let char = value.first, let partialMatch = self.nextMatch[char] {
                if let fullMatch = partialMatch.match(value.dropFirst(1)) {
                    return fullMatch
                } else if let definition = self.definition {
                    return (value.startIndex, definition) // TO DO: check this isn't off-by-one
                }
            }
            return nil
        }
    }
    
    private var symbolMatcher = PartialMatch()
    
    
    
    func add(_ definition: OperatorDefinition) {
        
    }
    
    
    // TO DO: should matchWord/matchSymbols take token and return tokens?
    
    func matchWord(_ value: Substring) -> OperatorDefinition? {
        return self.wordOperators[value.lowercased()]
    }
    
    func matchSymbols(_ value: Substring) -> [(Substring, OperatorDefinition)] { // returned substrings should be slices of same underlying string as value
        if let result = self.symbolOperators[String(value)] { return [(value, result)] }
        var symbols = value
        var result = [(Substring, OperatorDefinition)]()
        while symbols != "" {
            if let (endIndex, definition) = self.symbolMatcher.match(symbols) {
                result.append((symbols.prefix(upTo: endIndex), definition))
                symbols = symbols.suffix(from: endIndex)
            } else {
                symbols = symbols.dropFirst(1)
            }
        }
        return result
    }
}


//typealias OperatorDefinition = (name: OperatorName, precedence: Int, parseFunc: ParseFunc, aliases: [OperatorName], handlerName: String?) // operands and associativity determined by parsefunc (in the case of trinary operators, parsefunc would also match [key]word between 2nd and 3rd operands [right now, only trinary operators we're considering are comparison operators with optional `as` clause])



// TO DO: need to rethink reader chaining as unwrapping/rewrapping of readers within next() is a giant PITA to get right; (from outside, we want something like monadic bind that pipelines output of one reader as input to next without the composing code having to worry about connection details)


struct OperatorReader: TokenReader {
    
    let reader: TokenReader
    let operators: OperatorRegistry
    
    var code: String { return self.reader.code }
    
    init(_ reader: TokenReader, for operators: OperatorRegistry) {
        self.reader = reader
        self.operators = operators
    }
    
    func next() -> (Token, TokenReader) {
        var (token, reader) = self.reader.next()
        reader = OperatorReader(reader, for: self.operators)
        switch token.form {
        // TO DO: ignore token
        case .letters where !(token.isRightContiguous && reader.next().0.form == .colon): // ignore if it's a field/argument `label:`
            if let definition = self.operators.matchWord(token.content) {
                (token, reader) = (token.extract(.lexeme(definition)), reader)
            }
        case .symbols:
            let matches = self.operators.matchSymbols(token.content)
            // TO DO: this'd be simpler if matchSymbols built and returned the new token stream (only issue is that matches are made first to last whereas unpopping tokens needs to be done from last match to first; i.e. use recursion rather than loop)
            if matches.count > 0 {
                var idx = token.content.endIndex
                for (substr, definition) in matches.reversed() {
                    if substr.endIndex != idx { // if operator is followed by non-operator symbols, put those back on token stream firt
                        reader = UnpopToken(token.extract(.symbols, from: substr.endIndex, to: idx), reader)
                    }
                    // put operator back on token stream
                    reader = UnpopToken(token.extract(.lexeme(definition), from: substr.startIndex, to: substr.endIndex), reader)
                    idx = substr.startIndex
                }
                if idx == token.content.startIndex { // put any non-operator symbols before first operator back onto token stream
                    (token, reader) = reader.next()
                } else {
                    (token, reader) = (token.extract(.symbols, from: token.content.startIndex, to: idx), reader)
                }
            }
        default: ()
        }
        return (token, reader) // TO DO: it is awfully easy to forget to rewrap chained readers, and even easier to rewrap the wrong reader
    }
    
}



func newOperatorReader(for operators: OperatorRegistry) -> EditableScript.LineReaderAdapter {
    return { (reader: TokenReader) -> TokenReader in return OperatorReader(reader, for: operators) }
}
