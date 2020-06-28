//
//  matcher.swift
//  iris-script
//
//  PatternMatcher; used by parser to identify complex literals (list, record, group, block) and library-defined operators in token stream

import Foundation


// Q. given two different operators of same precedence but different associativity, should the latter affect which binds first?


// note that composite matches such as OptionalMatch can spawn multiple PatternMatches, one for each branch

// important: the first pattern in OperatorDefinition.pattern array must be a non-composite (it should be possible to eliminate this restriction - it's an artifact of current implementation)

// TO DO: matcher should keep a complete record of the exact pattern sequence matched, with expr patterns annotated with the arg labels to use in Command (at minimum, it needs to keep a list of the arg labels to use, as those will be required to disambiguate overloaded operators with the same name but different operand count and/or position[s])


extension OperatorDefinition {
    
    // list/record/group/block literals are also defined as operators for pattern-matching purposes

    func patternMatchers(groupID: Int = -1) -> [PatternMatcher] { // returns one or more new pattern matchers for matching this operator
        return self.pattern.reify().map{ PatternMatcher(for: self, matching: $0, groupID: groupID) }
    }
}

extension OperatorDefinitions {
    
    private static var _groupID = 0
    
    static func newGroupID() -> Int {
        self._groupID += 1
        return self._groupID
    }
    
    // list/record/group/block literals are also defined as operators for pattern-matching purposes

    func patternMatchers() -> [PatternMatcher] { // returns one or more new pattern matchers for matching this operator
        let groupID = OperatorDefinitions.self.newGroupID()
        return self.flatMap{ $0.patternMatchers(groupID: groupID) }
    }
}


typealias Conjunctions = Set<Symbol>

// might want to return .yes/.maybe/.no for EXPR match

struct PatternMatcher: CustomStringConvertible, Equatable {
    // a single pattern; this should advance when a .value is pushed onto stack (assuming no unreduced tokens between it and the previous .value which holds the previous match)
    
    private static var _matchID = 0
    
    var description: String {
        return "«matcher \(self.groupID)/\(self.matchID) for \(self.pattern.description) of `\(self.definition.precis)`\(self.isAFullMatch ? (self.isLongestPossibleMatch ? "✔︎" : "✓") : "") \(self.definition.precedence)»"
    }
    
    var name: Symbol { return self.definition.name }
    
    let matchID: Int
    let groupID: Int // all matchers returned by a OperatorDefinitions.patternMatchers() call share a common group ID; this should make it easier to discard non-longest match[es] where the operator name is overloaded, e.g. `+`/`-` (caution: this assumes that patternMatchers() is called once only per .operatorName token; it would probably be safer for parser to supply an ID based on the token's identity) (caution: for list/record/group literals the ID is always -1; being built-in primitives we assume they are never overloaded by libraries, although that is not currently enforced)
    
    static func == (lhs: PatternMatcher, rhs: PatternMatcher) -> Bool {
        return lhs.matchID == rhs.matchID
    }
    
    // note: PatternMatchers are initialized on first operator/punctuation in definition's pattern; if the pattern starts with an EXPR, the matcher is added to the preceding stack frame, otherwise it is added to the current one // TO DO: for now, if the preceding frame is not already reduced to .value, the match will fail
    
    let definition: OperatorDefinition
    
    let count: Int // no. of stack items matched by this pattern; initially 1 (caution: this count is incremented *before* the match is actually performed, the assumption being that parser will immediately discard failed matchers and keep only those whose match() returned true, at which point the count is correct)
    
    // pattern[0] is the pattern being matched and has already been reified
    private let pattern: [Pattern] // any patterns to match to next Reduction[s] in parser stack; caution: do not assume these patterns are the same as definition.patterns[OFFSET..<END_INDEX]; they may be transformations of composite patterns
        
    // called by OperatorDefinition.patternMatchers
    init(for definition: OperatorDefinition, matching pattern: [Pattern], count: Int = 1, groupID: Int) {
        if pattern.isEmpty { fatalError("Invalid pattern (zero-length): \(pattern)") }
        self.definition = definition
        self.pattern = pattern
        self.count = count
        PatternMatcher._matchID += 1
        self.matchID = PatternMatcher._matchID
        self.groupID = groupID
    }
        
