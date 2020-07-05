//
//  matcher.swift
//  iris-script
//
//  PatternMatch; used by parser to identify complex literals (list, record, group, block) and library-defined operators in token stream

import Foundation



typealias Symbols = Set<Symbol>

// might want to return .yes/.maybe/.no for EXPR match

struct PatternMatch: CustomStringConvertible, Equatable {
    // a single pattern; this should advance when a .value is pushed onto stack (assuming no unreduced tokens between it and the previous .value which holds the previous match)
        
    private static var _matchID = 0
    
    var description: String {
        return "«match `\(self.definition.precis)` U\(self.uniqueID) O\(self.originID) G\(self.groupID): \([Pattern](self.matchedPattern).description) \(self.remainingPattern[0]) \([Pattern](self.remainingPattern.dropFirst()).description)\(self.isAFullMatch ? (self.isLongestFullMatch ? "✔︎" : "✓") : "") \(self.definition.precedence)»"
    }
    
    var count: Int { return self.matchedPattern.count + 1 }
    
    var name: Symbol { return self.definition.name }
    
    // matcher IDs are used to reconcile conjunctions and to discard non-longest full matches
    
    let uniqueID: Int // unique to a given match instance; used by `==` to compare for identity
    let originID: Int // identifies all matchers that originated from the same pattern definition at the same .operatorName(…) token (if the pattern branches, all descendants retain the same originID)
    let groupID: Int // identifies all matchers that originated at the same .operatorName(…) token (if an operator name is overloaded with multiple definitions, each in-progress match has a different originID but same groupID); be aware that whereas atom/prefix matchers start on .operatorName(…) token, infix/postfix backtrack to start on its preceding EXPR, thus two in-progress matches that share the same groupID should not be assumed to be the same length
        
    let definition: PatternDefinition

    // patterns that were matched by earlier instances of this matcher (not including the pattern currently being matched)
    private let matchedPattern: [Pattern]
    
    // pattern[0] is the pattern currently being matched and has already been reified; this is followed by zero or more additional patterns which have yet to be matched // TO DO: is it worth moving remainingPattern[0] to its own `let currentPattern:Pattern` slot?
    private let remainingPattern: [Pattern] // any patterns to match to next Reduction[s] in parser stack (caution: do not assume these patterns are the same as definition.patterns[OFFSET..<END_INDEX])
        
    // called by PatternDefinition.newMatches
    init(for definition: PatternDefinition, matching remainingPattern: [Pattern], matched matchedPattern: [Pattern] = [], groupID: Int, originID: Int) {
        assert(!remainingPattern.isEmpty, "Invalid PatternMatch (remainingPattern is empty): \(definition.precis)")
        self.definition = definition
        self.remainingPattern = remainingPattern
        self.matchedPattern = matchedPattern
        self.groupID = groupID
        self.originID = originID // equivalent to (groupID,patternDefinition) product
        PatternMatch._matchID += 1
        self.uniqueID = PatternMatch._matchID // used for identity-based `==`
    }
    
    public func fullyMatches(form: Token.Form) -> Bool {
        return self.remainingPattern[0].fullyMatch(form)
    }
    
    public func provisionallyMatches(form: Token.Form) -> Bool {
        // currently, partial matching is almost always used as we need to match yet-to-be-reduced operands in order to determine operator precedence, which we need to know before we can decide which operands to reduce first (i.e. provisionally match then reduce in order of priority, confirming those matches still hold; it's not ideal and it's a bit brittle (e.g. using .testValue patterns to match anything except atomic literals will break), plus there's a fair amount of duct-tape currently holding it together too, but at least it gets something working which allows further development to proceed)
       // print("matching .\(form) to", self, "…")
        guard let pattern = self.remainingPattern.first else { fatalError("No pattern left to match: \(self)") }
        let isMatch: Bool
        
        // TO DO: this is not right
        if pattern.isExpression {
            if self.isAtBeginningOfMatch { // if we are backmatching left operand, match end of EXPR only
                isMatch = pattern.provisionallyMatchEnd(form)
            } else { // otherwise we’re matching the start of an EXPR at the head of token stack
                isMatch = pattern.provisionallyMatchBeginning(form)
            }
        } else {
            isMatch = pattern.fullyMatch(form)
        }
       // print("…", isMatch)
        return isMatch
    }

    
    func next() -> [PatternMatch] {
        var remaining = self.remainingPattern
        let matched = self.matchedPattern + [remaining.removeFirst()]
        return remaining.reify().filter{!$0.isEmpty}.map{
            PatternMatch(for: self.definition, matching: $0, matched: matched, groupID: self.groupID, originID: self.originID)
        }
    }
    
