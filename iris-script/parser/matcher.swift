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

// TO DO: matcher should keep a complete record of the exact pattern sequence matched, with expr patterns annotated with the arg labels to use in Command (at minimum, it needs to keep a list of the arg labels to use, as those will be required to disambiguate overloaded operators with the same name but different operand count and/or position[s])


extension OperatorDefinition {
    
    // list/record/group/block literals are also defined as operators for pattern-matching purposes

    var patternMatchers: [PatternMatcher] { // returns one or more new pattern matchers for matching this operator
        return self.pattern.reify().map{ PatternMatcher(for: self, matching: $0) }
    }
}

extension OperatorDefinitions {
    
    // list/record/group/block literals are also defined as operators for pattern-matching purposes

    var patternMatchers: [PatternMatcher] { // returns one or more new pattern matchers for matching this operator
        return self.flatMap{ $0.patternMatchers }
    }
}


typealias Conjunctions = Set<Symbol>

// match(form) should return MatchResult.completed/.partial([remaining])/.none, and that should be put on stack

// might want to return .yes/.maybe/.no for EXPR match

struct PatternMatcher: CustomStringConvertible, Equatable {
    // a single pattern; this should advance when a .value is pushed onto stack (assuming no unreduced tokens between it and the previous .value which holds the previous match)
    
    private static var _matchID = 0
    
    var description: String {
        return "«matcher for \(self.pattern.description) of `\(self.definition.precis)`\(self.isAFullMatch ? (self.isLongestPossibleMatch ? "✔︎" : "✓") : "") \(self.definition.precedence)»"
    }
    
    var name: Symbol { return self.definition.name }
    
    let matchID: Int
    
    static func == (lhs: PatternMatcher, rhs: PatternMatcher) -> Bool {
        return lhs.matchID == rhs.matchID
    }
    
    // note: PatternMatchers are initialized on first operator/punctuation in definition's pattern; if the pattern starts with an EXPR, the matcher is added to the preceding stack frame, otherwise it is added to the current one // TO DO: for now, if the preceding frame is not already reduced to .value, the match will fail
    
    let definition: OperatorDefinition
    
    let count: Int // no. of stack items matched by this pattern; initially 1 (caution: this count is incremented *before* the match is actually performed, the assumption being that parser will immediately discard failed matchers and keep only those whose match() returned true, at which point the count is correct)
    
    // pattern[0] is the pattern being matched and has already been reified
    private let pattern: [Pattern] // any patterns to match to next Reduction[s] in parser stack; caution: do not assume these patterns are the same as definition.patterns[OFFSET..<END_INDEX]; they may be transformations of composite patterns
    
    // think EXPR needs to match unreduced values (e.g. .operatorName, where fixity allows)
    
    // called by OperatorDefinition.patternMatchers
    init(for definition: OperatorDefinition, matching pattern: [Pattern], count: Int = 1) {
        if pattern.isEmpty { fatalError("Invalid pattern (zero-length): \(pattern)") }
        self.definition = definition
        self.pattern = pattern
        self.count = count
        PatternMatcher._matchID += 1
        self.matchID = PatternMatcher._matchID
    }
    
    // TO DO: how to back-match operator patterns? (presumably keep reifying until we reach the relevant keyword, then backmatch all of those patterns against topmost frame[s] of parser stack)
    
    // problem with backmatching is that it doesn't capture the matcher in stack if preceding frame isn't already reduced
    
    // TO DO: to determine operator precedence parser needs to know matched operations' fixity; to do that, it needs to know the final pattern that was matched (or at least its first and last matches)… or does it? parser should be able to see which token.form was matched first/last: opname/punc or .value(_); if it's .value,
    
    public func match(_ form: Token.Form, allowingPartialMatch: Bool = false) -> Bool {
        //print("matching .\(form) to", self, "…")
        if allowingPartialMatch {
            if self.isAtBeginningOfMatch {
                return self.pattern[0].match(form, extent: .end)
            } else if self.isAFullMatch {
                return self.pattern[0].match(form, extent: .start)
            }
        }
        return self.pattern[0].match(form)
    }
    
    func next() -> [PatternMatcher] {
        return [Pattern](self.pattern.dropFirst()).reify().filter{!$0.isEmpty}.map{
            PatternMatcher(for: self.definition, matching: $0, count: self.count + 1)
        }
    }
    
    public var wantsExpression: Bool {
        switch self.pattern.first! {
        case .expression: return true
        // TO DO: what about .test?
        default: return false
        }
    }
    
    public var isAtBeginningOfMatch: Bool { return self.count == 1 } // if true, match() will match the first pattern in the operator definition's pattern array
    
    public var isAtConjunction: Bool {
        if self.count > 2, case .keyword(_) = self.pattern[0] { return true } else { return false }
    }
    
    public var isAFullMatch: Bool { // if match() returns true and a longer match isn't possible, the tokens identified by this matcher can be passed to the operator defintion's reducefunc
        // kludge: pattern array can end with any number of .optional/.zeroOrMore patterns
        return ([Pattern](self.pattern.dropFirst()).reify().first{$0.isEmpty}) != nil
    } // if true, stack item is last Reduction in this match; caution: this does not mean a longer match cannot be made
    
    public var isLongestPossibleMatch: Bool {
        // also kludgy
        return self.next().isEmpty // in event that pattern ends with .zeroOrMore/.oneOrMore, there will always be a longer match possible
    }
    
    
    var hasLeadingExpression: Bool { return self.pattern.first!.hasLeadingExpression }
    var hasTrailingExpression: Bool { return self.pattern.last!.hasLeadingExpression }
    
    var hasConjunction: Bool {
        return self.pattern.reduce(0, {$0 + $1.keywords.count}) > 1 // TO DO: this [incorrect logic] assumes multiple keywords appear sequentially, which is not necessarily true: e.g. a poorly composed pattern such as `.anyOf(["FOO", "BAR"])` will currently break the parser by corrupting the blockMatchers stack; for now, we'll use this naive implementation while we get the rest of the parser working, as it's "good enough" for current operators such as `if…then…` and `do…done`; eventually we'll need to rework to make it return an accurate result regardless of how a pattern is constructed // TO DO: also bear in mind that this will only report correct result while the first keyword is being matched (what it should really do is always ignore the first [primary] keyword and only count the remaining conjunction keywords; e.g. consider an operator with two or more conjunctions)
    }
    
    var conjunction: Conjunctions { // KLUDGE
        if case .keyword(_) = self.pattern[0] {} else { print("BUG: conjunction should be called immediately after matching first keyword") }
        // TO DO: this returns *all* conjunctions (in the event pattern contains > 1 conjunction); is this appropriate? or do we just want to get the next conjunction[s] that appears? (although given the freedom allowed by patterns, it's possible to create all kinds of weird combinations)
        return Conjunctions(self.pattern.dropFirst().flatMap{ $0.keywords.map{ $0.name } })
    }
}
