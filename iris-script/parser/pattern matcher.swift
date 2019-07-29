//
//  pattern matcher.swift
//  iris-script
//

// top-down matches the tokens it expects, populating collection-type AST nodes as it goes, and failing if it encounters a token it can't handle; note: suspending a recursive-descent parser (short of running it on its own thread where it can block, or going mad with 'yield' callbacks) is problematic

// bottom-up matches the tokens it finds, shifting tokens from lexer onto stack, then reducing (popping) one or more tokens from head-down when a completed pattern is identified, pushing the resulting AST node onto the stack and continuing; mismatches leave unreduced tokens on bottom of stack, but should not prevent further reductions being made to remainder of token stream; nice thing about stack is that parsing can be suspended and resumed at any time

// Q. what about binding individual completed [block?] reductions to a Line or range of lines?



// it might be necessary to punt context-sensitive matches from tables to funcs


// bottom-up recursion? i.e. each time patternMatcher detects start of a new expr (which is just about always), it may try matching that first


// decision: 'double-postfix' is no more: any operator that takes two right-hand operands should instead take a single right-hand colon-pair

// to foo: do_this, do_that, do_the_other.

// to bar {with: x, over: y}: do_this, do_that, do_the_other.

// to baz {with: x as text, over: y as number} returning boolean: do_this, do_that, do_the_other.

// if some_test: do_stuff.
// repeat 5: do_stuff.

// if some_test: do_stuff, do_more_stuff else do_other_stuff. // Q. what is precedence on `else`? and what if user puts comma before/after it? and what if there's a comma-linked block? (i.e. what is precedence rules for comma-linked expr sequence in general?)




// TO DO: pattern matching is a bit too top-down/pull-driven; to better accommodate incremental parsing, for each token consumed it needs to return a PartialMatch along with the matched token, placing these on stack as temporary storage; thus matching is push-driven, where each new token is fed to stack head's partial match; Q. upon failure to consume a complete match, should we unwind current incomplete match to its start point and re-try matching from start+1, leaving a single unmatched token on stack? (a bottom-up parser would do this implicitly) or do we leave that incomplete match on stack and attempt to start a new match from the point it ended? (also, in the event that longest-match fails but there is a completed shorter match, we'd unwind stack to that, reduce it, then start a new match from the token after it—a process we could further streamline if we started a new match in parallel to the incomplete longest-match)


// TO DO: might operator patterns be replaced with [.operatorName, .action]?


// TO DO: partial matching might be easier if composite patterns were flattened with .failure and/or .completion markers at end of flattened sequence indicating the action to take (e.g. rollback) if the preceding patterns are [not] fully matched (this is not unlike a kiwi pipeline, where a composite rule is 'flattened' by injecting its rules into the parent pipeline for evaluation)


//Comparable,

