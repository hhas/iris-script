//
//  matcher.swift
//  iris-script
//
//  PatternMatcher; used by parser to identify complex literals (list, record, group, block) and library-defined operators in token stream

import Foundation


// Q. given two different operators of same precedence but different associativity, should the latter affect which binds first?

// Q. how to carry forward current precedence and associativity? or should parser detect `OPNAME EXPR OPNAME` sequences itself?

// note that composite matches such as OptionalMatch can spawn multiple PatternMatches, one for each branch


// important: the first pattern in OperatorDefinition.pattern array must be a non-composite (it should be possible to eliminate this restriction - it's an artifact of current implementation)

// important: operator patterns must be one of the following: (OPNAME), (OPNAME EXPR […]), (EXPR OPNAME […])


struct PatternMatcher: CustomDebugStringConvertible { // a single pattern; this should advance when a .value is pushed onto stack (assuming no unreduced tokens between it and the previous .value which holds the previous match)
    
    var debugDescription: String {
        if self.isCompleted {
            return "«matcher found `\(self.definition.fullName)` (\(self.count) tokens)»"
        } else {
            return "«matcher wants \((self.remaining)) of `\(self.definition.fullName)`»"
        }
    }
    
    // note: PatternMatchers are initialized on first operator/punctuation in definition's pattern; if the pattern starts with an EXPR, the matcher is added to the preceding stack frame, otherwise it is added to the current one // TO DO: for now, if the preceding frame is not already reduced to .value, the match will fail
    
    let definition: OperatorDefinition
    
    let count: Int // no. of stack items matched by this pattern (Q. when is this determined? e.g. `1 * 2 + 3` will start `*` match on index 0; where does `+` match start? is 1*2 reduced first? (i.e. as soon as precedences of operators on either side of `2` can be compared)) // TO DO: this won't work if reductions are applied mid-stack; might need to rethink (e.g. if LH EXPR matches .endList, start would identify that token only, not the entire list - which needs reduced down before the matched operation can be reduced; in per-line parsing, that reduction must be performed by re-matching tail end of list from bottom [start] of stack, not top [end]); could use -ve offset from each matcher's index (since that shouldn't change)
        
    private let remaining: [Pattern] // any patterns to match to next Reduction[s] in parser stack; caution: do not assume these patterns are the same as definition.patterns[OFFSET..<END_INDEX]; they may be transformations of composite patterns
    
    private init(for definition: OperatorDefinition, count: Int, remaining: [Pattern]) {
        self.definition = definition
        self.count = count
        self.remaining = remaining
    }
    
    // TO DO: change this to class method that returns [PatternMatcher] after reifying pattern
    
    // TO DO: how to back-match operator patterns? (presumably keep reifying until we reach the relevant keyword, then backmatch all of those patterns against topmost frame[s] of parser stack)
    
    public init(for operatorDefinition: OperatorDefinition) {
        self.init(for: operatorDefinition, count: 1, remaining: [Pattern](operatorDefinition.pattern.dropFirst()))
    }
    
    // TO DO: to determine operator precedence parser needs to know matched operations' fixity; to do that, it needs to know the final pattern that was matched (or at least its first and last matches)… or does it? parser should be able to see which token.form was matched first/last: opname/punc or .value(_); if it's .value,
        
    private func nextMatch(withRemaining patterns: [Pattern] = []) -> PatternMatcher {
        return PatternMatcher(for: self.definition, count: self.count + 1, remaining: patterns)
    }
    
    public func match(_ form: Token.Form) -> [PatternMatcher] { // TO DO: need to take Token in order to match whitespace
        //print("matching .\(form) to", self, "…")
        if let pattern = self.remaining.first {
            var result = [PatternMatcher]()
           // print("reifying", pattern)
            for patternSeq in pattern.reify([Pattern](self.remaining.dropFirst())) { // reify returns one or more pattern sequences, each of which starts with a non-composite pattern which can be matched against current token
               // print("… gave us", patternSeq)
                if let pattern = patternSeq.first {
                   // print("matching reified:", patternSeq)
                   // if patternSeq.count == 2, case .token(.endList) = patternSeq[0] {
                   /// fatalError()
                   // }
                    let remaining = [Pattern](patternSeq.dropFirst())
                    switch pattern.match(form) {
                    case .fullMatch:
                        result.append(self.nextMatch(withRemaining: remaining))
                    case .partialMatch(let rest):
                        result.append(self.nextMatch(withRemaining: rest + remaining))
                    case .noMatch:
                        ()
                    }
                }
            }
            //print("  … ->", result)
            return result
        } else {
            //print(self, "  …is already fully matched")
            return [] // already fully matched
        }
    }
    
    public var isBeginning: Bool { return self.count == 1 } // if true, stack item is first Reduction in this match
    public var isCompleted: Bool { return self.remaining.isEmpty } // if true, stack item is last Reduction in this match
    
}
