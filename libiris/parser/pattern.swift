//
//  pattern.swift
//  iris-script
//

//  composable Pattern enum describes how to match one or more tokens; used by PatternMatch

import Foundation

// TO DO: expr patterns need to be (optionally?) annotated with the arg labels to use in the constructed Command (at minimum, it needs to provide a list of the arg labels to use, as those will be required to disambiguate overloaded operators with the same name but different operand count and/or position[s]); currently constructed commands use `left`/`middle`/`right` as labels, which are dreadful for anything beyond basic arithmetic and comparison ops (we also need a way to supply binding names [used in native commands, and in primitive commands’ documentation] but these can be stored separately and looked up by label); Q. is it worth matcher capturing separate array of `(labelName,bindingName,tokenOffset)`, and provide methods for iterating these bindings in reducefuncs?

//  note: because EXPRs can only be fully matched once they are fully reduced to a single .value(…) token, provisional EXPR matches are performed when an EXPR’s unreduced first/last token is is at head of stack; note that if an operator has one or more interstitial EXPRs, that interstitial expression must be fully reduced before shifting the conjunction that follows it, e.g. `tell EXPR to EXPR` requires a full match of first expr in order to locate `to` but can partially-match the start of the second expr (however, it cannot reduce that 2nd expr until it is also reduced to a `.value(…)`; once that is done, the entire `tell…to…` operation can itself be reduced by that operator’s reducefunc)



extension Array where Element == Pattern {
    
    var description: String {
        return "(\(self.map{String(describing:$0)}.joined(separator: " ")))"
    }
}

extension RandomAccessCollection where Element == Pattern {
        
    func reify() -> [[Pattern]] { // given a pattern sequence, ensures the first pattern is not a composite
        if let pattern = self.first {
            return pattern.reify([Pattern](self.dropFirst()))
        } else {
            return [[]] // indicates a completed match
        }
    }
}


// PEG-like patterns for matching tokens; used in `PatternMatch` struct

// - core syntax patterns are defined in `literal patterns.swift`
// - the most commonly used patterns (prefix, infix, postfix, keyword block, etc) are predefined by convenience constructors in `OperatorRegistry` extension; any other patterns can be provided using `registry.add(PatternDefinition(…))` (once library glue syntax and implementation is finalized, much of these details will be hidden beneath that)