indirect enum Pattern: Equatable, ExpressibleByArrayLiteral, CustomDebugStringConvertible {
    
    // TO DO: might be better as structs with common Pattern protocol (bearing in mind it needs to be introspectable by tooling as well)

    typealias Action = (_ stack: ASTBuilder) -> () // TO DO: this breaks Equatable
    
    
    var debugDescription: String {
        switch self { // TO DO: most of these values are placeholders; need to finish implementation
        case .form(let form): return ".form(\(form))"
        case .optional(let pattern): return ".optional(\(pattern))"
        case .zeroPlus(let pattern): return ".zeroPlus(\(pattern))"
        case .onePlus(let pattern): return ".onePlus(\(pattern))"
        case .sequence(let pattern): return ".sequence(\(pattern))"
        case .oneOf(let pattern): return ".oneOf(\(pattern))"
        case .not(let pattern): return ".not(\(pattern))"
        case .operatorName(let form): return ".operatorName(\(form))"
        case .commandName: return ".commandName"
        case .expr: return ".expr"
        case .contiguous(let before, let pattern, let after): return ".contiguous(\(before), \(pattern), \(after))"
        case .action(_): return ".action"
        }
    }
    
    static func == (lhs: Pattern, rhs: Pattern) -> Bool {
        switch (lhs, rhs) {
        case (.form(let f1), .form(let f2)):                    return f1 == f2
        case (.optional(let p1), .optional(let p2)):            return p1 == p2
        case (.zeroPlus(let p1), .zeroPlus(let p2)):            return p1 == p2
        case (.onePlus(let p1), .onePlus(let p2)):              return p1 == p2
        case (.sequence(let p1), .sequence(let p2)):            return p1 == p2
        case (.oneOf(let p1), .oneOf(let p2)):                  return p1 == p2
        case (.not(let p1), .not(let p2)):                      return p1 == p2
        case (.operatorName(let f1), .operatorName(let f2)):    return f1 == f2
        case (.commandName, .commandName):                      return true
        case (.expr, .expr):                                    return true
        case (.contiguous(let b1, let p1, let a1), .contiguous(let b2, let p2, let a2)): return b1 == b2 && p1 == p2 && a1 == a2
        default: return false
        }
    }
    
    enum Contiguous {
        case yes
        case no
        case any
        
        func match(_ hasWhitespace: Bool) -> Bool {
            switch self {
            case .yes where hasWhitespace: return false
            case .no where !hasWhitespace: return false
            default: return true
            }
        }
    }
    
    enum NameForm {
        case word
        case symbol // TO DO: rename 'symbolic'
        case any
    }
        
    typealias ArrayLiteralElement = Pattern
    typealias Reducer = () -> ()
    
    //                       // regexp equivalent, +imsx
    case form(Token.Form)    // LITERAL (but only form, not content, e.g. .letters/.operatorName)
    case optional(Pattern)   // PATT?
    case zeroPlus(Pattern)   // PATT*
    case onePlus(Pattern)    // PATT+
    case sequence([Pattern]) // (?: PATT PATT … PATT )
    case oneOf([Pattern])    // (?: PATT | PATT | … | PATT ) // TO DO: what if >1 pattern matches? (currently breaks on first match; should probably try them all and if >1 then return the one with highest precedence)
    case not(Pattern)     // [^…] (but over patterns, not chars)
    case operatorName(OperatorDefinition.Form) // .operatorName(OperatorDefinition); TO DO: allow >1 form to be specified?
    case commandName         // .letters, .symbols, .quotedName // Q. form?
    case expr // type/constraint? (debatable; see notes elsewhere)
    case contiguous(Contiguous, Pattern, Contiguous) // describes whitespace requirements before/after pattern (.yes/.no/.any)
    case action(Action) // match() should apply this
    
    // TO DO: how to express 'auto-fixable' syntax errors? (e.g. where user flubs whitespace, but intent is still clear) or do we want more general token-sequence-level rules for this? (e.g. fixing poorly spaced punctuation, missing punctuation, missing expr)
    
    init(arrayLiteral elements: Pattern...) {
        self = .sequence(elements)
    }
    
    init(_ form: Token.Form) {
        self = .form(form)
    }
    
    var precedence: Int { // where >1 pattern matches, need to determine which pattern 'wins'
        switch self { // TO DO: most of these values are placeholders; need to finish implementation
        case .form(_): return 10
        case .optional(_): return 0
        case .zeroPlus(_): return 0
        case .onePlus(_): return 0
        case .sequence(_): return 0
        case .oneOf(_): return 0
        case .not(_): return 0
        case .operatorName(_): return 30 // Q. should operator form/precedence have any influence here? (would be problematic, as there's no easy way to pass an OperatorRegistry to Pattern, particularly in `==`/`<` comparisons)
        case .commandName: return 20
        case .expr: return 0
        case .contiguous(_, let pattern, _): return pattern.precedence - 1
        case .action(_): return -1
        }
    }
    
    // TO DO: FIX: == operator is comparing enum cases, but < is comparing case precedences
    
    static func < (lhs: Pattern, rhs: Pattern) -> Bool {
        return lhs.precedence < rhs.precedence
    }
    
    enum MatchStatus {
        case completed // indicates a complete sequence match (e.g. `comma expr`); as-per longest-match rule, if matchable patterns remain then a longer match may still be made, but if that fails then the stack is only rolled back to last .complete // TO DO: is it worth distinguishing 'completedSubMatch' from 'completedFullMatch'?
        case partial
        case failed
        case new
    }
    
    typealias MatchResult = (result: MatchStatus, shift: Bool, remaining: [Pattern])
    
    func match(token: Token, precedence: Int) -> MatchResult { // TO DO: given match may be called recursively, should it carry current match's rollback depth with it as argument; if so, replace `shift:Bool` with +/- Int where +1 shifts [current] token from stream to stack and -N discards N tokens from stack
        var matchStatus = MatchStatus.failed // was token matched?
        var shouldShift = false // should the token be shifted to stack?
        var remainingPatterns = [Pattern]()
        let r: [Pattern]
        switch self {
        case .form(let form): // typically used to match punctuation, which requires comparing form only; non-punctuation matches generally test for a .commandName/.operatorName, or completed value (.expr)
            // on matching token,
            if form == token.form {
                matchStatus = .completed
                shouldShift = true
            }
        case .optional(let pattern):
            // an .optional match shifts all tokens (if pattern matches) or shifts none
            // if it fails to match, stack should rollback and restart matching with next pattern in parent seq
            // a failure within sequence means discard shifted tokens and restart matching with next pattern in parent seq
            print(">>> matching \(token) to .optional \(pattern) …")
            (matchStatus, shouldShift, r) = pattern.match(token: token, precedence: precedence)
            if matchStatus == .new { // TO DO: move this test to return statement below? i.e. on successful completion, the new match returns a reduced .value which can now be re-matched against the same pattern
                remainingPatterns = [self]
            } else if matchStatus != .failed {
                if !r.isEmpty {
                    // TO DO: don't box r as a sequence if it's already [.sequence] as that's redundant - just unwrap it instead
                    remainingPatterns = [.optional(.sequence(r))]
                    matchStatus = .partial
                }
            }
            print(">>> …matched", (matchStatus, shouldShift, remainingPatterns))
            
        case .zeroPlus(let pattern):
            
            // .zeroPlus on successful match of pattern returns (.complete, true, self)
            (matchStatus, shouldShift, r) = pattern.match(token: token, precedence: precedence)
            switch matchStatus {
            case .completed: remainingPatterns = [self]
            case .partial:  remainingPatterns = r // TO DO: we need to make sure that a failure on remaining patterns triggers rollback
            case .failed:   matchStatus = .completed
            case .new:      remainingPatterns = [self]
            }
            
        case .onePlus(let pattern):
            // .zeroPlus on successful match of pattern returns (.complete, true, self)
            (matchStatus, shouldShift, r) = pattern.match(token: token, precedence: precedence)
            switch matchStatus {
            case .completed: remainingPatterns = [.zeroPlus(pattern)]
            case .partial:  remainingPatterns = r
            case .failed:   () // failed to match pattern once
            case .new:      remainingPatterns = [self]
            }
            
        case .sequence(let patterns): // this should probably only be used for optional/repeating sub-sequences that are not themselves exprs (or are parsing context-sensitive code, e.g. handler interface in `to`/`when` operator) // see also PatternRegistry.add, which flattens a top-level .sequence into a chain of PartialMatches
            assert(!patterns.isEmpty)
            (matchStatus, shouldShift, r) = patterns.first!.match(token: token, precedence: precedence)
            remainingPatterns += r + patterns.dropFirst(1)
            if matchStatus == .completed && !remainingPatterns.isEmpty { matchStatus = .partial }
            
        case .oneOf(let patterns): // TO DO: this is a bugger should given patterns be different lengths (should it try to consume the longest, or just take the shortest? or should we just reject patterns that are >1 token); most common use would be in groupings, e.g. `[.form(.startList), .oneOf([.endList, [.expr, .zeroPlus([.comma, .expr]), .endList]]), .action]`
            // this is, essentially, the same algorithm used by startMatch: solution is to do breadth-first, returning remaining patterns
            var remaining = [[Pattern]]()
            for pattern in patterns {
                let r: [Pattern]
                (matchStatus, shouldShift, r) = pattern.match(token: token, precedence: precedence)
                if !r.isEmpty { remaining.append(r) }
                if matchStatus == .completed { break } // TO DO: this halts on shortest-match
                if matchStatus == .new { fatalError("not yet implemented") }
            }
            
        case .not(let pattern):
            print(".not", pattern)
            fatalError("not yet implemented")
            
        case .operatorName:
            if token.isOperatorName { // TO DO: this also needs to look up operator's name in operator registry to determine its fixity (or fixities, if overloaded), which is needed to determine which pattern[s] to allow (note: we might want to push this decision over to stack); if we do it here, we probably want to parameterize Pattern.operatorName with OperatorDefinition.Form to allow pattern to fail if operator isn't the right form
                matchStatus = .completed
                shouldShift = true
            }
            
        case .commandName:
            if token.isCommandName {
                matchStatus = .completed
                shouldShift = true
            }
            
        case .expr: // important: this will only match the token if it's already a complete expression (i.e. it's a .value); if not, it triggers a new match to reduce it to one, after which the same pattern can be successfully re-applied (while this is more work than simply recursing, it avoids taking control away from the external token-pumping loop)
            print("matching .expr")
            if case .value(_) = token.form { // already reduced to an expression
                matchStatus = .completed
                shouldShift = true
            } else { // signal to registry to start a new expression match; once that's reduced a value, resume
                matchStatus = .new
                shouldShift = false
                remainingPatterns = [.expr] // bit snaky, but we need to kick the problem back to pattern registry // TO DO: this is insufficient; all that happens is it gets boxed up
            }
            
        case .contiguous(let before, let pattern, let after):
            if before.match(token.hasLeadingWhitespace) {
                (matchStatus, shouldShift, r) = pattern.match(token: token, precedence: precedence)
                switch matchStatus {
                case .completed where after.match(token.hasTrailingWhitespace): () // single-token match
                case .partial:
                    assert(!r.isEmpty)
                    if after == .any {
                        remainingPatterns += r
                    } else {
                        let lastPattern = r.last!
                        remainingPatterns += r.dropLast(1)
                        remainingPatterns.append(.contiguous(.any, lastPattern, after))
                    }
                    
                default: () // failed/new
                }
            
            }
        case .action(_):
            fatalError(".action should not reach here")
        }
        return (matchStatus, shouldShift, remainingPatterns)
    }
    
    
    
    
}


