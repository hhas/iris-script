//
//  parser extensions.swift
//  iris-script
//

import Foundation



typealias ReductionOrder = OperatorDefinition.Associativity

func reductionOrderFor(_ leftMatch: PatternMatcher, _ rightMatch: PatternMatcher) -> ReductionOrder {
    let left = leftMatch.definition, right = rightMatch.definition
    if !left.hasTrailingExpression { // TO DO: FIX: need to determine this by examing the *matched* pattern seq (currently previously matched patterns are not carried forward to next matchers)
        return .left
    } else if !right.hasLeadingExpression { // TO DO: ditto
        return .right
    } else if left.precedence != right.precedence {
        return left.precedence > right.precedence ? .left : .right
    } else { // both operators are the same precedence, e.g. `2 ^ 3 ^ 4`, so use associativity // TO DO: what if they're different operators with same precedence? // TO DO: what about operators that shouldn't compose (e.g. `A thru B`); report as syntax error or leave Command to throw coercion error at eval time?
        return left.associate == .left ? .left : .right
    }
}




extension OperatorDefinitions {
    
    // TO DO: this should return a 4-case enum: .yes, .no, .maybe (has both prefix and infix forms, requiring further analysis to decide), .error (operators have precedences both higher AND lower than command’s); it might also be better to analyze the *matched* patterns on the stack as that may help narrow the decision (caveat it might create more confusion than it solves: sometimes dumb—i.e. easily learned—rules are the best)
    
    func terminatesCommand() -> Bool? { // returns true if operator is infix/postfix with precedence[s] lower than command’s (i.e. a lower-precedence), false if operator has no infix/postfix forms or precedence is higher than command’s, or nil if overloaded operators’ precedence is both less AND greater than command’s (i.e. user MUST add explicit parentheses to disambiguate as parser cannot decide for itself)
        let (minPrecedence, maxPrecedence) = self.definitions.filter{ $0.hasLeadingExpression }.reduce(
            (Precedence.max, Precedence.min), { (Swift.min($0.0, $1.precedence), Swift.max($0.1, $1.precedence)) })
        if maxPrecedence > commandPrecedence && minPrecedence < commandPrecedence {
            return nil // overloaded infix/postfix operator has precedences higher AND lower than command
            // TO DO: this should be encapsulated as a syntax error allowing parsing to continue (Q. what should this error encompass? the current argument only or the current command, or even the whole expression? in any case it should indicate to user that they must explicitly parenthesize either the argument or the entire command to disambiguate the code and allow it to parse as intended)
            //fatalError("Cannot resolve precedence between command \(commandName) and overloaded operator \(d.name) as the operators’ precedences are higher AND lower than command’s.")
        }
        return maxPrecedence < commandPrecedence
    }
    
    var hasPrefixForms: Bool {
        return self.first{ $0.hasLeadingExpression } != nil
    }
    
    var hasInfixForms: Bool {
        return self.first{ $0.hasLeadingExpression } == nil
    }
}




extension Array where Element == LongestMatch {
    
    func show() { // DEBUG
        print("  ->")
        for m in self { print("    \(m.start)-\(m.stop) [\(m.tokens.map{".\($0.reduction)"}.joined(separator: ", "))]") }
        //print()
    }
}


typealias LongestMatch = (start: Int, stop: Int, match: PatternMatcher, tokens: [Parser.StackItem]) // important: stop index is INclusive (start...stop), i.e. to check for overlapping operations: left.stop == right.start (assumes the shared operand is already reduced to a single .value token)

enum CommandTokenForm { // tokens within an expression that denote commands
    case name(Symbol)
    case label(Symbol)
    case terminatingOperator // operators *may* right-terminate a command // TO DO: we should probably filter these as they're read so that only operators that WILL terminate a command are included (in fact, we should be able to calculate commands' spans immediately); that then gives us command ranges, from which we should be able to identify nested commands and reduce those immediately, then pass the resulting sub-stack array straight to reductionForOperator
}

typealias CommandToken = (index: Int, form: CommandTokenForm)



