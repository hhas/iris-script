//
//  pattern matcher.swift
//  iris-script
//
//  used by parser

import Foundation


// Q. given two different operators of same precedence but different associativity, should the latter affect which binds first?

// Q. how to carry forward current precedence and associativity? or should parser detect `OPNAME EXPR OPNAME` sequences itself?

// note that composite matches such as OptionalMatch can spawn multiple PatternMatches, one for each branch

struct PatternMatcher: CustomDebugStringConvertible { // a single pattern; this should advance when a .value is pushed onto stack (assuming no unreduced tokens between it and the previous .value which holds the previous match)
    
    var debugDescription: String {
        if self.isComplete {
            return "<Fully-matched \(self.definition)>"
        } else {
            return "<Matching \(formatPattern(self.remaining)) of \(self.definition)>"
        }
    }
    
    // note: PatternMatchers are initialized on first operator/punctuation in definition's pattern; if the pattern starts with an EXPR, the matcher is added to the preceding stack frame, otherwise it is added to the current one // TO DO: for now, if the preceding frame is not already reduced to .value, the match will fail
    
    let definition: OperatorDefinition
    
    private(set) var start: Int // -ve offset to index of first stack item matched by this pattern (Q. when is this determined? e.g. `1 * 2 + 3` will start `*` match on index 0; where does `+` match start? is 1*2 reduced first? (i.e. as soon as precedences of operators on either side of `2` can be compared)) // TO DO: this won't work if reductions are applied mid-stack; might need to rethink (e.g. if LH EXPR matches .endList, start would identify that token only, not the entire list - which needs reduced down before the matched operation can be reduced; in per-line parsing, that reduction must be performed by re-matching tail end of list from bottom [start] of stack, not top [end]); could use -ve offset from each matcher's index (since that shouldn't change)
    
    //private(set) var end: Int
    
    let remaining: [Pattern] // any patterns to match to next Reduction[s] in parser stack; caution: do not assume these patterns are the same as definition.patterns[OFFSET..<END_INDEX]; they may be transformations of composite patterns
    
    private init(for definition: OperatorDefinition, start: Int = 0, remaining: [Pattern]) {
        self.definition = definition
        self.start = start
        self.remaining = remaining
    }
    
    // TO DO: change this to class method that returns [PatternMatcher] after reifying pattern
    
    // TO DO: how to back-match operator patterns? (presumably keep reifying until we reach the relevant keyword, then backmatch all of those patterns against topmost frame[s] of parser stack; Q. how to match .noConsume when doing this?)
    
    public init(for operatorDefinition: OperatorDefinition) {
        self.init(for: operatorDefinition, start: 0, remaining: [Pattern](operatorDefinition.pattern.dropFirst()))
    }
    
    var firstPattern: Pattern? { return self.remaining.first }
    var remainingPatterns: [Pattern] { return [Pattern](self.remaining.dropFirst()) }
    
    func nextMatch(withRemaining remainingPatterns: [Pattern] = []) -> PatternMatcher {
        return PatternMatcher(for: self.definition, start: self.start + 1, remaining: remainingPatterns)
    }
    
    func match(_ form: Token.Form) -> [PatternMatcher] {
        print("matching .\(form) to", self)
        if let firstPattern = self.firstPattern {
            var result = [PatternMatcher]()
           // print("reifying", firstPattern)
            for patternSeq in firstPattern.reify(self.remainingPatterns) {
               // print("… gave us", patternSeq)
                if let pattern = patternSeq.first {
                   // print("matching reified:", patternSeq)
                   // if patternSeq.count == 2, case .token(.endList) = patternSeq[0] {
                   /// fatalError()
                   // }
                    let rest = [Pattern](patternSeq.dropFirst())
                    switch pattern.match(form) {
                    case .fullMatch:
                        result.append(self.nextMatch(withRemaining: rest))
                    case .partialMatch(let remaining): // TO DO: is this only place where multiple matches can spawn?
                        result.append(self.nextMatch(withRemaining: remaining + rest))
                    case .noMatch:
                        ()
                    case .noConsume:
                        result += self.nextMatch(withRemaining: rest).match(form) // TO DO: confirm this is correct (e.g. what if pattern ends with -LF?)
                    }
                }
            }
            print("… ->", result)
            return result
        } else {
           // print(self, "…is already fully matched")
            return [] // already fully matched
        }
    }
    
    var isComplete: Bool { return self.remaining.isEmpty } // if true, stack item is last Reduction in this match
    
}