public indirect enum Pattern: CustomDebugStringConvertible, ExpressibleByStringLiteral, ExpressibleByArrayLiteral, SwiftLiteralConvertible {
    
    private func literalPattern(_ patterns: [Pattern]) -> String {
        return "[\(patterns.map{$0.swiftLiteralDescription}.joined(separator: ", "))]"
    }
    
    public var swiftLiteralDescription: String {
        switch self {
        case .keyword(let k):           return ".keyword(\(k.swiftLiteralDescription))"
        case .optional(let p):          return ".optional(\(p.swiftLiteralDescription))"
        case .sequence(let p):          return self.literalPattern(p)
        case .anyOf(let p):             return ".anyOf(\(self.literalPattern(p)))"
        case .zeroOrMore(let p):        return ".zeroOrMore(\(p.swiftLiteralDescription))"
        case .oneOrMore(let p):         return ".oneOrMore(\(p.swiftLiteralDescription))"
        case .name:                     return ".name"
        case .label:                    return ".label"
        case .expression:               return ".expression"
        case .expressionLabeled(let k): return ".expressionLabeled(\(k.label.debugDescription))"
        case .token(let t):             fatalError("TODO: .token(\(t))")
        case .testValue(let f):         fatalError("TODO: .testValue(\(String(describing: f)))")
        case .delimiter:                return ".delimiter"
        case .lineBreak:                return ".lineBreak"
        }
    }

    
    case keyword(Keyword)
    case expression // any value
    case expressionLabeled(Symbol) // any value // TO DO: replace with namedExpression(label: Symbol, binding: Symbol), allowing the binding name (which native pattern uses) to appear in auto-generated documentation
    
    // TO DO: case binding(Symbol, Pattern); allows e.g. arg labels to be attached to operator pattern for use in constructed Command (while we could supply a descriptive binding name here for documentation purposes, since operators are defined as part of handler definition the documentation generator can already obtain binding name from that; for now, operands are treated as positional only, which is fine for the common case where there operator has no optional clauses); TO DO: what about `do…done` blocks, where the body is an expression sequence? (these use a custom reducefunc which can simply ignore any labels, but it could be a problem for tooling that reads these patterns for other purposes)
    
    // PEG-style patterns
    case optional(Pattern)
    case sequence([Pattern]) // TO DO: how to enforce non-empty array?
    case anyOf([Pattern]) // TO DO: how to enforce non-empty array? // slightly different to PEG’s `first` in that it pursues all branches with equal priority, not just the first which satisfies the condition (this is both unavoidable and probably preferable, since our pattern matching is stack-based, not recursive)
    case zeroOrMore(Pattern)
    case oneOrMore(Pattern)
    
    // TO DO: whitespace patterns?
    
    // .name and .label should only be needed if patterns are used to match command syntax; if commands are matched directly by parser code then probably get rid of these (Q. what about `name:value` bindings? note: might want to consider AS-style `property name:value` syntax as it's clear and unambiguous to parse, and avoids stray colon-pairs being misinterpreted as anything other than syntax error)
    case name  // `NAME`; used in nestedCommandLiteral pattern
    case label // `NAME COLON`
    
    case token(Token.Form) // TO DO: .token(…)? (this might be a subset of Token.Form - braces and punctuation only; powerful, e.g. able to match `HH:MM:SS`, but could also be dangerous)
    
    case testValue((Value)->Bool) // currently used to match dictionary keys // TO DO: replace this with more limited case that takes a literal value’s type/coercion and tests for that? (it will self-document better and its behavior will be fixed so can be reasoned about)
    
    case delimiter // punctuation or linebreak required; e.g. prefix `to` operator should be left-delimited to avoid confusion with infix `to` conjunction; that delimiter may be start of code, linebreak, `(` (`[` and `{` would also work, although that implies `to` is being used within a record or list which is typically a semantic error as a list of closures should be defined using `as [handler]` cast; using `to` will bind them to current namespace as well) // TO DO: what about requiring a leading/trailing delimiter without consuming it? any situations where that might be helpful/necessary (e.g. indicating clear-left for the prefix `to` operator, to prevent it being confused for a command argument, e.g. `tell foo to bar` *should* longest-match the `tell…to…` op, but if the prefix `to` operator can require a LH delimiter then that will also help to disambiguate by making it impossible for `foo to bar` to be interpreted as `foo{to{bar}}`, particularly when reading incomplete/invalid code where a syntax error may prevent the `tell…to…` operator being matched)
    case lineBreak // linebreak required
    
    public init(stringLiteral value: String) {
        self = .keyword(Keyword(Symbol(value)))
    }
    
    public init(arrayLiteral patterns: Pattern...) {
        self = .sequence(patterns)
    }
    
    public var debugDescription: String {
        switch self {
        case .keyword(let k):           return "‘\(k.name.label)’"
        case .optional(let p):          return "\(p)?"
        case .sequence(let p):          return "(\(p.map{String(describing:$0)}.joined(separator: " ")))"
        case .anyOf(let p):             return "(\(p.map{String(describing:$0)}.joined(separator: "|")))"
        case .zeroOrMore(let p):        return "\(p)*"
        case .oneOrMore(let p):         return "\(p)+"
        case .name:                     return "NAME"
        case .label:                    return "LABEL"
        case .expression:               return "EXPR"
        case .expressionLabeled(let k): return "EXPR(\(k.label))"
        case .token(let t):             return ".\(t)"
        case .testValue(_):             return "«VALUE»"
        case .delimiter:                return "DELIM"
        case .lineBreak:                return "LF"
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
    
    // match
    
    func provisionallyMatchBeginning(_ form: Parser.Form) -> Bool {
        if self.isExpression {
            switch form {
            case .value(_): return true
            case .startList, .startRecord, .startGroup: return true // fairly sure these will already be reduced
            case .unquotedName(_), .quotedName(_): return true
            //case .label(_): return false // TO DO: is this appropriate?
            case .operatorName(let definitions):
                //print("Checking if .\(form) could be the start of an EXPR", definitions.map{ $0.hasLeftOperand })
                // TO DO: the problem remains operatorName(_) as we need to know if none/some/all of those defs has leading expr; also, what if mixed? (e.g. unary `-` can match as .start of expr, but we also have to consider binary `-`) // as long as we re-match the fully reduced operand, we should be okay returning true here, as long as at least one definition has trailing expr
                return definitions.contains{ !$0.hasLeftOperand } // _could_ this be a prefix/atom operator? (we can't ask if it is definitely a prefix/atom operator, because that requires completing that match as well, and Pattern [intentionally] has no lookahead capability; however, “could be” should be good enough for now; a greater problem is hasLeadingExpression's inability to guarantee a correct result when custom .testValue(…) patterns are used as those can only match tokens that have already been fully reduced; for now, .testValue is only used to match keyed-list keys, which are atomic .values when whole-script parsing is used [per-line parsing remains TBD, given the challenges of parsing incomplete multi-line string literals, so we aren't even going to think about that right now])
            default: () // fall-thru
            }
        }
        return self.fullyMatch(form)
    }
    
    func provisionallyMatchEnd(_ form: Parser.Form) -> Bool {
        if self.isExpression {
            switch form {
            case .value(_):                        return true
            case .endList, .endRecord, .endGroup:  return true // ditto
            case .unquotedName(_), .quotedName(_): return true
            case .operatorName(let definitions):
                //print("Checking if .\(form) could be the end of an EXPR", definitions.map{ $0.hasRightOperand })
                return definitions.contains{ !$0.hasRightOperand }
            default: () // fall-thru
            }
        }
        return self.fullyMatch(form)
    }
    
    func fullyMatch(_ form: Parser.Form) -> Bool {
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
        case .expression, .expressionLabeled(_):
            if case .value(_) = form { return true } // TO DO: what about .error? should it always be immediately reduced to error value, or are there cases where it's preferable to put .error token on parser stack for later processing?
        case .token(let t):
            return form == t // TO DO: why does Form.==() not compare exactly? (probably because we currently only use `==` when matching punctuation tokens; it is dicey though; we probably should define a custom method for this, or else implement exact comparison [the other problem with `==` is that it's no use for matching names and other parameterized cases unless we use dummy values, which makes code very confusing/potentially misleading - best to implement those tests as Form.isName:Bool, etc])
        case .testValue(let f): // this matches an expr that's been reduced to a Value which satisfies the provided test, e.g. `{$0 is HashableValue}`
            if case .value(let v) = form, f(v) { return true } // for provisional matches, only test if token is a .value; for full matches, confirm is satisfies condition func too; TO DO: need to check this doesn't cause any problems itself
        case .delimiter: // this matches separator punctuation OR a single linebreak; to match e.g. a block separator (where the comma may be followed by any number of linebreaks), use `[.delimiter, .zeroOrMore(.lineBreak)]`
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

    var isExpression: Bool { // does this pattern match an EXPR? caution: this must ONLY be called on reified patterns (i.e. currently/previously matched, NEVER on remainingPatterns[1...])
        switch self {
        case .expression, .expressionLabeled(_), .testValue(_):
            return true
        case .optional(let p), .zeroOrMore(let p), .oneOrMore(let p):
            fatalError("Cannot get isExpression for non-reified pattern: \(p)")
        case .sequence(let p), .anyOf(let p):
            fatalError("Cannot get isExpression for non-reified pattern: \(p)")
        default:
            return false
        }
    }

    var hasLeftOperand: Bool { // crude; assumes all branches are consistent
        switch self {
        case .expression, .expressionLabeled(_), .testValue(_): return true
        case .optional(let p):           return p.hasLeftOperand
        case .sequence(let p):           return p.first!.hasLeftOperand
        case .anyOf(let p):              return p.reduce(false){ $0 || $1.hasLeftOperand }
        case .zeroOrMore(let p):         return p.hasLeftOperand
        case .oneOrMore(let p):          return p.hasLeftOperand
        default:                         return false // TO DO: how should .expression, etc. patterns treat .error(…) tokens? will .errors always be [malformed] exprs?
        }
    }
    
    var hasRightOperand: Bool { // ditto
        switch self {
        case .expression, .expressionLabeled(_), .testValue(_): return true
        case .optional(let p):           return p.hasRightOperand
        case .sequence(let p):           return p.last!.hasRightOperand
        case .anyOf(let p):              return p.reduce(false){ $0 || $1.hasRightOperand }
        case .zeroOrMore(let p):         return p.hasRightOperand
        case .oneOrMore(let p):          return p.hasRightOperand
        default:                         return false
        }
    }
}

