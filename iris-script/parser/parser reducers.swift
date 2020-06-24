//
//  match and reduce.swift
//  iris-script
//

// WIP // pulled this out of Parser for now; not sure if it should be there or on matcher

import Foundation

 
 // caution: we have to be careful when reducing a range of tokens, as it's possible to have [pathological?] cases where an operator has an optional conjunction, e.g. `foo EXPR ( bar EXPR )?`: when parser encounters the `bar` conjunction, it will trigger a reduction of the preceding EXPR; however, that reduction must be limited to the EXPR only; the shorter `foo EXPR` match must be ignored in favor of completing the longer `foo…bar…` match (to maintain sanity, once a matcher matches a conjunction, it *must* complete otherwise it's a syntax error; while it's possible to backtrack and attempt other match combinations, it makes parsing behavior harder for humans to understand and predict; longest match first is dumb but it's understandable, and can always be overridden by adding parentheses)
 
 // it is not enough just to look for complete matches; we must also look for longest completion for each match (e.g. in `A is_after B as C`, the `as` keyword is an optional conjunction to `is_after` operator, not `as` operator)
 
 // another challenge: we can't immediately discard shorter/incomplete matches as not all matches have yet been run to exhaustion
 

 
 // Q. when an operator's middle EXPR contains operators with lower precedence, this will not affect binding; however, should PP parenthesize middle EXPR for clarity? (note: this case is more complicated when outer operator has optional conjunction)
 
 // important: all blocks (both punctuation and keyword delimited) must already be auto-reduced; any sub-expressions bounded by conjunctions should also be fully reduced by now (having been reduced prior to shifting the conjunction token); except for [LP?] commands there should not be any pending matches left within the specified range // if we ignore commands for now [TODO], we can extract the longest operator matches from the stack range and apply precedence rules to reduce those operators to .value(Command)s // TO DO: confirm `do…done` auto-reduces (it'll help us if all block structures auto-reduce themselves, as that minimizes unreduced token seqs and so maximizes matches; might even automatically trigger reduction when a fully matched pattern starts and ends with non-expr, avoiding need for explicit autoReduce flag)
 
 // at this point, can we reduce commands, treating .operatorNames as delimiters?
 
 // this is a bodge; there ought to be an easier way to discard non-longest completed matches during main parse loop (the way it works, for a given primary operator name, there can be at most 1 index difference between the matches it produces [prefix vs infix]; upon achieving longest match, if opdefs has >1 entry we could backtrack at that point to detect and discard shorter matches with same groupID; we might even discard _all_ previous matches with that groupID [i.e. non-longest completed matches and partial matches, which we no longer need either])
 // however, there is still the precedence climbing question: given `OP1 EXPR OP2 …` where parser is positioned on EXPR and looking ahead to OP2, there will be cases where we don't know for sure if we should reduce `OP1 EXPR` or shift `OP2`: while we can compare precedence[s] for [incomplete] OP2 against precedence for [completable] OP1, if OP2 has multiple definitions with precedences on both sides of OP1's we need to finish OP2 before we can make a decision; this will be rare


extension Token.Form {
    
    var canBeLabel: Bool {
        switch self {
        case .operatorName(_), .quotedName(_), .unquotedName(_): return true
        default:                                                 return false
        }
    }
    
    var isName: Bool {
        switch self {
        case .quotedName(_), .unquotedName(_): return true
        default:                               return false
        }
    }
    
    func toName() -> Symbol {
        switch self {
        case .quotedName(let name), .unquotedName(let name): return name
        case .operatorName(let definitions):                 return definitions.name
        default:                                             return nullSymbol
        }
    }
}


extension Array where Element == Parser.StackItem {
    
    func reduce(completedMatch: PatternMatcher) -> Token.Form { // reduce a single fully matched expression at head of stack to a single value // TO DO: what to call this method? (it doesn't put the result back onto parser stack or update stack's matchers, so is not a full reduction step in the Shift-Reduce sense)
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
}



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



typealias MatchInfo = (start: Int, end: Int, matcher: PatternMatcher) // `start...end`

func key(_ info: MatchInfo) -> String {
    return "\(info.start) \(info.matcher.definition.name.key)"
}


extension Parser {
    
    func readLowPunctuationCommand() {
        
    }
    
    // TO DO: two options for parsing commands: 1. leave it entirely to fullyReduceExpression(), which can search for names and labels and call itself to reduce arguments in LP syntax (the delimiter being `NAME COLON` labels); or 2. put commands on Parser.blockMatches and read them in main loop
    
