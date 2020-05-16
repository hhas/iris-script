//
//  pattern matcher.swift
//  iris-script
//
//  used by parser

import Foundation



// note that composite matches such as OptionalMatch can spawn multiple PatternMatches, one for each branch

struct PatternMatch: CustomDebugStringConvertible { // a single pattern; this should advance when a .value is pushed onto stack (assuming no unreduced tokens between it and the previous .value which holds the previous match)
    
    var debugDescription: String {
        if self.isComplete {
            return "<Matched \(self.operatorDefinition)>"
        } else {
            return "<Matching \(formatPattern(self.remaining)) of \(self.operatorDefinition)>"
        }
    }
    
    // note: matches are started on first operator/punctuation, backtracking to match any leading EXPRs in the pattern
    
    let operatorDefinition: OperatorDefinition
    
    let start: Int // index of first stack item matched by this pattern (Q. when is this determined? e.g. `1 * 2 + 3` will start `*` match on index 0; where does `+` match start? is 1*2 reduced first? (i.e. as soon as precedences of operators on either side of `2` can be compared))
    //private(set) var end: Int
    
    let remaining: [Pattern] // any patterns to match to next Reduction[s] in parser stack; caution: do not assume these patterns are the same as operatorDefinition.patterns[OFFSET..<END_INDEX]; they may be transformations of composite patterns
    
    var firstPattern: Pattern? { return self.remaining.first }
    var remainingPatterns: [Pattern] { return [Pattern](self.remaining.dropFirst()) }
    
    func nextMatch(with extraPatterns: [Pattern] = []) -> PatternMatch {
        return PatternMatch(operatorDefinition: self.operatorDefinition, start: self.start, remaining: extraPatterns + self.remainingPatterns)
    }
    
    
    func match(_ reduction: Parser.Reduction) -> PatternMatch? {
        //print("matching", reduction, "to", self)
        if let pattern = self.firstPattern {
            switch pattern.match(reduction) {
            case .fullMatch:
                return self.nextMatch()
            case .partialMatch(let remaining):
                return self.nextMatch(with: remaining)
            case .noMatch:
                return nil
            case .noConsume:
                return self.nextMatch().match(reduction) // TO DO: confirm this is correct (e.g. what if pattern ends with -LF?)
            }
        } else {
            //print(self, "is already fully matched")
            return nil // already fully matched
        }
    }
    
    var isComplete: Bool { return self.remaining.isEmpty } // if true, stack item is last Reduction in this match
    
    //let index: Int // TO DO: this is insufficient to handle composite patterns; might be better to use [Pattern], which can be outputted by CompositePatterns (e.g. AnyPattern will pick the sequence whose first token matches and return that, followed by rest of parent pattern, as flat array; RepeatingPattern will return rest of its pattern followed by `OptionalPattern(self)` followed by rest of parent pattern); one challenge is trailing optional pattern: if it only partially matches then need to rollback to before that match [but isn't that always the case with Optional(SEQUENCE)?]
    // include rollback index for stack (i.e. last point where a match with optional tail pattern could be completed, or the point before the match started)
    
    
    // Q. how does pattern-seq matching work? optional seqs are the challenge; use rollback? (that'd need to rollback both pattern and matched token) is it better to let matches build up and wait for something else to trigger reductions, at which point matches can be analyzed? [the challenge with that is we generally want to find longest matches from start of code, not end]; allowing matches to accummulate means more opportunity to disambiguate ambiguous code, e.g. allowing parse to succeed with `SHORT LONG` match rather than failing on `LONGEST INVALID`, while still preferring `LONG SHORT`
}

// Q. given two different operators of same precedence but different associativity, should the latter affect which binds first?

// Q. how to carry forward current precedence and associativity? or should parser just look for `OPNAME1 EXPR OPNAME2` sequences itself