    public func match(_ form: Token.Form, allowingPartialMatch: Bool = false) -> Bool {
        // currently, allowingPartialMatch is [almost?] always true as we need to match yet-to-be-reduced operands in order to determine operator precedence, which we need to know before we can decide which operands to reduce first (i.e. provisionally match then reduce in order of priority, confirming those matches still hold; it's not ideal and it's a bit brittle (e.g. using .testValue patterns to match anything except atomic literals will break), plus there's a fair amount of duct-tape currently holding it together too, but at least it gets something working which allows further development to proceed)
        //print("matching .\(form) to", self, "…")
        if true {//allowingPartialMatch {
            if self.isAtBeginningOfMatch {
                return self.pattern[0].match(form, extent: .end) // a new, unconsumed pattern sequence
            } else if self.isAFullMatch {
                assert(self.pattern.count == 1)
                return self.pattern[0].match(form, extent: .start) // a fully consumed pattern sequence, where the final pattern (i.e. pattern[0]) has already been matched
            }
        }
        return self.pattern[0].match(form)
    }
    
    func next() -> [PatternMatcher] {
        return [Pattern](self.pattern.dropFirst()).reify().filter{!$0.isEmpty}.map{
            PatternMatcher(for: self.definition, matching: $0, count: self.count + 1, groupID: self.groupID)
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
      ///  print(self.definition.precis,"full?", //[Pattern](self.pattern.dropFirst()).reify(), [Pattern](self.pattern.dropFirst()).reify().contains{$0.isEmpty})
        return [Pattern](self.pattern.dropFirst()).reify().contains{ $0.isEmpty}
    } // if true, stack item is last Reduction in this match; caution: this does not mean a longer match cannot be made
    
    public var isLongestPossibleMatch: Bool {
        // also kludgy
        return self.next().isEmpty // in event that pattern ends with .zeroOrMore/.oneOrMore, there will always be a longer match possible
    }
    
    
    // TO DO: these are confusing/wrong; they test the remaining pattern, not the matched pattern; see also TODO on reductionOrderFor(): whereas a sub-optimally designed pattern sequence could return misleading result due to optionals and branching, examining the actual matches made by a completed matcher should always give an accurate answer
    var hasLeadingExpression: Bool { return self.pattern.first!.hasLeadingExpression }
    var hasTrailingExpression: Bool { return self.pattern.last!.hasLeadingExpression }
    
    var hasConjunction: Bool {
        return self.pattern.reduce(0, {$0 + $1.keywords.count}) > 1 // TO DO: this [incorrect logic] assumes multiple keywords appear sequentially, which is not necessarily true: e.g. a poorly composed pattern such as `.anyOf(["FOO", "BAR"])` will currently break the parser by corrupting the blockMatchers stack; for now, we'll use this naive implementation while we get the rest of the parser working, as it's "good enough" for current operators such as `if…then…` and `do…done`; eventually we'll need to rework to make it return an accurate result regardless of how a pattern is constructed // TO DO: also bear in mind that this will only report correct result while the first keyword is being matched (what it should really do is always ignore the first [primary] keyword and only count the remaining conjunction keywords; e.g. consider an operator with two or more conjunctions)
    }
    
    var conjunctions: Conjunctions { // KLUDGE
        if case .keyword(_) = self.pattern[0] {} else { print("BUG: conjunction should be called immediately after matching first keyword") }
        // TO DO: this returns *all* conjunctions (in the event pattern contains > 1 conjunction); is this appropriate? or do we just want to get the next conjunction[s] that appears? (although given the freedom allowed by patterns, it's possible to create all kinds of weird combinations)
        return Conjunctions(self.pattern.dropFirst().flatMap{ $0.keywords.map{ $0.name } })
    }
    
    func startIndex(from endIndex: Int) -> Int {
        return endIndex - self.count + 1
    }
    
}