    typealias LongestMatch = (start: Int, stop: Int, match: PatternMatcher, tokens: [StackItem])
    
    // start..<stop // TO DO: decide if end index is inclusive or exclusive and standardize across all code
    func findLongestMatches(_ startIndex: Int, _ stopIndex: Int) -> [LongestMatch] {
        var longestMatches = [Int: LongestMatch]() // [groupID:(start...stop,match,tokens)] // note that first/last tokens in sub-array may represent incomplete matches, e.g. given `1 * - 2`, the `*` match's tokens will be [`1`,`*`,`-`]; it's up to the reducer to reduce [`-`,`2`] to value `-2` and substitute that in place of the `*` match's `-` token

        
        // TO DO: this isn't picking up `…*…` match in ` 1 + 2 * -3 ` (probably because the `…*…` matcher isn't matching the `-` as [potentially] the start of an expr)
        
        for rightExpressionIndex in (startIndex..<stopIndex).reversed() {
            //print(index)
            let f = self.stack[rightExpressionIndex]
            
            switch f.reduction {
            case .operatorName(let d):
                if rightExpressionIndex < stopIndex - 1 , case .colon = self.stack[rightExpressionIndex+1].reduction {
                    print("OPLABEL", d.name)
                } else {
                    print("OPNAME", d.name)
                }
            case .unquotedName(let n), .quotedName(let n):
                print("NAME", n)
            default:
                print(f.reduction)
            }
            print("…matchers new:", f.matches.filter({$0.isAtBeginningOfMatch}),
            "\n         part:", f.matches.filter({!$0.isAtBeginningOfMatch && !$0.isAFullMatch}),
            "\n         full:", f.matches.filter({$0.isAFullMatch}))
            for m in f.matches {
                if m.isAFullMatch {
                    //print("full",m)
                    if let pm = longestMatches[m.groupID] {
                        if pm.match.count < m.count {
                            let start = m.startIndex(from: rightExpressionIndex)
                            longestMatches[m.groupID] = (start, rightExpressionIndex, m, [StackItem](self.stack[start...rightExpressionIndex])) // stop index is inclusive
                            //print("discard", m)
                        }
                    } else {
                        let start = m.startIndex(from: rightExpressionIndex)
                        longestMatches[m.groupID] = (start, rightExpressionIndex, m, [StackItem](self.stack[start...rightExpressionIndex]))
                    }
                } else {
                    //print("part",m)
                }
            }
        }
        return longestMatches.values.sorted{ $0.stop < $1.stop }
    }
    