class PatternRegistry {
    
    typealias MatchResult = (shifted: Bool, next: PartialMatch?)
    
    
    struct PartialMatch: CustomDebugStringConvertible {
        
        var debugDescription: String { return "<PartialMatch for \(self.patterns.map{$0.name})>" }
        
        // TO DO: we need a PartialMatch method that returns a list of single-token patterns against which next token will be matched (e.g. for a3c, bad syntax fixers [if next match is expr/punctuation; Q. how to determine shortest fix?])
        
        let patterns: [(name: String, pattern: [Pattern])]
        let registry: PatternRegistry
        let stack: ASTBuilder
        
        
        func continueMatch(_ token: Token, precedence: Int = 0) -> MatchResult {
            if case .annotation(_) = token.form {
                self.stack.annotate(token)
                return (true, nil)
            }
            // try all matches at this step; if >1 is matched, keep going until a single longest-match remains (note: this may involve rollback where the last pattern fails to match last token[s])
            
            var remainingPatterns = [(String,[Pattern])]()
            var shift: Bool?
            
            for (name, pattern) in self.patterns {
                
                // TO DO: don't re-match already tested patterns; see below
                
                
                let (pattern, remaining) = (pattern.first!, pattern.dropFirst(1))
                if case .action(let action) = pattern {
                    action(self.stack) // TO DO: we really want to put these aside along with depth, so that when last match ends and we search backwards for longest completion, we know to call [Q. what about mid-pattern actions? e.g. LIST could perform per-item reduction which appends item directly to list builder]
                } else if case .expr = pattern, case .value(_) = token.form {
                    remainingPatterns.append((name, Array<Pattern>(remaining)))
                } else {
                    let (m, s, r) = pattern.match(token: token, precedence: precedence)
                    print("#", m, "matching", token, "to", name, "pattern", pattern, "shifting", s)

                    if m == .new { // start a new expression match (this is not invoked if token is already a .value)
                        assert(!s)
                        print("continueMatch is starting a new match…")
                        let (shifted, r2) = registry.startMatch(token, precedence: precedence, stack: stack)
                        print("…continueMatch started a new match, r2 =", (r2 ?? nil) as Any)
                        // TO DO: need to append r to r2 so that once r2 is exhausted, r resumes (it may be best to chain via a `var previousMatch: PartialMatch?`, rather than trying to merge the two sets of patterns; it should make its behavior easier to reason about if nothing else)
                        
                        // TO DO: another challenge is how to get the newly reduced .value (which is [presumably] now on top of stack, so requires an 'unshift') so we can match it against r2+r (plus we need to do this within an existing match cycle, as we don't have any control over the token stream)
                        
                        if !r.isEmpty {
                            
                        }
                        
                        // big problem: we need to get r2's remaining matches and prefix them to r, then put that into remainingPatterns; in theory we could do this using .oneOf, but that doesn't do multi-token matches well, so gets nuts really quickly (plus `name` applies to the outer match, not the inner)
                        
                        // we're also going to have problems with left-recursive patterns (basically, any pattern that represents a complete expression while itself starting with .expr, e.g. infix/postfix operators)
                        
                        return (shifted, r2) // WRONG!!
                    } else if m != .failed {
                        if shift == nil {
                            shift = s
                        } else if shift != s {
                            // if >1 pattern matches, they must all return the same value for shouldShift (in theory, we could put non-shifted matches into a separate array within PartialMatch along with a queue for the unshifted tokens, and let partial match resynchronise these 'trailing' token streams in its own time, but for now we just want to get something working; it's also unclear how often such 'desynchronizations' will occur in real-world use, so not worth the extra effort unless/until it becomes an issue)
                            fatalError("shift/no-shift conflict between \(name) and \(remainingPatterns.map{$0.0}) patterns")
                        }
                        remainingPatterns.append((name, r + remaining ))
                    }
                }
            }
            return (shift ?? false, remainingPatterns.isEmpty ? nil : PartialMatch(patterns: remainingPatterns, registry: self.registry, stack: self.stack))
        }
    }
    
    
    
