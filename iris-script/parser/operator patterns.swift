//
//  patterns.swift
//  iris-script
//

import Foundation


// A partial match succeeds in becoming a full match, or fails to match a Reduction before that


// TO DO: implement pattern sequences as linked lists? this might be more efficient as operations on patterns are push/pop (technically push is more splice: combine remaining patterns of this pattern's branch with remaining patterns in parent sequence and store that as a new PartialMatch, plus linked lists will refcount each node whereas an array of structs will refcount the array's owners only)


// TO DO: should .delimiter match one of `,.?!` followed by zero or more linebreaks? (i.e. are there any situations where trailing linebreaks *aren't* wanted?)

enum MatchResult {
    case fullMatch
    case partialMatch([Pattern]) // this Reduction was matched, but additional Reductions need to be matched as well
    case noMatch // match failed, so stop matching this pattern at this point
    case noConsume // match current Reduction to next pattern; e.g. when .ignoreLineBreaks is used, return .partialMatch([.ignoreLineBreaks]) if Reduction is .token(.lineBreak) or .noConsume if it's anything else
}


protocol PatternProtocol {
    
    // TO DO: problem with passing Parser to match() is that it tempts consuming multiple tokens, which disrupts other partial matches

    // on successful match of the given reduction (token, value, etc), return [] if it's a complete match or any patterns to match against subsequent tokens; if no match, return nil
    func match(_ reduction: Parser.Reduction) -> MatchResult
}



enum Pattern: PatternProtocol, CustomDebugStringConvertible {
    case keyword(Keyword)
    case pattern(CompositePattern)
    case expression // any value
    case value(Value.Type) // match specific type of literal value, e.g. Command; e.g. pipe operator has pattern [.expression, .keyword(";"), .value(Command.self)]; note: this should ignore grouping parens when testing value type (but not blocks?) - that shouldn't be an issue as parser should discard grouping parens around single expr (elective or precedence-overriding) while parens wrapped around expr-seq will be parsed as Block
    case delimiter // punctuation or linebreak required; e.g. prefix `to` operator should be left-delimited to avoid confusion with infix `to` conjunction; that delimiter may be start of code, linebreak, `(` (`[` and `{` would also work, although that implies `to` is being used within a record or list which is typically a semantic error as a list of closures should be defined using `as [handler]` cast; using `to` will bind them to current namespace as well)
    case lineBreaks // one or more // TO DO: needed? (i.e. are there any cases where punctuation isn't sufficient to delimit)
    case ignoreLineBreaks // skip over any contiguous linebreaks (normally linebreaks within an operation are a syntax error; exceptions are e.g. in `do … done` block)

    
    var debugDescription: String {
        switch self {
        case .keyword(let k):   return String(describing: k)
        case .pattern(let p):   return String(describing: p)
        case .expression:       return "EXPR"
        case .value(let t):     return String(describing: t)
        case .delimiter:        return "DELIM"
        case .lineBreaks:       return "LF"
        case .ignoreLineBreaks: return "-LF"
        }
    }
    
    func match(_ reduction: Parser.Reduction) -> MatchResult {
        switch self {
        case .keyword(let k):
            if case .token(let t) = reduction, case .operatorName(let d) = t.form, k.matches(d.name) {
                return .fullMatch
            }
        case .pattern(let p):
            return p.match(reduction)
        case .expression:
            if case .value(_) = reduction { return .fullMatch }
        case .value(let t):
            if case .value(let v) = reduction, type(of: v) == t { return .fullMatch } // Q. what about subclasses? also numbers
        case .delimiter: // note: this only matches separator OR linebreak; to match separator followed by zero or more linebreaks, use `.delimiter, .ignoreLineBreak`
            if case .token(let t) = reduction {
                switch t.form {
                case .separator(_): return .fullMatch
                case .lineBreak:    return .fullMatch
                default: ()
                }
            }
            // TO DO: fix: this should match .separator(_) or .lineBreak
        //case .lineBreaks:        return nil // TO DO: fix: this should match one or more linebreaks
        //case .ignoreLineBreaks:  return nil // TO DO: fix: this needs to avoid consuming reduction
        default:()
        }
        return .noMatch
    }

}


