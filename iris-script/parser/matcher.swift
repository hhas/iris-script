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


extension OperatorDefinitions {
    
    private static var _groupID = 0
    
    static func newGroupID() -> Int {
        self._groupID += 1
        return self._groupID
    }
    
    func patternMatchers() -> [PatternMatcher] { // returns one or more new pattern matchers for matching this operator
        let groupID = OperatorDefinitions.self.newGroupID()
        return self.flatMap{ $0.patternMatchers(groupID: groupID) }
    }
}

extension OperatorDefinition {
    
    func patternMatchers(groupID: Int? = nil) -> [PatternMatcher] { // returns one or more new pattern matchers for matching this operator
        let groupID = groupID ?? OperatorDefinitions.newGroupID()
        return self.pattern.reify().map{ PatternMatcher(for: self, matching: $0, groupID: groupID) }
    }
}


typealias Conjunctions = Set<Symbol>

// might want to return .yes/.maybe/.no for EXPR match

struct PatternMatcher: CustomStringConvertible, Equatable {
    // a single pattern; this should advance when a .value is pushed onto stack (assuming no unreduced tokens between it and the previous .value which holds the previous match)
    
    private static var _matchID = 0
    
    var description: String {
        return "«match \(self.matchID) of \(self.groupID) for \(self.remainingPattern.description) of `\(self.definition.precis)`\(self.isAFullMatch ? (self.isLongestPossibleMatch ? "✔︎" : "✓") : "") \(self.definition.precedence)»"
    }
    
    var name: Symbol { return self.definition.name }
    
    let matchID: Int // unique to a given match instance; TO DO: is this needed/used?
    let groupID: Int // all matchers returned by a OperatorDefinitions.patternMatchers() call share a common group ID; this should make it easier to discard non-longest match[es] where the operator name is overloaded, e.g. `+`/`-` (caution: this assumes that patternMatchers() is called once only per .operatorName token; it would probably be safer for parser to supply an ID based on the token's identity) (caution: for list/record/group literals the ID is always -1; being built-in primitives we assume they are never overloaded by libraries, although that is not currently enforced)
    
    static func == (lhs: PatternMatcher, rhs: PatternMatcher) -> Bool {
        return lhs.groupID == rhs.groupID && lhs.definition.name == rhs.definition.name
            && lhs.matchedPattern == rhs.matchedPattern && lhs.remainingPattern == rhs.remainingPattern
    }
    
    // note: PatternMatchers are initialized on first operator/punctuation in definition's pattern; if the pattern starts with an EXPR, the matcher is added to the preceding stack frame, otherwise it is added to the current one // TO DO: for now, if the preceding frame is not already reduced to .value, the match will fail
    
    let definition: OperatorDefinition
    
    let count: Int // no. of stack items matched by this pattern; initially 1 (caution: this count is incremented *before* the match is actually performed, the assumption being that parser will immediately discard failed matchers and keep only those whose match() returned true, at which point the count is correct)
    
    // pattern[0] is the pattern being matched and has already been reified
    private let remainingPattern: [Pattern] // any patterns to match to next Reduction[s] in parser stack; caution: do not assume these patterns are the same as definition.patterns[OFFSET..<END_INDEX]; they may be transformations of composite patterns
    
    // TO DO: logic would be easier to understand if the already-reified pattern currently being matched was held in `let currentPattern:Pattern` rather than being remainingPattern[0]
    
    private let matchedPattern: [Pattern]
        
    // called by OperatorDefinition.patternMatchers
    init(for definition: OperatorDefinition, matching remainingPattern: [Pattern], matched matchedPattern: [Pattern] = [], count: Int = 1, groupID: Int) {
        if remainingPattern.isEmpty { fatalError("Invalid pattern (zero-length): \(remainingPattern)") }
        self.definition = definition
        self.remainingPattern = remainingPattern
        self.matchedPattern = matchedPattern
        self.count = count
        PatternMatcher._matchID += 1
        self.matchID = PatternMatcher._matchID
        self.groupID = groupID
    }
        
