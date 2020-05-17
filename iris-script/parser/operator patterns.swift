//
//  operator patterns.swift
//  iris-script
//

import Foundation


// it may help to think of parser's stack as not so much an SR stack but as an array of in-progress reductions; starting as an array of .token(_) and finishing as an array of .value(_); this may require multiple passes (particularly when parsing per-line, e.g. while editing where the code may contain multiple [transient] syntax errors)

// A partial match succeeds in becoming a full match, or fails to match a Reduction before that


// TO DO: implement pattern sequences as linked lists? this might be more efficient as operations on patterns are push/pop (technically push is more splice: combine remaining patterns of this pattern's branch with remaining patterns in parent sequence and store that as a new PartialMatch, plus linked lists will refcount each node whereas an array of structs will refcount the array's owners only)


// TO DO: should .delimiter match one of `,.?!` followed by zero or more linebreaks? (i.e. are there any situations where trailing linebreaks *aren't* wanted?)

enum MatchResult {
    case fullMatch
    case partialMatch([Pattern]) // this Reduction was matched, but the given sequence of Reductions need to be matched as well
    case noMatch // match failed, so stop matching this pattern at this point
    case noConsume // match current Reduction to next pattern; e.g. when .ignoreLineBreaks is used, return .partialMatch([.ignoreLineBreaks]) if Reduction is .token(.lineBreak) or .noConsume if it's anything else
}


protocol PatternProtocol {
    
    // TO DO: problem with passing Parser to match() is that it tempts consuming multiple tokens, which disrupts other partial matches

    // on successful match of the given reduction (token, value, etc), return [] if it's a complete match or any patterns to match against subsequent tokens; if no match, return nil
    func match(_ reduction: Parser.Reduction) -> MatchResult
}



// TO DO: assuming EXPR can match the start/end of a not-yet-reduced operand (which would greatly simplify pattern matching of incomplete code) as well as a completely reduced .value, exactly which token forms does this involve? (also be aware that handedness must be taken into account, e.g. a list to the left of the operator would appear as .endList but to its right as .startList); also consider that matchers' start indexes will be invalidated by reductions occurring mid-stack; caution: partial expr matches can only be performed when EXPR is at start/end of pattern, e.g. `tell EXPR to EXPR` requires a full match of first expr in order to locate `to` but can partially-match the start of the second expr (however, it cannot reduce the 2nd expr until that is reduced to a .value)


func reifySequence(_ patterns: [Pattern]) -> [[Pattern]] { // given a pattern sequence, ensures the first pattern is not a composite
    if let pattern = patterns.first {
        return pattern.reify([Pattern](patterns.dropFirst()))
    } else {
        return []
    }

}


