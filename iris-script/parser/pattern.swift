//
//  pattern.swift
//  iris-script
//

//  composable Pattern enum describes how to match one or more tokens; used by PatternMatcher

import Foundation


// it may help to think of parser's stack as not so much an SR stack but as an array of in-progress reductions; starting as an array of .token(_) and finishing as an array of .value(_); this may require multiple passes (particularly when parsing per-line, e.g. while editing where the code may contain multiple [transient] syntax errors)

// A partial match succeeds in becoming a full match, or fails to match a Reduction before that

// TO DO: also need a pattern for matching no adjacent whitespace, e.g. 'YYYY-MM-DD' (Q. is this safe for negation operator to use?); also, what about regexp-based matcher? (this may be preferable to `.value(Value.Type)` for matching literal values)

// if pattern is sequence, this will be non-atomic (in practice, this is probably only used to match operators, e.g. when distinguishing `a -b` command from infix `a - b`/`a-b` operation, in which case it might be simpler to capture operator and perform match as atomic operation); alternative would be for parser to enforce balanced whitespace around all infix operators

// TO DO: should .delimiter match one of `,.?!` followed by zero or more linebreaks? (i.e. are there any situations where trailing linebreaks *aren't* wanted?)

// TO DO: assuming EXPR can match the start/end of a not-yet-reduced operand (which would greatly simplify pattern matching of incomplete code) as well as a completely reduced .value, exactly which token forms does this involve? (also be aware that handedness must be taken into account, e.g. a list to the left of the operator would appear as .endList but to its right as .startList); also consider that matchers' start indexes will be invalidated by reductions occurring mid-stack; caution: partial expr matches can only be performed when EXPR is at start/end of pattern, e.g. `tell EXPR to EXPR` requires a full match of first expr in order to locate `to` but can partially-match the start of the second expr (however, it cannot reduce the 2nd expr until that is reduced to a .value)




extension Array where Element == Pattern {
    
    var description: String {
        return "(\(self.map{String(describing:$0)}.joined(separator: " ")))"
    }
    
    func reify() -> [[Pattern]] { // given a pattern sequence, ensures the first pattern is not a composite
        if let pattern = self.first {
            return pattern.reify([Pattern](self.dropFirst()))
        } else {
            return [[]] // indicates a completed match
        }
    }
}