extension Array where Element == Parser.StackItem {
    
    
    func show(_ startIndex: Int = 0, _ stopIndex: Int? = nil) { // startIndex..<stopIndex // DEBUG: list stack tokens + their associated partial/complete matchers
        print("Stack[\(startIndex)..<\(stopIndex ?? self.count)]:")
        print(self[startIndex..<(stopIndex ?? self.count)].map{ "\t.\($0.reduction)\($0.matches.map{"\n\t\t\t\t\($0)"}.joined(separator: ""))" }.joined(separator: "\n"))
    }
    
    // starting from end of a range of tokens, search backwards to find a left-hand expression delimiter
    // this search also returns a list of significant tokens needed to parse commands
    
    func findStartIndex(from startIndex: Int, to stopIndex: Int) -> (Int, [CommandToken]) {
        // TO DO: what if labels are found but no command names? presumably that's a syntax error (Q. what if we use AS-style `property NAME : EXPR`? presumably a pattern matcher can read that; however, .label will remain on stack; one solution *might* be to define `property` as a command handler, in which case `NAME:` is an arbitrary label in LP syntax [this'd also allow multiple NAME:EXPR definitions in LP syntax]; only difference to standard commands is that this requires the argument record to be passed to handler as a single parameter; currently primitive/native handlers don't support this form of argument mapping but it's something we need to accept arbitrary arguments, c.f. Python's `name(*args,**kwargs)`, which is useful e.g. in implementing dynamic bridging wrappers around foreign APIs)
        var commandTokens = [CommandToken]() // tokens that denote/delimit LP commands
        for index in stride(from: stopIndex - 1, to: startIndex - 1, by: -1) {
            let form = self[index].reduction
            switch form { // can't use Token.isLeftDelimited as that's not yet implemented
            case .semicolon, .colon, .separator(_), .startList, .startRecord, .startGroup, .lineBreak:
                // note that .colon here typically denotes kv-list item; TO DO: what about records? when we reduce record values, we need to stop on the colon even though it's already been partly reduced to a .label
                return (index + 1, commandTokens.reversed()) // TO DO: what if this returns on the first token checked? the index returned will be stopIndex, which is out of range
            case .unquotedName(let n), .quotedName(let n):
                commandTokens.append((index, .name(n)))
            case .label(let n):
                commandTokens.append((index, .label(n)))
            case .operatorName(let d): // we need this to determine where commands are right-delimited by infix/postfix operators of lower precedence
                // when parsing commands, we only need consider operators that appear after a command name
                // we only really need to consider operators that appear after a command name; however, we're scanning right-to-left here
                guard let mayEndCommand = d.terminatesCommand() else {
                    fatalError("Cannot resolve precedence between commandand overloaded operator \(d.name) as the operators’ precedences are higher AND lower than command’s.")
                }
                if mayEndCommand {
                    // TO DO: this only applies if preceding token in stack is a name (e.g. `foo - 1`)
                    if d.hasPrefixForms {
                        if index > startIndex {
                            switch self[index - 1].reduction {
                            case .quotedName(_), .unquotedName(_): ()
                            default:
                                print("TODO: \(d.name) operator has both prefix and infix forms, so needs further analysis to determine if it's the start of a direct argument or end of command")
                        // TO DO: need to append .maybeTerminatingOperator(OperatorDefinitions); readLowPunctuationCommand can then do whitespace analysis to make judgement call (caveat: WS analysis only really works for symbolic prefix+infix operators; word-based prefix+infix operators will require WS on both sides [or explicit parenthesization of the operand, e.g. `cmd op(1)`, which is rather pointless as it's easier and a lot less confusing just to write `cmd {op 1}` in the first place])
                            }
                        }
                    }
                    commandTokens.append((index, .terminatingOperator))
                }
            default: ()
            }
        }
        return (startIndex, commandTokens.reversed())
    }
    
    // find full operation matchers in the given range; reductionForOperatorExpression() uses the result in determining the order in which to reduce nested operators according to the operators’ arity, precedence, and/or associativity
    
