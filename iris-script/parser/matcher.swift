//
//  matcher.swift
//  iris-script
//
//  PatternMatcher; used by parser to identify complex literals (list, record, group, block) and library-defined operators in token stream

import Foundation


// TO DO: FIX: match fails to complete if last pattern is .optional(…); need to revise initialization to generate all matchers and return them to be matched one at a time against token; those that succeed are shifted onto stack frame along with token


// Q. given two different operators of same precedence but different associativity, should the latter affect which binds first?

// Q. how to carry forward current precedence and associativity? or should parser detect `OPNAME EXPR OPNAME` sequences itself?

// note that composite matches such as OptionalMatch can spawn multiple PatternMatches, one for each branch


// important: the first pattern in OperatorDefinition.pattern array must be a non-composite (it should be possible to eliminate this restriction - it's an artifact of current implementation)

// important: operator patterns must be one of the following: (OPNAME), (OPNAME EXPR […]), (EXPR OPNAME […])


extension OperatorDefinition {
    
    // list/record/group/block literals are also defined as operators for pattern-matching purposes

    func patternMatchers() -> [PatternMatcher] { // returns one or more new pattern matchers for matching this operator
        return self.pattern.reify().map{ PatternMatcher(for: self, matching: $0) }
    }
}


// match(form) should return MatchResult.completed/.partial([remaining])/.none, and that should be put on stack

// might want to return .yes/.maybe/.no for EXPR match

struct PatternMatcher: CustomStringConvertible { // a single pattern; this should advance when a .value is pushed onto stack (assuming no unreduced tokens between it and the previous .value which holds the previous match)
    
    var description: String {
        return "«matcher for \(self.patterns.description) of `\(self.definition.precis)`»"
    }
    
    // note: PatternMatchers are initialized on first operator/punctuation in definition's pattern; if the pattern starts with an EXPR, the matcher is added to the preceding stack frame, otherwise it is added to the current one // TO DO: for now, if the preceding frame is not already reduced to .value, the match will fail
    
    let definition: OperatorDefinition
    
    let count: Int // no. of stack items matched by this pattern
    
    // pattern[0] is the pattern being matched and has already been reified
    private let patterns: [Pattern] // any patterns to match to next Reduction[s] in parser stack; caution: do not assume these patterns are the same as definition.patterns[OFFSET..<END_INDEX]; they may be transformations of composite patterns
    
    // think EXPR needs to match unreduced values (e.g. .operatorName, where fixity allows)
    
    // called by OperatorDefinition.patternMatchers()
    init(for definition: OperatorDefinition, matching patterns: [Pattern], count: Int = 1) {
        if patterns.isEmpty { fatalError("Invalid pattern (zero-length): \(patterns)") }
        self.definition = definition
        self.patterns = patterns
        self.count = count
    }
    
    // TO DO: how to back-match operator patterns? (presumably keep reifying until we reach the relevant keyword, then backmatch all of those patterns against topmost frame[s] of parser stack)
    
    // problem with backmatching is that it doesn't capture the matcher in stack if preceding frame isn't already reduced
    
    // TO DO: to determine operator precedence parser needs to know matched operations' fixity; to do that, it needs to know the final pattern that was matched (or at least its first and last matches)… or does it? parser should be able to see which token.form was matched first/last: opname/punc or .value(_); if it's .value,
    
    public func match(_ form: Token.Form) -> Bool {
        //print("matching .\(form) to", self, "…")
        return self.patterns[0].match(form)
    }
    
    func next() -> [PatternMatcher] {
        return [Pattern](self.patterns.dropFirst()).reify().filter{!$0.isEmpty}.map{
            PatternMatcher(for: self.definition, matching: $0, count: self.count + 1)
        }
    }
    
    public var isAtBeginningOfMatch: Bool { return self.count == 1 } // if true, match() will match the first pattern in the operator definition's pattern array
    
    public var isAFullMatch: Bool { // if match() returns true and a longer match isn't possible, the tokens identified by this matcher can be passed to the operator defintion's reducefunc
        // kludge: pattern array can end with any number of .optional/.zeroOrMore patterns
        return ([Pattern](self.patterns.dropFirst()).reify().first{$0.isEmpty}) != nil
    } // if true, stack item is last Reduction in this match; caution: this does not mean a longer match cannot be made
    
    public var isLongestPossibleMatch: Bool {
        // also kludgy
        return self.next().isEmpty // in event that pattern ends with .zeroOrMore/.oneOrMore, there will always be a longer match possible
    }
}