    public var wantsExpression: Bool { // TO DO: currently unused
        switch self.remainingPattern.first! {
        case .expression, .testValue(_): return true
        default: return false
        }
    }
    
    public var isAtBeginningOfMatch: Bool { return self.matchedPattern.isEmpty } // when true, PatternMatch.match() will match the first pattern in the operator definition's remainingPattern array
    
    public var isAtConjunction: Bool { // when true, the pattern currently being matched is a conjunction keyword (i.e. assuming that patterns will *always* start with either `EXPR KEYWORD …` or `KEYWORD EXPR …`, we ignore the first two matches; this assumption is currently not enforced, but probably could/should be [preferably in glue generator to avoid additional startup overheads])
        if self.matchedPattern.count > 1, case .keyword(_) = self.remainingPattern[0] { return true } else { return false }
    }
    
    public var isAFullMatch: Bool { // if match() returns true and a longer match isn't possible, the tokens identified by this matcher can be passed to the operator defintion's reducefunc // caution: isAFullMatch only indicates that this matcher represents a complete match of its pattern; to determine if a longer match is/isn’t possible, get isLongestFullMatch as well
        // kludge: pattern array can end with any number of .optional/.zeroOrMore patterns
      
     //   print(self.definition.precis,"full?", [Pattern](self.remainingPattern.dropFirst()).reify(), ![Pattern](self.remainingPattern.dropFirst()).reify().contains{!$0.isEmpty})
        
        // reify() returns an array of one or more [Pattern], each one representing a possible branch; if any of those subarrays are empty, it means that particular branch has been fully matched ending on the current pattern
        return self.remainingPattern.dropFirst().reify().contains{ $0.isEmpty }
    }
    
    public var isLongestFullMatch: Bool {
        // caution: if the pattern ends with .zeroOrMore(…) or .oneOrMore(…) then a longer match is *always* possible, in which case this will *always* return false (in practice repeating sections should be bounded, e.g. `do…done`, but this isn’t enforced); TO DO: check that such matches will always eventually reduce, based on longest completed match, once fullyReduceExpression() is called
        return self.next().isEmpty
    }
    
    var autoReduce: Bool {
        return self.definition.autoReduce // TO DO: calculate this from matched pattern (i.e. must start and end with non-expr: atom, list/record/group, block [though not LP commands as those are already reduced by parser])
    }
    
    var hasLeftOperand: Bool {
        // TO DO: do we need this warning? (pattern matchers will always report true/false correctly for left operand)
        if !self.isAFullMatch { print("WARNING: called hasLeftOperand on incomplete match: \(self)") }
        // remainingPattern[0] is the pattern currently being matched
        return (self.matchedPattern.first ?? self.remainingPattern.first!).isExpression // reification ensures the pattern currently being matched is always non-composite; no optionals or branching
    }
    
    var hasRightOperand: Bool {
        // caution: caller is responsible for calling fullyMatches() to confirm the current token matches prior to calling hasRightOperand // TO DO: the problem here is that it's possible for a pattern to branch, with one branch looking for terminating keyword and other looking for trailing EXPR, and we've no way to know which answer is relevant until the match has completed (even then, just checking if it's *a* full match is not really helpful as it may not be the longest full match available); need to give this more thought
        if !self.isAFullMatch { fatalError("WARNING: called hasRightOperand on incomplete match: \(self)") }
        return self.remainingPattern.first!.isExpression
    }
    