indirect enum Pattern: PatternProtocol, CustomDebugStringConvertible, ExpressibleByArrayLiteral {
    case keyword(Keyword)
    case optional(Pattern)
    case sequence([Pattern])
    case anyOf([Pattern])
    case zeroOrMore(Pattern)
    case oneOrMore(Pattern)
    
    // TO DO: whitespace patterns
    
   // case pattern(CompositePattern)
    case expression // any value
    case token(Token.Form) // TO DO: .token(…)? (this might be a subset of Token.Form - braces and punctuation only; powerful, e.g. able to match `HH:MM:SS`, but could also be dangerous)
    // TO DO: .regepx(…) rather than .value(T)? that'd match the token's raw string rather than form
    case value(Value.Type) // match specific type of literal value, e.g. Command; e.g. pipe operator has pattern [.expression, .keyword(";"), .value(Command.self)]; note: this should ignore grouping parens when testing value type (but not blocks?) - that shouldn't be an issue as parser should discard grouping parens around single expr (elective or precedence-overriding) while parens wrapped around expr-seq will be parsed as Block
    case delimiter // punctuation or linebreak required; e.g. prefix `to` operator should be left-delimited to avoid confusion with infix `to` conjunction; that delimiter may be start of code, linebreak, `(` (`[` and `{` would also work, although that implies `to` is being used within a record or list which is typically a semantic error as a list of closures should be defined using `as [handler]` cast; using `to` will bind them to current namespace as well) // TO DO: what about requiring a leading/trailing delimiter without consuming it? any situations where that might be helpful/necessary (e.g. indicating clear-left for the prefix `to` operator, to prevent it being confused for a command argument, e.g. `tell foo to bar` *should* longest-match the `tell…to…` op, but if the prefix `to` operator can require a LH delimiter then that will also help to disambiguate by making it impossible for `foo to bar` to be interpreted as `foo{to{bar}}`, particularly when reading incomplete/invalid code where a syntax error may prevent the `tell…to…` operator being matched)
    case lineBreaks // one or more // TO DO: needed? (i.e. are there any cases where punctuation isn't sufficient to delimit) // TO DO: singular or plural (i.e. are there any use-cases where we need to disallow *multiple* linebreaks?)
    case ignoreLineBreaks // skip over any contiguous linebreaks (normally linebreaks within an operation are a syntax error; exceptions are e.g. in `do … done` block)
    
   // init(_ pattern: CompositePattern) {
  //      self = .pattern(pattern)
  //  }
    
    init(arrayLiteral patterns: Pattern...) {
        self = .sequence(patterns)
    }
    
    var debugDescription: String {
        switch self {
        case .keyword(let k):   return "\"\(k.name.label)\""
//        case .pattern(let p):   return String(describing: p)
            
        case .optional(let p):      return "optional(\(p))"
        case .sequence(let p):      return "sequence(\(p))"
        case .anyOf(let p):         return "anyOf(\(p))"
        case .zeroOrMore(let p):    return "zeroOrMore(\(p))"
        case .oneOrMore(let p):    return "oneOrMore(\(p))"

            
        case .expression:       return "EXPR"
        case .token(let t):     return "\(t)"
        case .value(let t):     return String(describing: t)
        case .delimiter:        return "DELIM"
        case .lineBreaks:       return "LF"
        case .ignoreLineBreaks: return "-LF"
      //  default: return "???"
        }
    }
    
    
    // if self is a composite pattern, decompose it to one or more new pattern sequences, each of which starts with a non-composite pattern
    func reify(_ remaining: [Pattern]) -> [[Pattern]] { // for each sub-array returned, fork a new match
        //print("REIFYING", self, "+", remaining)
        switch self {
        case .optional(let pattern):
            return reifySequence(remaining) + pattern.reify(remaining)
        case .sequence(let patterns):
            guard let pattern = patterns.first else { fatalError("Empty Pattern.sequence() not allowed.") }
            return pattern.reify(patterns.dropFirst() + remaining)
        case .anyOf(let patterns):
            var result = [[Pattern]]()
            for pattern in patterns {
                result += pattern.reify(remaining)
            }
            return result
        case .zeroOrMore(let pattern):
            return reifySequence(remaining) + pattern.reify([.zeroOrMore(pattern)] + remaining)
        case .oneOrMore(let pattern):
            return pattern.reify(remaining) + pattern.reify([.zeroOrMore(pattern)] + remaining)
        default:
            return [[self] + remaining]
        }
    }
    
    func match(_ form: Parser.Reduction) -> MatchResult {
        switch self {
        case .keyword(let k):
            if case .operatorName(let d) = form, k.matches(d.name) {
                return .fullMatch
            }
            
            
//        case .pattern(let p):
//            fatalError("Found unreified pattern: \(p)")
            // TO DO: need to decide how/where composite patterns decompose themselves; the goal is to transform [CompositePattern, REST] into [[SimplePattern,…,REST],…], preferably shortest first
            
        case .expression: // TO DO: is it sufficient to match something that *could* be an expression, e.g. if .endList appears to left of a postfix operator, that implies the LH operand will eventually be a List value, even if it hasn't yet been reduced to one (i.e. the operator pattern can match it; it just can't reduce to an annotated Command yet)
            if case .value(_) = form { return .fullMatch }
        case .token(let t):
            return form == t ? .fullMatch : .noMatch // TO DO: why does Form.==() not compare exactly?
        case .value(let t):
            if case .value(let v) = form, type(of: v) == t { return .fullMatch } // Q. what about subclasses? also numbers // this is likely to be troublesome for any Value composed of more than one token (command/record/list/block, and possibly string)
        case .delimiter: // note: this only matches separator OR linebreak; to match separator followed by zero or more linebreaks, use `.delimiter, .ignoreLineBreak`
            switch form {
            case .separator(_): return .fullMatch
            case .lineBreak:    return .fullMatch
            default: ()
            }
            // TO DO: fix: this should match .separator(_) or .lineBreak
        case .lineBreaks:        return .noMatch // TO DO: fix: this should match one or more linebreaks (might be better to use .oneOrMore)
        case .ignoreLineBreaks:  return .noMatch // TO DO: fix: this needs to avoid consuming form if it's not .lineBreak
        default: fatalError("Unreified pattern: \(self)") // this should never happen as composite patterns should recursively reify themselves, the final result being an array of one or more pattern sequences where the first pattern is *always* non-composite
        }
        return .noMatch
    }

}


// TO DO: also need a pattern for matching no adjacent whitespace, e.g. 'YYYY-MM-DD' (Q. is this safe for negation operator to use?); also, what about regexp-based matcher? (this may be preferable to `.value(Value.Type)` for matching literal values)
 
 // if pattern is sequence, this will be non-atomic (in practice, this is probably only used to match operators, e.g. when distinguishing `a -b` command from infix `a - b`/`a-b` operation, in which case it might be simpler to capture operator and perform match as atomic operation); alternative would be for parser to enforce balanced whitespace around all infix operators