protocol CompositePattern: PatternProtocol {
    
    // TO DO: need `reify` method that takes remaining patterns and returns [PartialMatch], where each PartialMatch matches one branch of that pattern (actually, it probably wants to return [[Pattern],…]; each of those pattern arrays has its first element tested against current Reduction, and the one that wins is packed into a PartialMatch [if it has more patterns to test])
    
}

struct AnyPattern: CompositePattern {

    let patterns: [Pattern] // TO DO: should each pattern start with unique match? (e.g. `[EXPR,…] OR [VALUE,…]` would be ambiguous, since VALUE is also an expr) how would we enforce that?
    
    func match(_ reduction: Parser.Reduction) -> MatchResult { // TO DO: think this is wrong; composite patterns need to decompose themselves to one or more simple patterns
        return .noMatch
    }
}

struct PatternSequence: CompositePattern {
    
    let patterns: [Pattern]
    
    func match(_ reduction: Parser.Reduction) -> MatchResult {
        return .noMatch
    }
}

// challenge with pattern rewriting is that matcher needs to control rewrite; or can we do it by passing the remaining pattern to CompositePattern and have it return the new pattern[s] to match? [or it could add those patterns directly to new matcher, which is then used to match next .value on stack]

struct OptionalPattern: CompositePattern {
    
    let pattern: Pattern
    
    func match(_ reduction: Parser.Reduction) -> MatchResult {
        return .noMatch // return
    }
}

// OneOrMore(P) -> [P, ZeroOrMore(P)]

// ZeroOrMore(P) -> [Optional(P), ???]

// how to match repeating seqs? we arguably want to spawn two remaining patterns: one with the seq followed by ZeroOrMore seqs followed by closing; the other with closing (i.e. don't worry about rollback; just branch to attempt both matches [i.e. with the OptionalPattern section and without the OptionalPattern section] and discontinue the failed one[s]); this probably means rewriting patterns from user-friendly structure to state-machine-friendly (i.e. only primitives are sequenceOf and anyOf)

struct BalancedWhitespace: CompositePattern { // if pattern is sequence, this will be non-atomic (in practice, this is probably only used to match operators, e.g. when distinguishing `a -b` command from infix `a - b`/`a-b` operation, in which case it might be simpler to capture operator and perform match as atomic operation); alternative would be for parser to enforce balanced whitespace around all infix operators
    
    let pattern: Pattern
    
    func match(_ reduction: Parser.Reduction) -> MatchResult {
        return .noMatch
    }
}


//

// Q. should PartialMatch be re-cast as an enum that distinguishes between completed match, incomplete match [and failed match?]?


// note that composite matches such as OptionalMatch can spawn multiple PartialMatches, one for each branch

struct PartialMatch { // a single pattern; this should advance when a .value is pushed onto stack (assuming no unreduced tokens between it and the previous .value which holds the previous match)
    
    // note: matches are started on first operator/punctuation, backtracking to match any leading EXPRs in the pattern
    
    let operatorDefinition: OperatorDefinition
    
    let start: Int // index of first stack item matched by this pattern (Q. when is this determined? e.g. `1 * 2 + 3` will start `*` match on index 0; where does `+` match start? is 1*2 reduced first? (i.e. as soon as precedences of operators on either side of `2` can be compared))
    //private(set) var end: Int
    
    let remaining: [Pattern]
    
    var firstPattern: Pattern? { return self.remaining.first }
    var remainingPatterns: [Pattern] { return [Pattern](self.remaining.dropFirst()) }
    
    func nextMatch(with extraPatterns: [Pattern] = []) -> PartialMatch {
        return PartialMatch(operatorDefinition: self.operatorDefinition, start: self.start, remaining: extraPatterns + self.remainingPatterns)
    }
    
    
    func match(_ reduction: Parser.Reduction) -> PartialMatch? {
        print("matching", reduction, "to", self)
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
            print(self, "is already fully matched")
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