indirect enum Pattern: CustomDebugStringConvertible, ExpressibleByArrayLiteral {
    
    case keyword(Keyword)
    case optional(Pattern)
    case sequence([Pattern])
    case anyOf([Pattern])
    case zeroOrMore(Pattern)
    case oneOrMore(Pattern)
    
    // TO DO: whitespace patterns
    
    case name
    case label
    
    case expression // any value
    case token(Token.Form) // TO DO: .token(…)? (this might be a subset of Token.Form - braces and punctuation only; powerful, e.g. able to match `HH:MM:SS`, but could also be dangerous)
    // TO DO: .regepx(…) rather than .value(T)? that'd match the token's raw string rather than form; or maybe take (Token)->Bool
    
    case test((Token.Form)->Bool)
    
    case value(Value.Type) // match specific type of literal value, e.g. Command; e.g. pipe operator has pattern [.expression, .keyword(";"), .value(Command.self)]; note: this should ignore grouping parens when testing value type (but not blocks?) - that shouldn't be an issue as parser should discard grouping parens around single expr (elective or precedence-overriding) while parens wrapped around expr-seq will be parsed as Block
    case delimiter // punctuation or linebreak required; e.g. prefix `to` operator should be left-delimited to avoid confusion with infix `to` conjunction; that delimiter may be start of code, linebreak, `(` (`[` and `{` would also work, although that implies `to` is being used within a record or list which is typically a semantic error as a list of closures should be defined using `as [handler]` cast; using `to` will bind them to current namespace as well) // TO DO: what about requiring a leading/trailing delimiter without consuming it? any situations where that might be helpful/necessary (e.g. indicating clear-left for the prefix `to` operator, to prevent it being confused for a command argument, e.g. `tell foo to bar` *should* longest-match the `tell…to…` op, but if the prefix `to` operator can require a LH delimiter then that will also help to disambiguate by making it impossible for `foo to bar` to be interpreted as `foo{to{bar}}`, particularly when reading incomplete/invalid code where a syntax error may prevent the `tell…to…` operator being matched)
    case lineBreak
    
    init(arrayLiteral patterns: Pattern...) {
        self = .sequence(patterns)
    }
    
    var debugDescription: String {
        switch self {
        case .keyword(let k):       return "\"\(k.name.label)\""
        case .optional(let p):      return "\(p)?"
        case .sequence(let p):      return "(\(p.map{String(describing:$0)}.joined(separator: " ")))"
        case .anyOf(let p):         return "(\(p.map{String(describing:$0)}.joined(separator: "|")))"
        case .zeroOrMore(let p):    return "\(p)*"
        case .oneOrMore(let p):     return "\(p)+"
        case .name:                 return "NAME"
        case .label:                return "LABEL"
        case .expression:           return "EXPR"
        case .token(let t):         return ".\(t)"
        case .test(_):              return "TEST"
        case .value(let t):         return String(describing: t)
        case .delimiter:            return "DELIM"
        case .lineBreak:            return "LF"
        }
    }
    
    
    var keywords: [Keyword] {
        switch self {
        case .keyword(let k):       return [k]
        case .optional(let p):      return p.keywords
        case .sequence(let p):      return p.flatMap{$0.keywords}
        case .anyOf(let p):         return p.flatMap{$0.keywords}
        case .zeroOrMore(let p):    return p.keywords
        case .oneOrMore(let p):     return p.keywords
        default: return []
        }
    }
    
    
    // if self is a composite pattern, decompose it to one or more new pattern sequences, each of which starts with a non-composite pattern; ideally, a token should match one (or zero) of the returned sequences, though this is not enforced so it is possible for two or more returned patterns to match if the original composite pattern is sloppily constructed (e.g. `(ABC|ADC)` will spawn two patterns, both of which match A token, so would be better written as `A(B|D)C` to avoid redundancy; it is not illegal, however, so parser needs to allow for possibility that >1 pattern matcher may match the same token sequence and resolve that S/R conflict same as any other)
    func reify(_ remaining: [Pattern]) -> [[Pattern]] { // for each sub-array returned, fork a new match
        //print("REIFYING", self, "+", remaining)
        switch self {
        case .optional(let pattern):
            return remaining.reify() + pattern.reify(remaining) // return patternseqs without and with the optional sequence
        case .sequence(let patterns):
            guard let pattern = patterns.first else { fatalError("Empty Pattern.sequence() not allowed.") }
            return pattern.reify(patterns.dropFirst() + remaining)
        case .anyOf(let patterns):
            var result = [[Pattern]]()
            for pattern in patterns {
                result += pattern.reify(remaining)
            }
            //print("ANYOF", result)
            return result
        case .zeroOrMore(let pattern): // sequence without pattern, then with pattern and zero or more additional instances
            return remaining.reify() + pattern.reify([.zeroOrMore(pattern)] + remaining)
        case .oneOrMore(let pattern): // sequence with one instance of pattern, then zero or more additional instances
            return pattern.reify([.zeroOrMore(pattern)] + remaining)
        default:
            return [[self] + remaining]
        }
    }
    
    func match(_ form: Parser.Form) -> Bool { // needs to take Token, not Form, in order to match adjoining whitespace (this means parser stack has to capture Token)
        switch self {
        case .keyword(let k):
            if case .operatorName(let d) = form, k.matches(d.name) { return true }
        case .name:
            switch form {
            case .quotedName(_), .unquotedName(_): return true // TO DO: what about undifferentiated .letters, .symbols, etc? can we guarantee those have been reduced to name tokens by the time they reach here? (note: can't do anything with them if they do reach here)
            default: return false
            }
        case .label:
            switch form {
            case .quotedName(_), .unquotedName(_), .operatorName(_): return true // TO DO: ditto
            default: return false
            }
        case .expression: // TO DO: is it sufficient to match something that *could* be an expression, e.g. if .endList appears to left of a postfix operator, that implies the LH operand will eventually be a List value, even if it hasn't yet been reduced to one (i.e. the operator pattern can match it; it just can't reduce to an annotated Command yet)
            if case .value(_) = form { return true }
        case .token(let t):
            return form == t // TO DO: why does Form.==() not compare exactly? (probably because we currently only use `==` when matching punctuation tokens; it is dicey though; we probably should define a custom method for this, or else implement exact comparison [the other problem with `==` is that it's no use for matching names and other parameterized cases unless we use dummy values, which makes code very confusing/potentially misleading - best to implement those tests as Form.isName:Bool, etc])
        case .test(let f):
            return f(form)
        case .value(let t):
            if case .value(let v) = form, type(of: v) == t { return true } // Q. what about subclasses? also numbers // this is likely to be troublesome for any Value composed of more than one token (command/record/list/block, and possibly string)
        case .delimiter: // this matches separator punctuation OR linebreak; to match e.g. a list separator, where the comma can be followed by a linebreak, use `[.delimiter, .zeroOrMore(.lineBreak)]`
            switch form {
            case .separator(_): return true
            case .lineBreak:    return true
            default: ()
            }
        case .lineBreak:
            switch form {
            case .lineBreak: return true
            default: ()
            }
        default: fatalError("Unreified pattern: \(self)") // this should never happen as composite patterns should recursively reify themselves, the final result being an array of one or more pattern sequences where the first pattern is *always* non-composite
        }
        return false
    }

}