    public func match(_ form: Token.Form, allowingPartialMatch: Bool = false) -> Bool {
        // currently, allowingPartialMatch is [almost?] always true as we need to match yet-to-be-reduced operands in order to determine operator precedence, which we need to know before we can decide which operands to reduce first (i.e. provisionally match then reduce in order of priority, confirming those matches still hold; it's not ideal and it's a bit brittle (e.g. using .testValue patterns to match anything except atomic literals will break), plus there's a fair amount of duct-tape currently holding it together too, but at least it gets something working which allows further development to proceed)
       // print("matching .\(form) to", self, "…")
        let isMatch: Bool
        if allowingPartialMatch { // TO DO: always allow partial match?
            if self.isAtBeginningOfMatch {
                isMatch = self.remainingPattern[0].match(form, extent: .end) // a new, unconsumed pattern sequence
            } else if self.isAFullMatch {
                assert(self.remainingPattern.count == 1)
                isMatch = self.remainingPattern[0].match(form, extent: .start) // a fully consumed pattern sequence, where the final pattern (i.e. pattern[0]) has already been matched
            } else {
                isMatch = self.remainingPattern[0].match(form)
            }
        } else {
            isMatch = self.remainingPattern[0].match(form)
        }
       // print("…", isMatch)
        return isMatch
    }
    
    func next() -> [PatternMatcher] {
        var remaining = self.remainingPattern
        let matched = self.matchedPattern + [remaining.removeFirst()]
        return remaining.reify().filter{!$0.isEmpty}.map{
            PatternMatcher(for: self.definition, matching: $0, matched: matched, count: self.count + 1, groupID: self.groupID)
        }
    }
    
    public var wantsExpression: Bool {
        switch self.remainingPattern.first! {
        case .expression: return true
        // TO DO: what about .test?
        default: return false
        }
    }
    
    public var isAtBeginningOfMatch: Bool { return self.count == 1 } // if true, match() will match the first pattern in the operator definition's pattern array
    
    public var isAtConjunction: Bool {
        if self.count > 2, case .keyword(_) = self.remainingPattern[0] { return true } else { return false }
    }
    
    public var isAFullMatch: Bool { // if match() returns true and a longer match isn't possible, the tokens identified by this matcher can be passed to the operator defintion's reducefunc
        // kludge: pattern array can end with any number of .optional/.zeroOrMore patterns
      ///  print(self.definition.precis,"full?", //[Pattern](self.pattern.dropFirst()).reify(), [Pattern](self.pattern.dropFirst()).reify().contains{$0.isEmpty})
        return [Pattern](self.remainingPattern.dropFirst()).reify().contains{ $0.isEmpty}
    } // if true, stack item is last Reduction in this match; caution: this does not mean a longer match cannot be made
    
    public var isLongestPossibleMatch: Bool {
        // also kludgy
        return self.next().isEmpty // in event that pattern ends with .zeroOrMore/.oneOrMore, there will always be a longer match possible
    }
    
    
    // TO DO: these are confusing/wrong; they test the remaining pattern, not the matched pattern; see also TODO on reductionOrderFor(): whereas a sub-optimally designed pattern sequence could return misleading result due to optionals and branching (it does: commands with optional direct arg _always_ report as having trailing expr, even when they don't), examining the actual matches made by a completed matcher should always give an accurate answer
    var hasLeadingExpression: Bool {
        if self.isAFullMatch {
            // remainingPattern[0] = pattern currently being matched; caller is responsible for calling match() to confirm it actually has matched the given token prior to calling hasLeadingExpression/hasTrailingExpression
            return (self.matchedPattern.first ?? self.remainingPattern.first!).isExpression // matched patterns are always non-composite; no optionals or branching
        } else {
            fatalError("WARNING: called hasLeadingExpression on incomplete match: \(self)")
            //print("WARNING: calling hasLeadingExpression on incomplete match: \(self)")
            //return self.remainingPattern.first!.hasLeadingExpression
        }
    }
    