    func findLongestMatches(from startIndex: Int, to stopIndex: Int) -> [LongestMatch] { // startIndex..<stopIndex // given a range of shifted stack frames denoting a delimited simple/compound expression, returns the longest full matches grouped with their associated tokens // TO DO: decide if end index is inclusive or exclusive and standardize across all code
        assert(startIndex >= 0)
        assert(stopIndex <= self.count) // non-inclusive
        // important: this should only be used to identify longest matches in a contiguous sequence; it cannot be used to identify matches that span over other matches (at least, not until all those nested matches have already been reduced; e.g. given `if EXPR1 then EXPR2`, findLongestMatches should be called for EXPR1 only, then for EXPR2 only, and only then for `if VALUE1 then VALUE2` once its operands are all reduced to .values)
        var longestMatches = [Int: LongestMatch]() // [groupID:(start...stop,match,tokens)] // note that first/last tokens in sub-array may represent incomplete matches, e.g. given `1 * - 2`, the `*` match's tokens will be [`1`,`*`,`-`]; it's up to the reducer to reduce [`-`,`2`] to value `-2` and substitute that in place of the `*` match's `-` token
        //print("findLongestMatches:")
        for rightExpressionIndex in (startIndex..<stopIndex).reversed() { // TO DO: confirm right-to-left vs left-to-right
            let form = self[rightExpressionIndex]
            for m in form.matches {
                if m.isAFullMatch {
                    //print("full",m)
                    // TO DO: make sure this respects optional conjunctions (e.g. `EXPR is_before EXPR ( as EXPR )?`; while `EXPR is_before EXPR` is a full match, if it's followed by `as` conjunction then the longer match should be used)
                    if let pm = longestMatches[m.groupID] {
                        if pm.match.count < m.count {
                            let start = m.startIndex(from: rightExpressionIndex)
                            longestMatches[m.groupID] = (start, rightExpressionIndex, m, [Parser.StackItem](self[start...rightExpressionIndex])) // stop index is inclusive
                            //print("discard", m)
                        }
                    } else {
                        let start = m.startIndex(from: rightExpressionIndex)
                        longestMatches[m.groupID] = (start, rightExpressionIndex, m, [Parser.StackItem](self[start...rightExpressionIndex]))
                    }
                } else {
                    //print("part",m)
                }
            }
        }
        return longestMatches.values.sorted{ $0.start < $1.start }
    }
    
    
    
    // TO DO: make sure all reductions are applied using these methods, and make absolutely sure that the replace() method updates all in-progress matchers correctly