    private let operatorRegistry: OperatorRegistry? // use `if let opClass = self.operatorRegistry?.get(opName)`
    
    init(operatorRegistry: OperatorRegistry? = nil) {
        self.operatorRegistry = operatorRegistry
    }
    
    private var patterns = [PatternDefinition]()
    
    func add(_ pattern: PatternDefinition) {
        self.patterns.append(pattern)
    }
    
    // TO DO: should startMatch/continueMatch take the token's stream rather than just the token? this'd allow them to put the stream on the stack during shifting; if reduction fails and the stack is rolled back, the token stream from the point at which the failed match began can be returned (this object includes the token's line and position, which can be used e.g. to highlight the problem code)
    
    func startMatch(_ token: Token, precedence: Int = 0, stack: ASTBuilder) -> (Bool, PartialMatch?) {
        if case .annotation(_) = token.form {
            stack.annotate(token)
            return (true, nil)
        }
        // try all matches at this step; if >1 is matched, keep going until a single longest-match remains (note: this may involve rollback where the last pattern fails to match last token[s]) // TO DO: don't re-match already tested patterns, e.g. infix and postfix operator patterns both start by trying to match .expr; this only needs done once, and only if another pattern hasn't already done so (list/record literal or already-reduced value); might be an idea to start by sorting self.patterns by specificity so that narrowest definitions come first: if the narrowest definition matches then the broader definitions must logically also match, obviating need for explicit tests
        
        // Q. how well will this design cope with left-recursion (e.g. `A = A b c`)?
        
        var remainingPatterns = [(String,[Pattern])]()
        var shift: Bool?
        for pattern in self.patterns {
            let (name, pattern) = (pattern.name, pattern.pattern)
            if case .action(let action) = pattern {
                action(stack) // TO DO: we really want to put these aside along with depth, so that when last match ends and we search backwards for longest completion, we know to call [Q. what about mid-pattern actions? e.g. LIST could perform per-item reduction which appends item directly to list builder]
            // TO DO: what about special-casing `if case .expr = pattern`? (left recursion is a PITA)
            } else {
                let (m, s, r) = pattern.match(token: token, precedence: precedence)
                print("#", m, "matching", token, "to", name, "shifting", s)
                if m == .partial && !s && r.count == 1, case .expr = r[0] { // start new expression match
                    print(">> start new expression match")
                    
                } else if m != .failed {
                    if shift == nil {
                        shift = s
                    } else if shift != s {
                        fatalError("shift/no-shift conflict between \(name) and \(remainingPatterns.map{$0.0}) patterns")
                    }
                    remainingPatterns.append((name,r))
                }
            }
        }
        
        // TO DO: how to reconcile `shouldShift`s when >1 pattern is matched? for now, just check they're all true/all false
        
        //print("remaining:", remainingPatterns)
        return (shift ?? false, remainingPatterns.isEmpty ? nil : PartialMatch(patterns: remainingPatterns, registry: self, stack: stack))
    }
    
}