    func fullyReduceExpression(from startIndex: Int = 0, to stopIndex: Int? = nil, allowLPCommands: Bool = false) {
        let stopIndex = stopIndex ?? self.stack.count // caution: stopIndex is nearest head of stack, so will no longer be valid once a reduction is performed
        
       // print("fullyReduceExpression:", self.stack[startIndex..<stopIndex].map{"\n\t\t.\($0.reduction)\($0.matches.map{"\n\t\t\t\t\($0)"}.joined(separator: ""))"}.joined(separator: ""))
        //show(self.stack, startIndex, stopIndex)
        var matches = self.findLongestMatches(startIndex, stopIndex)
        if matches.isEmpty {
            print("WARNING: no complete matches")
            return
        }
       // for m in matches { print(">>>", m) }
        // starting from head (right) of stack, shift left to find the highest-precedence operator and reduce that; rinse and repeat until only one operator is left to reduce
        var rightExpressionIndex = matches.count - 1
        var leftExpressionIndex = rightExpressionIndex - 1
        while matches.count > 1 {
            //print("matches:", matches.map{ "\($0.start)-\($0.stop)\($0.match.name)" }.joined(separator: " "))
            var left = matches[leftExpressionIndex], right = matches[rightExpressionIndex]
            var hasSharedOperand = left.stop == right.start
            while leftExpressionIndex > 0 && hasSharedOperand && left.match.reduceBefore(followingMatcher: right.match) {
                leftExpressionIndex -= 1; rightExpressionIndex -= 1
                left = matches[leftExpressionIndex]; right = matches[rightExpressionIndex]
                hasSharedOperand = left.stop == right.start
            }
            // left = matches[index+1], right = matches[index]
            //print("LEFT:", left, "\nRIGHT:", right, "\n", rightExpressionIndex)
            //print("hasSharedOperand:", hasSharedOperand, left.match.name, right.match.name)
            if hasSharedOperand {
                if left.match.reduceBefore(followingMatcher: right.match) {
                    //print("REDUCE LEFT EXPR", left.match.name)
                    let form = left.tokens.reduce(completedMatch: left.match)
                    //print("…TO: \(form)")
                    matches[rightExpressionIndex].tokens[0] = (form, [], left.tokens[0].hasLeadingWhitespace)
                    matches[rightExpressionIndex].start = left.start
                    matches.remove(at: leftExpressionIndex)
                } else {
                    //print("REDUCE RIGHT EXPR", right.match.name)
                    let form = right.tokens.reduce(completedMatch: right.match)
                    //print("…TO: \(form)")
                    let lastIndex = matches[leftExpressionIndex].tokens.count - 1
                    matches[leftExpressionIndex].tokens[lastIndex] = (form, [], right.tokens[0].hasLeadingWhitespace)
                    matches[leftExpressionIndex].stop = right.stop
                    matches.remove(at: rightExpressionIndex)
                }
            } else {
                // TO DO: this also happens if an operator match is missing from matches (which is itself probably a bug)
                //assert(right.start > left.stop)
                print("no shared operand:\n\t", left, "\n\t", right)
                // TO DO: need to fully reduce right expr[s], move result to stack, remove that matcher and reset indices, then resume
                fatalError("TO DO: non-overlapping operations, e.g. `1+2 3+4`") // pretty sure `EXPR EXPR` is always a syntax error (with opportunities to suggest corrections, e.g. by inserting a delimiter)
            }
            //print(">>>", matches)
            if rightExpressionIndex == matches.count {
                leftExpressionIndex -= 1
                rightExpressionIndex -= 1 // since we've removed an element
            }
            //
        }
        
        
        // reduce the last operator expression
        let form = matches[0].tokens.reduce(completedMatch: matches[0].match)
        print("…EXPR FULLY REDUCED TO: \(form)")
        // TO DO: confirm this correctly resumes parser stack's in-progress matches
        let partialMatches = self.reapplyMatches(at: startIndex)
        // replace the specified portion of the parser stack with its reduction (.value/.error)
        let reduction = (form, partialMatches, self.stack[startIndex].hasLeadingWhitespace)
        self.stack.replaceSubrange((startIndex..<stopIndex), with: [reduction])
    }
    
    func reapplyMatches(at startIndex: Int) -> [PatternMatcher] {
        // reapply the preceding stack frame's matchers to newly reduced value
        if startIndex > 0 {
            let form = self.stack[startIndex].reduction
            return self.stack[startIndex - 1].matches.flatMap{ $0.next() }.filter{ $0.match(form, allowingPartialMatch: true) }
        } else {
            return [] // TO DO: what should this be?
        }
    }
    
    // TO DO: is endingAt: needed? currently this method is only used when auto-reducing, which always applies at head of stack
    func reduce(completedMatch: PatternMatcher, endingAt endIndex: Int) { // called by Parser.shift() when auto-reducing
        //print("REDUCING", completedMatch)
        let startIndex = endIndex - completedMatch.count // check math (endIndex is inclusive)
        let hasLeadingWhitespace = self.stack[startIndex].hasLeadingWhitespace
        let form = self.stack.reduce(completedMatch: completedMatch)
        let updatedMatchers = self.reapplyMatches(at: startIndex)
        let reduction = (form, updatedMatchers, hasLeadingWhitespace)
        //      print("reduce()", completedMatch, "->", reduction)
        self.stack.replaceSubrange((startIndex..<endIndex), with: [reduction])
        //show(self.stack, 0, self.stack.count, "after reduction")
    }
    
    //
    
    // note: matching a conjunction keyword forces reduction of the preceding expr
    
    // TO DO: this assumes conjunction's .operatorName token has yet to be shifted onto parser stack (for now this assumption should hold as it's only ever called from parser's main loop, which always operates on head of stack)
    
    func reduce(conjunction: Token.Form, matchedBy matchers: [PatternMatcher]) {
        let matchID: Int // find nearest
        if matchers.count == 1 {
            matchID = matchers[0].matchID
        } else {
            matchID = matchers.min{ $0.count < $1.count }!.matchID // confirm this logic; if there are multiple matchers in progress it should associate with the nearest/innermost, i.e. shortest = most recently started (e.g. consider nested `if…then…` expressions); it does smell though
        }
        let startIndex = self.stack.lastIndex{ $0.matches.first{ $0.matchID == matchID } != nil }! + 1
        let stopIndex = self.stack.count
        print("FULLY REDUCING EXPR before conjunction: .\(conjunction)…")
        self.fullyReduceExpression(from: startIndex, to: stopIndex) // start..<stop
    }
    
}