    func reductionFor(completedMatch: PatternMatcher) -> Token.Form { // reduce a single fully matched expression at head of stack to a single value // TO DO: what to call this method? (it doesn't put the result back onto parser stack or update stack's matchers, so is not a full reduction step in the Shift-Reduce sense)
        //        print("REDUCING COMPLETED MATCH \(completedMatch) TO:")
        let endIndex = self.count // end index is non-inclusive
        let startIndex = endIndex - completedMatch.count
        let result: Token.Form
        do {
            result = .value(try completedMatch.definition.reduce(self, completedMatch.definition, startIndex, endIndex))
        } catch {
            result = .error(error as? NativeError ?? InternalError(error))
        }
        //        print("…TO: .\(result)")
        //        print("…reduced \(completedMatch) ➞ .\(result)")
        return result
    }
    
    
    mutating func replace(from startIndex: Int, to stopIndex: Int, withReduction form: Token.Form) { // startIndex..<stopIndex
        // reapply the preceding stack frame's matchers to newly reduced value
        // TO DO: make sure this correctly resumes in-progress matches (right now it's probably wrong)
        let matches: [PatternMatcher]
        if startIndex > 0 {
            //print(">", form)
            // TO DO: what about matches already on self[startIndex] (most will be continuations of previous match, but some may be backmatches of subsequent operator [but won't those be on last frame of expression tokens? I think we're currently losing those])
            matches = self[startIndex - 1].matches.flatMap{ $0.next() }.filter{ $0.match(form, allowingPartialMatch: true) }
        } else {
            //print("#", form)
            matches = self[startIndex].matches // kludge; TO DO: what should this be?
        }
        let reduction: Parser.StackItem = (form, matches, self[startIndex].hasLeadingWhitespace)
        self.replaceSubrange(startIndex..<stopIndex, with: [reduction])
    }
    
    
    mutating func reduce(completedMatch: PatternMatcher) { // called by Parser.shift() when auto-reducing; this performs a normal SR reduction from head of stack
        //print("REDUCING", completedMatch)
        let stopIndex = self.count // non-inclusive
        let startIndex = stopIndex - completedMatch.count
        let form = self.reductionFor(completedMatch: completedMatch)
        self.replace(from: startIndex, to: stopIndex, withReduction: form)
    }
}

    




 // caution: we have to be careful when reducing a range of tokens, as it's possible to have [pathological?] cases where an operator has an optional conjunction, e.g. `foo EXPR ( bar EXPR )?`: when parser encounters the `bar` conjunction, it will trigger a reduction of the preceding EXPR; however, that reduction must be limited to the EXPR only; the shorter `foo EXPR` match must be ignored in favor of completing the longer `foo…bar…` match (to maintain sanity, once a matcher matches a conjunction, it *must* complete otherwise it's a syntax error; while it's possible to backtrack and attempt other match combinations, it makes parsing behavior harder for humans to understand and predict; longest match first is dumb but it's understandable, and can always be overridden by adding parentheses)
 
 // it is not enough just to look for complete matches; we must also look for longest completion for each match (e.g. in `A is_after B as C`, the `as` keyword is an optional conjunction to `is_after` operator, not `as` operator)
 
 // another challenge: we can't immediately discard shorter/incomplete matches as not all matches have yet been run to exhaustion
 

 
 // Q. when an operator's middle EXPR contains operators with lower precedence, this will not affect binding; however, should PP parenthesize middle EXPR for clarity? (note: this case is more complicated when outer operator has optional conjunction)
 
 // important: all blocks (both punctuation and keyword delimited) must already be auto-reduced; any sub-expressions bounded by conjunctions should also be fully reduced by now (having been reduced prior to shifting the conjunction token); except for [LP?] commands there should not be any pending matches left within the specified range // if we ignore commands for now [TODO], we can extract the longest operator matches from the stack range and apply precedence rules to reduce those operators to .value(Command)s // TO DO: confirm `do…done` auto-reduces (it'll help us if all block structures auto-reduce themselves, as that minimizes unreduced token seqs and so maximizes matches; might even automatically trigger reduction when a fully matched pattern starts and ends with non-expr, avoiding need for explicit autoReduce flag)
 
 // at this point, can we reduce commands, treating .operatorNames as delimiters?
 
 // this is a bodge; there ought to be an easier way to discard non-longest completed matches during main parse loop (the way it works, for a given primary operator name, there can be at most 1 index difference between the matches it produces [prefix vs infix]; upon achieving longest match, if opdefs has >1 entry we could backtrack at that point to detect and discard shorter matches with same groupID; we might even discard _all_ previous matches with that groupID [i.e. non-longest completed matches and partial matches, which we no longer need either])
 // however, there is still the precedence climbing question: given `OP1 EXPR OP2 …` where parser is positioned on EXPR and looking ahead to OP2, there will be cases where we don't know for sure if we should reduce `OP1 EXPR` or shift `OP2`: while we can compare precedence[s] for [incomplete] OP2 against precedence for [completable] OP1, if OP2 has multiple definitions with precedences on both sides of OP1's we need to finish OP2 before we can make a decision; this will be rare




// TO REDUCE:
// if matches[0].start != 0, ops haven't matched exactly

// simple matching strategy, assuming range is 100% matched by single expression composed of 1 or more operations: start at first match in sorted array [of completed matches] (which should have start index 0) and get its end index, then advance until [longest] pattern whose start index == previous match's end index is found; repeat until end index == end of range (or no matches left, if not perfect match)

// the problem remains: unreduced operands prevent all patterns initially matching; thus there will be gaps between completed matches (e.g. `1 - -2`) -- so just keep re-running scan, doing one reduction per-pass, until no more reductions can be made


// note: even with this strategy we need to do precedence comparisons so that we know *which* match to reduce when (one or more) contentions are found; basically, when doing pass we need to extract operator indices and precedence, and have some way of chunking them when command names/arg labels are found




