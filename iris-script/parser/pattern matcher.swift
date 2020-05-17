//
//  pattern matcher.swift
//  iris-script
//
//  used by parser

import Foundation



// note that composite matches such as OptionalMatch can spawn multiple PatternMatches, one for each branch

struct PatternMatcher: CustomDebugStringConvertible { // a single pattern; this should advance when a .value is pushed onto stack (assuming no unreduced tokens between it and the previous .value which holds the previous match)
    
    var debugDescription: String {
        if self.isComplete {
            return "<Fully-matched \(self.operatorDefinition)>"
        } else {
            return "<Matching \(formatPattern(self.remaining)) of \(self.operatorDefinition)>"
        }
    }
    
    // note: matches are started on first operator/punctuation, backtracking to match any leading EXPRs in the pattern
    
    let operatorDefinition: OperatorDefinition // TO DO: if we use patterns to match lists, etc, what to use as definition? should this be an enum?
    
    let start: Int // index of first stack item matched by this pattern (Q. when is this determined? e.g. `1 * 2 + 3` will start `*` match on index 0; where does `+` match start? is 1*2 reduced first? (i.e. as soon as precedences of operators on either side of `2` can be compared)) // TO DO: this won't work if reductions are applied mid-stack; might need to rethink (e.g. if LH EXPR matches .endList, start would identify that token only, not the entire list - which needs reduced down before the matched operation can be reduced; in per-line parsing, that reduction must be performed by re-matching tail end of list from bottom [start] of stack, not top [end]); could use -ve offset from each matcher's index (since that shouldn't change)
    
    //private(set) var end: Int
    
    let remaining: [Pattern] // any patterns to match to next Reduction[s] in parser stack; caution: do not assume these patterns are the same as operatorDefinition.patterns[OFFSET..<END_INDEX]; they may be transformations of composite patterns
    
    init(for operatorDefinition: OperatorDefinition, start: Int, remaining: [Pattern]) {
        self.operatorDefinition = operatorDefinition
        self.start = start
        self.remaining = remaining
    }
    
    init(for operatorDefinition: OperatorDefinition, start: Int) {
        self.operatorDefinition = operatorDefinition
        self.start = start
        self.remaining = [Pattern](operatorDefinition.pattern.dropFirst())
    }
    
    var firstPattern: Pattern? { return self.remaining.first }
    var remainingPatterns: [Pattern] { return [Pattern](self.remaining.dropFirst()) }
    
    /*
    func nextMatch(with extraPatterns: [Pattern] = []) -> [PatternMatcher] {
        return [PatternMatcher(for: self.operatorDefinition, start: self.start, remaining: extraPatterns + self.remainingPatterns)]
    }
    */
    
    func nextMatch(withRemaining remainingPatterns: [Pattern] = []) -> [PatternMatcher] {
        return [PatternMatcher(for: self.operatorDefinition, start: self.start, remaining: remainingPatterns)]
    }
    
    
    func match(_ form: Token.Form) -> [PatternMatcher] {
       // print("matching", form, "to", self)
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
                        result += self.nextMatch(withRemaining: rest)
                    case .partialMatch(let remaining): // TO DO: is this only place where multiple matches can spawn?
                        result += self.nextMatch(withRemaining: remaining + rest)
                    case .noMatch:
                        ()
                    case .noConsume:
                        result += self.nextMatch(withRemaining: rest).flatMap{$0.match(form)} // TO DO: confirm this is correct (e.g. what if pattern ends with -LF?)
                    }
                }
            }
            //print("… ->", result)
            return result
        } else {
           // print(self, "…is already fully matched")
            return [] // already fully matched
        }
    }
    
    var isComplete: Bool { return self.remaining.isEmpty } // if true, stack item is last Reduction in this match
    
    //let index: Int // TO DO: this is insufficient to handle composite patterns; might be better to use [Pattern], which can be outputted by CompositePatterns (e.g. AnyPattern will pick the sequence whose first token matches and return that, followed by rest of parent pattern, as flat array; RepeatingPattern will return rest of its pattern followed by `OptionalPattern(self)` followed by rest of parent pattern); one challenge is trailing optional pattern: if it only partially matches then need to rollback to before that match [but isn't that always the case with Optional(SEQUENCE)?]
    // include rollback index for stack (i.e. last point where a match with optional tail pattern could be completed, or the point before the match started)
    
    
    // Q. how does pattern-seq matching work? optional seqs are the challenge; use rollback? (that'd need to rollback both pattern and matched token) is it better to let matches build up and wait for something else to trigger reductions, at which point matches can be analyzed? [the challenge with that is we generally want to find longest matches from start of code, not end]; allowing matches to accummulate means more opportunity to disambiguate ambiguous code, e.g. allowing parse to succeed with `SHORT LONG` match rather than failing on `LONGEST INVALID`, while still preferring `LONG SHORT`
}

// Q. given two different operators of same precedence but different associativity, should the latter affect which binds first?

// Q. how to carry forward current precedence and associativity? or should parser just look for `OPNAME1 EXPR OPNAME2` sequences itself