    var hasTrailingExpression: Bool {
        if self.isAFullMatch {
         //   print("hasTrailingExpression:", self.definition.name, self.matchedPattern)
            // remainingPattern[0] = pattern currently being matched; caller is responsible for calling match() to confirm it actually has matched the given token prior to calling hasLeadingExpression/hasTrailingExpression
            return self.remainingPattern.first!.isExpression
        } else {
            fatalError("WARNING: called hasTrailingExpression on incomplete match: \(self)")
            //print("WARNING: calling hasTrailingExpression on incomplete match:", self)
            //return self.remainingPattern.last!.hasTrailingExpression
        }
    }
    
    var hasConjunction: Bool {
        return self.remainingPattern.reduce(0, {$0 + $1.keywords.count}) > 1 // TO DO: this [incorrect logic] assumes multiple keywords appear sequentially, which is not necessarily true: e.g. a poorly composed pattern such as `.anyOf(["FOO", "BAR"])` will currently break the parser by corrupting the blockMatchers stack; for now, we'll use this naive implementation while we get the rest of the parser working, as it's "good enough" for current operators such as `if…then…` and `do…done`; eventually we'll need to rework to make it return an accurate result regardless of how a pattern is constructed // TO DO: also bear in mind that this will only report correct result while the first keyword is being matched (what it should really do is always ignore the first [primary] keyword and only count the remaining conjunction keywords; e.g. consider an operator with two or more conjunctions)
    }
    
    var conjunctions: Conjunctions { // KLUDGE
        if case .keyword(_) = self.remainingPattern[0] {} else { print("BUG: conjunction should be called immediately after matching first keyword") }
        // TO DO: this returns *all* conjunctions (in the event pattern contains > 1 conjunction); is this appropriate? or do we just want to get the next conjunction[s] that appears? (although given the freedom allowed by patterns, it's possible to create all kinds of weird combinations)
        return Conjunctions(self.remainingPattern.dropFirst().flatMap{ $0.keywords.map{ $0.name } })
    }
    
    func startIndex(from lastTokenIndex: Int) -> Int { // lastTokenIndex is inclusive
        return lastTokenIndex - self.count + 1
    }
    
}



typealias ReductionOrder = OperatorDefinition.Associativity

func reductionOrderFor(_ leftMatch: PatternMatcher, _ rightMatch: PatternMatcher) -> ReductionOrder {
    // caution: if left op is postfix and right op is prefix, that's an `EXPR EXPR` syntax error; TO DO: should we detect and throw that here, or somewhere else?
    // caution: reductionOrderFor only indicates which of two overlapping operations should be reduced first; it does not indicate how that reduction should be performed, as the process for reducing unary operations is not quite the same as for binary operations
    if !leftMatch.hasLeadingExpression && !rightMatch.hasTrailingExpression {
        print("TODO: Found postfix \(leftMatch.name) operator followed by prefix \(rightMatch.name) operator (i.e. two adjacent expressions with no delimiter between). This should be treated as syntax error.")
    }
    let left = leftMatch.definition, right = rightMatch.definition
  //  print("reductionOrderFor:", leftMatch, rightMatch)
  //  print("\t…", left.name, leftMatch.hasTrailingExpression, " / ", right.name, rightMatch.hasLeadingExpression)
    if !leftMatch.hasTrailingExpression { // left operator is postfix so MUST reduce before right infix/postfix op
        return .left
    } else if !rightMatch.hasLeadingExpression { // right operator is prefix so MUST reduce before left prefix/infix op
        return .right
    } else if left.precedence != right.precedence {
        return left.precedence > right.precedence ? .left : .right
    } else { // both operators are the same precedence, e.g. `2 ^ 3 ^ 4`, so use associativity // TO DO: what if they're different operators with same precedence? // TO DO: what about operators that shouldn't compose (e.g. `A thru B`); report as syntax error or leave Command to throw coercion error at eval time?
        return left.associate == .left ? .left : .right
    }
}

