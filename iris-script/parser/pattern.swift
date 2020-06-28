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


// worth noting that patterns could/should be able to match AS's monolithic `if TEST then EXPR ( else if TEST then EXPR )* ( else EXPR )? end if` conditional statement; while we don't use that hairy mess of a block structure ourselves (instead we decompose conditional operations into two simple, composable operators, `if…then…` and `…else…`) it may serve as a useful test case [if/when we ever get around to writing unit tests] as it contains multiple conjunctions, adjacent keywords, and is generally horrible



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


// TO DO: need to annotate expression cases with [optional?] arg label for command (might help if it can take a binding name too, as that is used in auto-generated interface documentation)


indirect enum Pattern: CustomDebugStringConvertible, ExpressibleByArrayLiteral {
    
    case keyword(Keyword)
    case expression // any value // TO DO: case expression(label: Symbol); label is arg label in constructed Command (while we could supply a descriptive binding name here for documentation purposes, since operators are defined as part of handler definition the documentation generator can already obtain binding name from that; for now, operands are treated as positional only, which is fine for the common case where there operator has no optional clauses); TO DO: what about `do…done` blocks, where the body is an expression sequence? (these use a custom reducefunc which can simply ignore any labels, but it could be a problem for tooling that reads these patterns for other purposes)
    
    // PEG-style patterns
    case optional(Pattern)
    case sequence([Pattern]) // TO DO: how to enforce non-empty array?
    case anyOf([Pattern]) // TO DO: how to enforce non-empty array? // slightly different to PEG’s `first` in that it pursues all branches with equal priority, not just the first which satisfies the condition (this is both unavoidable and probably preferable, since our pattern matching is stack-based, not recursive)
    case zeroOrMore(Pattern)
    case oneOrMore(Pattern)
    
    // TO DO: whitespace patterns?
    
    // .name and .label should only be needed if patterns are used to match command syntax; if commands are matched directly by parser code then probably get rid of these (Q. what about `name:value` bindings? note: might want to consider AS-style `property name:value` syntax as it's clear and unambiguous to parse, and avoids stray colon-pairs being misinterpreted as anything other than syntax error)
    case name  // `NAME` // TO DO: this will match even if followed by colon; is that appropriate?
    case label // `NAME COLON`
    
    case token(Token.Form) // TO DO: .token(…)? (this might be a subset of Token.Form - braces and punctuation only; powerful, e.g. able to match `HH:MM:SS`, but could also be dangerous)
    
    case testToken((Token.Form)->Bool) // currently unused; TO DO: get rid of this? (it makes it harder to reason about patterns) // TO DO: String precis? (would help when generating error messages)
    case testValue((Value)->Bool) // currently used to match dictionary keys // TO DO: ditto
    
    case delimiter // punctuation or linebreak required; e.g. prefix `to` operator should be left-delimited to avoid confusion with infix `to` conjunction; that delimiter may be start of code, linebreak, `(` (`[` and `{` would also work, although that implies `to` is being used within a record or list which is typically a semantic error as a list of closures should be defined using `as [handler]` cast; using `to` will bind them to current namespace as well) // TO DO: what about requiring a leading/trailing delimiter without consuming it? any situations where that might be helpful/necessary (e.g. indicating clear-left for the prefix `to` operator, to prevent it being confused for a command argument, e.g. `tell foo to bar` *should* longest-match the `tell…to…` op, but if the prefix `to` operator can require a LH delimiter then that will also help to disambiguate by making it impossible for `foo to bar` to be interpreted as `foo{to{bar}}`, particularly when reading incomplete/invalid code where a syntax error may prevent the `tell…to…` operator being matched)
    case lineBreak // linebreak required
    
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
        case .testToken(_):         return "TESTTOKEN"
        case .testValue(_):         return "TESTVALUE"
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
    
    enum Extent {
        case whole
        case start
        case end
    }
    
    func match(_ form: Parser.Form, extent: Extent = .whole) -> Bool { // be VERY wary of .start/.end: matching the middle operand of conjunction-based operators as anything other than .whole will spawn malformed matches
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
            case .label(_): return true
            case .quotedName(_), .unquotedName(_), .operatorName(_): return true // TO DO: ditto; `NAME COLON` should probably be reduced to `Form.label(NAME)` before matchers are applied
            default: return false
            }
        case .expression: // TO DO: is it sufficient to match something that *could* be an expression, e.g. if .endList appears to left of a postfix operator, that implies the LH operand will eventually be a List value, even if it hasn't yet been reduced to one (i.e. the operator pattern can match it; it just can't reduce to an annotated Command yet)
            switch extent {
            case .whole:
                if case .value(_) = form { return true } // TO DO: what about .error? should it always be immediately reduced to error value, or are there cases where it's preferable to put .error token on parser stack for later processing?
            case .start: // *could* token be the first token in a multi-token expression?
                switch form {
                case .value(_): return true
                case .startList, .startRecord, .startGroup: return true // fairly sure these will already be reduced
                case .unquotedName(_), .quotedName(_): return true
                //case .label(_): return false // TO DO: is this appropriate?
                case .operatorName(let definitions):
                    //print("Checking if .\(form) could be the start of an EXPR", definitions.map{ $0.hasLeadingExpression })
                    // TO DO: the problem remains operatorName(_) as we need to know if none/some/all of those defs has leading expr; also, what if mixed? (e.g. unary `-` can match as .start of expr, but we also have to consider binary `-`) // as long as we re-match the fully reduced operand, we should be okay returning true here, as long as at least one definition has trailing expr
                    return definitions.contains{ !$0.hasLeadingExpression } // _could_ this be a prefix/atom operator? (we can't ask if it is definitely a prefix/atom operator, because that requires completing that match as well, and Pattern [intentionally] has no lookahead capability; however, “could be” should be good enough for now; a greater problem is hasLeadingExpression's inability to guarantee a correct result when custom .testValue(…) patterns are used as those can only match tokens that have already been fully reduced; for now, .testValue is only used to match keyed-list keys, which are atomic .values when whole-script parsing is used [per-line parsing remains TBD, given the challenges of parsing incomplete multi-line string literals, so we aren't even going to think about that right now])

                default: ()
                }
            case .end: // *could* token be the last token in a multi-token expression?
                switch form {
                case .value(_): return true
                case .endList, .endRecord, .endGroup: return true // ditto
                case .unquotedName(_), .quotedName(_): return true
                case .operatorName(let definitions):
                    //print("Checking if .\(form) could be the end of an EXPR", definitions.map{ $0.hasTrailingExpression })
                    return definitions.contains{ !$0.hasTrailingExpression }
                default: ()
                }
            }
        case .token(let t):
            return form == t // TO DO: why does Form.==() not compare exactly? (probably because we currently only use `==` when matching punctuation tokens; it is dicey though; we probably should define a custom method for this, or else implement exact comparison [the other problem with `==` is that it's no use for matching names and other parameterized cases unless we use dummy values, which makes code very confusing/potentially misleading - best to implement those tests as Form.isName:Bool, etc])
        case .testToken(let f): // use this to match non-exprs only // TO DO: needed?
            if case .value(_) = form { return false }
            return f(form)
        case .testValue(let f): // this matches an expr that's been reduced to a Value which satisfies the provided test, e.g. `{$0 is HashableValue}`
            // TO DO: this is very problematic when expr being matched hasn't yet been reduced to .value (i.e. it's fine for single-token values, but it'll return bad result on values composed of multiple tokens when performing a partial expr match)
            if case .value(let v) = form { return f(v) }
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

    var hasLeadingExpression: Bool { // crude; assumes all branches are consistent
        switch self {
        case .expression, .testValue(_): return true
        case .optional(let p):           return p.hasLeadingExpression
        case .sequence(let p):           return p.first!.hasLeadingExpression
        case .anyOf(let p):              return p.reduce(false){ $0 || $1.hasLeadingExpression }
        case .zeroOrMore(let p):         return p.hasLeadingExpression
        case .oneOrMore(let p):          return p.hasLeadingExpression
        default:                         return false // TO DO: how should .expression, etc. patterns treat .error(…) tokens? will .errors always be [malformed] exprs?
        }
    }
    
    var hasTrailingExpression: Bool {
        switch self {
        case .expression, .testValue(_): return true
        case .optional(let p):           return p.hasTrailingExpression
        case .sequence(let p):           return p.last!.hasTrailingExpression
        case .anyOf(let p):              return p.reduce(false){ $0 || $1.hasTrailingExpression }
        case .zeroOrMore(let p):         return p.hasTrailingExpression
        case .oneOrMore(let p):          return p.hasTrailingExpression
        default:                         return false
        }
    }
    
    //var nextConjunction: Set<Symbol> {
        
    //}
    /*
    func nextConjunction(_ result: inout Set<Symbol>) {
        switch self {
        case .keyword(let keyword):
            for name in keyword.allNames { result.insert(name) }
        case .optional(let p):
            p.nextConjunction(&result)
        default: ()
        }
    }*/
}

