//
//  match and reduce.swift
//  iris-script
//

// WIP

import Foundation


// `to name returning typename typearg: action` is problematic; it's not clear if `typearg` is labeled arg or direct arg; one option would be to use `to…do…done`, but that's inconsistent with `do…done` usage elsewhere; might use a different conjunction, e.g. `to…run…`, `to…perform…`, `to…then…`, `to…action…`, `to…evaluate…`

// pulled this out of Parser for now; not sure if it should be there or on matcher


// TO DO: conjunctions should trigger reduction (what if conjunction is also non-conjunction)



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



// TO DO: should stack track previous delimiter index, allowing us to know number of stack frames to be reduced (if 1, and it's .value, we know it's already fully reduced)

// TO DO: when comparing precedence, look for .values in stack that have overlapping operator matches where one isAtBeginningOfMatch and other isAFullMatch; whichever match has the higher definition.precedence (or if both are same definition and associate==.right) reduce that first



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



typealias MatchInfo = (start: Int, end: Int, matcher: PatternMatcher) // `start...end`

func key(_ info: MatchInfo) -> String {
    return "\(info.start) \(info.matcher.definition.name.key)"
}


extension Parser {
    
    func readLowPunctuationCommand() {
        
    }
    
    // start..<stop // TO DO: decide if end index is inclusive or exclusive and standardize across all code
    func fullyReduceExpression(from startIndex: Int = 0, to stopIndex: Int? = nil, allowLPCommands: Bool = false) {
        let stopIndex = stopIndex ?? self.stack.count
        
        // caution: stopIndex is nearest head of stack, so will no longer be valid once reductions are performed
        
        print("…fully reduce:")
        //show(self.stack, startIndex, stopIndex)
        
        // caution: we have to be careful when reducing a range of tokens, as it's possible to have [pathological?] cases where an operator has an optional conjunction, e.g. `foo EXPR ( bar EXPR )?`: when parser encounters the `bar` conjunction, it will trigger a reduction of the preceding EXPR; however, that reduction must be limited to the EXPR only; the shorter `foo EXPR` match must be ignored in favor of completing the longer `foo…bar…` match (to maintain sanity, once a matcher matches a conjunction, it *must* complete otherwise it's a syntax error; while it's possible to backtrack and attempt other match combinations, it makes parsing behavior harder for humans to understand and predict; longest match first is dumb but it's understandable, and can always be overridden by adding parentheses)
        
        // TO DO: precedence
        
        // it is not enough just to look for complete matches; we must also look for longest completion for each match (e.g. in `A is_after B as C`, the `as` keyword is an optional conjunction to `is_after` operator, not `as` operator)
        
        // another challenge: we can't immediately discard shorter/incomplete matches as not all matches have yet been run to exhaustion
        
        // TO DO: confirm `do…done` auto-reduces (it'll help us if all block structures auto-reduce themselves, as that minimizes unreduced token seqs and so maximizes matches; might even automatically trigger reduction when a fully matched pattern starts and ends with non-expr, avoiding need for explicit autoReduce flag)
        
        // Q. when an operator's middle EXPR contains operators with lower precedence, this will not affect binding; however, should PP parenthesize middle EXPR for clarity? (note: this case is more complicated when outer operator has optional conjunction)
        
        // important: all blocks (both punctuation and keyword delimited) must already be auto-reduced; any sub-expressions bounded by conjunctions should also be fully reduced by now (having been reduced prior to shifting the conjunction token); except for [LP?] commands there should not be any pending matches left within the specified range // if we ignore commands for now [TODO], we can extract the longest operator matches from the stack range and apply precedence rules to reduce those operators to .value(Command)s
        
        // at this point, can we reduce commands, treating .operatorNames as delimiters?
        
        // this is a bodge; there ought to be an easier way to discard non-longest completed matches during main parse loop (the way it works, for a given primary operator name, there can be at most 1 index difference between the matches it produces [prefix vs infix]; upon achieving longest match, if opdefs has >1 entry we could backtrack at that point to detect and discard shorter matches with same groupID; we might even discard _all_ previous matches with that groupID [i.e. non-longest completed matches and partial matches, which we no longer need either])
        // however, there is still the precedence climbing question: given `OP1 EXPR OP2 …` where parser is positioned on EXPR and looking ahead to OP2, there will be cases where we don't know for sure if we should reduce `OP1 EXPR` or shift `OP2`: while we can compare precedence[s] for [incomplete] OP2 against precedence for [completable] OP1, if OP2 has multiple definitions with precedences on both sides of OP1's we need to finish OP2 before we can make a decision; this will be rare
        var longestMatches = [Int: (start: Int, stop: Int, match: PatternMatcher, tokens: [StackItem])]() // [groupID:(start...stop,match)]
        for rightExpressionIndex in (startIndex..<stopIndex).reversed() {
            //print(index)
            let f = self.stack[rightExpressionIndex]
            //if case .operatorName(let d) = f.reduction {
                //print("…found operator:", d.name)
            //} else {
                //print("…matchers new:", f.matches.filter({$0.isAtBeginningOfMatch}),
                //      "\n         full:", f.matches.filter({$0.isAFullMatch}))
            //}
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
        
        // note that operators with conjunctions should have reduced middle EXPRs by now, so only leading/trailing EXPRs remain to be resolved, which is where precedence and associativity come into play
        // Q. does this mean we can reduce as we parse, using a precedence climbing stack, or is there any reason to read entire token seq up to expr delimiter then work back?
        
        // one way to read commands is to have intermediate .command(…) on parser stack
        
        
        var matches = longestMatches.values.sorted{ $0.stop > $1.stop }
        if matches.isEmpty {
            print("WARNING: no complete matches")
            return
        }
        print(">>>", matches)
        var rightExpressionIndex = 0
        while matches.count > 1 {
            //print("matches:", matches.map{ "\($0.start)-\($0.stop)\($0.match.name)" }.joined(separator: " "))
            var right = matches[rightExpressionIndex], left = matches[rightExpressionIndex + 1]
            var hasSharedOperand = left.stop == right.start
            while matches.count > 1 && rightExpressionIndex < matches.count - 2 && hasSharedOperand && !right.match.reduceBefore(precedingMatcher: left.match) {
                rightExpressionIndex += 1
                right = matches[rightExpressionIndex]
                left = matches[rightExpressionIndex + 1]
                hasSharedOperand = left.stop == right.start
            }
            let leftExpressionIndex = rightExpressionIndex + 1
            // index = RIGHT
            //print("LEFT:", left, "\nRIGHT:", right, "\n", rightExpressionIndex)
            //print("hasSharedOperand:", hasSharedOperand, left.match.name, right.match.name)
            if hasSharedOperand {
                //print("COMPARE PRECEDENCE", left.match, right.match, right.match.reduceBefore(precedingMatcher: left.match))
                if right.match.reduceBefore(precedingMatcher: left.match) { // reduce match[0] (nearest head of stack)
                    print("REDUCE RIGHT EXPR", right.match.name)
                    let definition = right.match.definition
                    let reduction = definition.reduce(right.tokens, definition, 0, right.tokens.count)
                    //print("…TO: .\(reduction)")
                    switch reduction { // (reduction: Form, matches: [PatternMatcher], hasLeadingWhitespace: Bool, token: Token)
                    case .value(let v):
                        // left = matches[index+1], right = matches[index]
                        let lastIndex = matches[leftExpressionIndex].tokens.count - 1
                        matches[leftExpressionIndex].tokens[lastIndex] = (.value(v), [], right.tokens[0].hasLeadingWhitespace, left.tokens[lastIndex].token) // TO DO: what should Token be? (for now we just dummy it; if it turns out never to be used then best to remove it from parser stack entirely)
                        matches[leftExpressionIndex].stop = right.stop
                    case .error(let e): fatalError("reduction failed: \(e)") // TO DO: where should errors be repackaged as Values (probably best for parser to provide method for that, as it should include the raw tokens and other information that may be used to describe the error, suggest corrections, etc)
                    }
                    matches.remove(at: rightExpressionIndex)
                } else { // reduce match[1]
                    print("REDUCE LEFT EXPR", left.match.name)
                    let definition = left.match.definition
                    let reduction = definition.reduce(left.tokens, definition, 0, left.tokens.count)
                    //print("…TO: .\(reduction)")
                    switch reduction { // (reduction: Form, matches: [PatternMatcher], hasLeadingWhitespace: Bool, token: Token)
                    case .value(let v):
                        // left = matches[index+1], right = matches[index]
                        matches[rightExpressionIndex].tokens[0] = (.value(v), [], left.tokens[0].hasLeadingWhitespace, left.tokens[0].token) // TO DO: what should Token be? (for now we just dummy it; if it turns out never to be used then best to remove it from parser stack entirely)
                        matches[rightExpressionIndex].start = left.start
                    case .error(let e): fatalError("reduction failed: \(e)") // TO DO: where should errors be repackaged as Values (probably best for parser to provide method for that, as it should include the raw tokens and other information that may be used to describe the error, suggest corrections, etc)
                    }
                    matches.remove(at: leftExpressionIndex)
                }
            } else {
                //assert(right.start > left.stop)
                print("no shared operand")
                fatalError("TO DO: non-overlapping operations, e.g. `1+2 3+4`") // pretty sure `EXPR EXPR` is always a syntax error (with opportunities to suggest corrections, e.g. by inserting a delimiter)
            }
            rightExpressionIndex -= 1 // since we've removed an element // TO DO: is this always needed, or only in some cases?

            print(">>>", matches)
        }
        
        
        // reduce last expr
        let left = matches[0]
        let definition = left.match.definition
        let expression = definition.reduce(left.tokens, definition, 0, left.tokens.count)
        print("…EXPR REDUCED TO: .\(expression)")
        let reduction: StackItem
        switch expression { // (reduction: Form, matches: [PatternMatcher], hasLeadingWhitespace: Bool, token: Token)
        case .value(let v):
            let partialMatches = self.stack[startIndex].matches // TO DO: confirm this is right
            reduction = (.value(v), partialMatches, self.stack[startIndex].hasLeadingWhitespace, self.stack[startIndex].token) // token is dummy value
        case .error(let e): fatalError("reduction failed: \(e)") // TO DO
            
        }
        
        // TO DO: FIX: this doesn't update stack's matchers; see reduce(completedMatch:endingAt:) below; we really need to refactor all this logic mess into discrete, reusable methods
        self.stack.replaceSubrange((startIndex..<stopIndex), with: [reduction])
        
        
    }
    
    
    // TO DO: is endingAt: needed? currently this method is only used when auto-reducing, which always applies at head of stack
    func reduce(completedMatch: PatternMatcher, endingAt endIndex: Int) { // called by Parser.shift() when auto-reducing
        print("REDUCING", completedMatch)
        let startIndex = endIndex - completedMatch.count // check math (endIndex is inclusive)
        let reduction: StackItem
        let token: Token = endIndex < self.stack.count ? self.stack[endIndex].token : self.current.token
        let hasLeadingWhitespace = self.stack[startIndex].hasLeadingWhitespace
        switch completedMatch.definition.reduce(self.stack, completedMatch.definition, startIndex, endIndex) {
        case .value(let v):
            var updatedMatchers = [PatternMatcher]()
            if startIndex > 0 { // reapply the preceding stack frame's matchers to newly reduced value
                for match in self.stack[startIndex - 1].matches {
                    for match in match.next() {
                        //print("rematching", match, "to", type(of: v), v, match.match(.value(v)))
                        if match.match(.value(v)) {
                            updatedMatchers.append(match)
                            // TO DO: what if match is completed? where should reduction be triggered? (where should contention be checked?)
                        }
                    }
                }
                //print("updated matchers:", updatedMatchers)
            }
            reduction = (Form.value(v), updatedMatchers, hasLeadingWhitespace, token)
        case .error(let e):
            reduction = (Form.error(e), [], hasLeadingWhitespace, token)
        }
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
        print("Reducing expression before conjunction .\(conjunction):")
        self.fullyReduceExpression(from: startIndex, to: stopIndex) // start..<stop
    }
    
}