    var hasConjunction: Bool {
        return self.remainingPattern.reduce(0, {$0 + $1.keywords.count}) > 1 // TO DO: this [incorrect logic] assumes multiple keywords appear sequentially, which is not necessarily true: e.g. a poorly composed pattern such as `.anyOf(["FOO", "BAR"])` will currently break the parser by corrupting the blockStack; for now, we'll use this naive implementation while we get the rest of the parser working, as it's "good enough" for current operators such as `if…then…` and `do…done`; eventually we'll need to rework to make it return an accurate result regardless of how a pattern is constructed
    }
    
    var conjunctions: Symbols { // returns all conjunctions after the current match; KLUDGE
        //if case .keyword(_) = self.remainingPattern[0] {} else { print("BUG: conjunction should be called immediately after matching first keyword") } // TO DO: in the case of `if…then…else…`, getting the matchers from the `else` token on stack causes this line to print a spurious error; we really need to figure out how to return accurate lists of conjunctions (e.g. given operator `foo…bar…baz…`, what happens if `bar…` is missing? the `foo…???` matcher will look for either `bar` OR `baz` - so what now happens/should happen in that case?)
        // TO DO: this returns *all* remaining conjunctions (in the event pattern contains > 1 conjunction); is this appropriate? or do we just want to get the next conjunction[s] that appears? (although given the freedom allowed by patterns, it's possible to create all kinds of weird combinations)
        
        // note: because new infix operator patterns are matched to both operator name AND its preceding expression as soon as they are created, it is sufficient to ignore those two matches when checking for any conjunctions
        
        return Symbols(self.remainingPattern.dropFirst().flatMap{ $0.keywords.map{ $0.name } })
    }
    
    func startIndex(from lastTokenIndex: Int) -> Int { // lastTokenIndex is inclusive
        return lastTokenIndex - self.count + 1
    }
        
    static func == (lhs: PatternMatch, rhs: PatternMatch) -> Bool {
        return lhs.uniqueID == rhs.uniqueID
    }
}



// used by reductionForOperatorExpression() to determine which of two overlapping operations to reduce first

// TO DO: given two different operators of same precedence but different associativity, should associativity affect which binds first?


typealias ReductionOrder = PatternDefinition.Associativity


func reductionOrderFor(_ leftMatch: PatternMatch, _ rightMatch: PatternMatch) -> ReductionOrder {
    // caution: reductionOrderFor only indicates which of two overlapping operations should be reduced first; it does not indicate how that reduction should be performed, as the process for reducing unary operations is not quite the same as for binary operations
    if !leftMatch.hasRightOperand && !rightMatch.hasLeftOperand {
        // caution: if left op is postfix and right op is prefix, that's a syntax error (`EXPR EXPR`); TO DO: should we detect and report here, or somewhere else?
        print("TODO: Found postfix \(leftMatch.name) operator followed by prefix \(rightMatch.name) operator (i.e. two adjacent expressions with no delimiter between). This should be treated as syntax error.")
    }
    let left = leftMatch.definition, right = rightMatch.definition
  //  print("reductionOrderFor:", leftMatch, rightMatch)
  //  print("\t…", left.name, leftMatch.hasRightOperand, " / ", right.name, rightMatch.hasLeftOperand)
    if !leftMatch.hasRightOperand { // left operator is postfix so MUST reduce before right infix/postfix op
        return .left
    } else if !rightMatch.hasLeftOperand { // right operator is prefix so MUST reduce before left prefix/infix op
        return .right
    } else if left.precedence != right.precedence {
        return left.precedence > right.precedence ? .left : .right
    } else { // both operators are the same precedence, e.g. `2 ^ 3 ^ 4`, so use associativity // TO DO: what if they're different operators with same precedence? // TO DO: what about operators that shouldn't compose (e.g. `A thru B`); report as syntax error or leave Command to throw coercion error at eval time?
        return left.associate == .left ? .left : .right
    }
}