// a command name preceded by an operator requires that operator be prefix/infix (i.e. has trailing EXPR) else it's a syntax error; thus encountering a name when scanning backwards mean reduction can be performed from that command name up to any right-hand infix/postfix operators that have lower precedence than argument binding

// any operator to immediate right of an arg label must be prefix/atom else it's a syntax error


// patterns to look for: `.operatorName .value .operatorName` -- needs precedence/association comparison to resolve


// there is another problem with above: start and end indices of later matches will change as earlier matches are reduced

// note: not all ops will be fully matched at this point as some operands (e.g. commands) are not yet reduced

// a command is `NAME EXPR`
// LP syntax allows `NAME [EXPR] [LABEL: EXPR …]`

// `NAME NAME NAME …` is valid syntax, i.e. `NAME{NAME{NAME{…}}}`, although PP should insert braces to clarify

// while we are scanning backwards, we treat any labels as belonging to outermost (LP) command
// any reduced .value(_) preceded by NAME is a command; if the value is followed by infix/postfix OPNAME then precedence determines if value is argument and command is the operand or value is operand and operation is argument; most operators bind less tightly than argument (one notable exception is `of` and its associated reference forms) so, as a rule, `CMDNAME EXPR OPNAME` -> `OPNAME{CMDNAME{EXPR}}`

// `NAME NAME NAME …` pattern can appear anywhere - at start of range (in which case it's command's name + direct argument) or after a label (in which case it's an argument to command); labels always associate with outermost command, however

// commands are effectively prefix operators so precedence comparison is only needed for infix/postfix operators appearing *after* a command name/arg label; a prefix/infix operator name preceding command name will always reduce that particular command - the question is where that command's right-side terminates

// there is an added wrinkle with precedence, e.g. `foo 1 + 2` -> `+{foo{1},2}` but `foo 1 + 2 bar: 3` is a syntax error

// note that `foo 1 + a bar: 3` -> `+{foo{1},a{bar:3}}`; when scanning back from end, the labeled arg associates with `a`, not `foo`; the PP should probably transform this code to `(foo 1) + (a bar: 3)` or `foo {1} + a {bar:3}` to avoid any visual ambiguity

// logic for disambiguating `cmd OP val` where OP is both prefix and infix operator (this should be hardcoded behavior in parser, not pattern): if OP has balanced whitespace then treat as infix operator whose LH operand is cmd; if OP has unbalanced whitespace (e.g. `foo -1`) then treat as prefix operator on val and pass that operation as argument



// note that operators with conjunctions should have already-reduced middle EXPRs by the time fullyReduceExpression() is called to reduce an entire expression, so only their leading/trailing EXPRs remain to be resolved, which is where precedence and associativity come into play

// unfortunately, textbook SR precedence parsing isn't an option as that assumes a fixed set of operators whose precedence can be reliably determined just by comparing two OperatorDefinitions, with no possibility that overloaded definitions could return conflicting answers (e.g. given operators `foo` and `bar`, ALL definitions of `foo` are guaranteed to come before ALL definitions of `bar`, or vice-versa, but NEVER a mix of both); however, since all our operators are library-defined using PEG-like grammars, the only way to know for sure which overloaded operator definition to use (and thus if it has leading and/or trailing operands and, if it does, what its precedence and associativity is) to match them all and see which one completes (at which point we've shifted a whole bunch of tokens, so can no longer just reduce from the head; we'd either have to roll back the head of the stack to the highest-precedence expression and reduce that, or else treat that section of the stack as a random-access array and perform reductions mid-stack instead of from the head only); a typical example is `+` and `-`, which have both prefix and infix definitions

// another problem: reducing mid-stack makes tracking remaining tokens and matches their by stack indices a right pig as each reduction removes stack elements, invalidating all previously-stored stack indices after that point; currently we use match indices to determine where two operators share a common operand (i.e. the two matches overlap); it may be possible to come up with a robust implementation that doesn't rely on indices, but for now we avoid the problem by leaving the main stack alone and copying each range of matched tokens to its own “private” array which can be independently manipulated without affecting anything else; it smells, and probably wastes quite a few cycles, but it works well enough to do for now

