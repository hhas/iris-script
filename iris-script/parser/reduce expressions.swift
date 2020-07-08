//
//  expression reduce.swift
//  iris-script
//

import Foundation


extension Parser {
    
    
    
    
    func reduceExpressionBeforeConjunction(_ name: Symbol, matchedBy matchers: ConjunctionMatches) {
        // called by parser before shifting a conjunction keyword onto stack to reduce the EXPR that precedes it
        // note: matching a conjunction keyword forces reduction of the preceding expr; in the event that the operator is nested (e.g. `if test then if test then action`) the caller uses Parser.blockMatches stack to track [potentially nested] in-progress operator matches currently waiting for their conjunction to appear, pairing up the closest, i.e. innermost, pair of primary and conjunction keywords first (thus:  `if test then if test then action` -> `if test then (if test then action)` -> `(if test then (if test then action))`)
        // TO DO: since matchers comes directly from BlockStack’s head .conjunction(…), which in turn corresponds to a single .operatorName(…) token, it will usually contain a single PatternMatch instance stored under one or more names (depending on whether the conjunction keyword includes aliases); occasionally there will be >1 matcher if the primary keyword is overloaded, e.g. `repeat…while…` vs `repeat…until…`; that said, since conjunction matching is greedy, the first conjunction found wins and the rest should be discarded (based on groupID)
        let parentMatch: PatternMatch
        let resumeIndex: Int // TO DO: use this rather than lastIndex search below?
        if matchers.count == 1 {
            (parentMatch, resumeIndex) = matchers[0]
        } else {
            (parentMatch, resumeIndex) = matchers.min{ $0.match.count < $1.match.count }! // confirm this logic; if there are multiple matchers in progress it should associate with the nearest/innermost, i.e. shortest = most recently started (e.g. consider nested `if…then…` expressions); it does smell though
        }
        let matchID = parentMatch.uniqueID // find nearest
        // find the partial match to which this conjunction keyword belongs (e.g. the partial `if EXPR…` match); this must be earlier in the same expression otherwise a syntax error will occur
        // note that a stray conjunction (i.e. one which is not preceded by the operator’s primary keyword, e.g. `notif test then action`) will not trigger reduceExpressionBeforeConjunction(:…)
        // TO DO: not quite sure why this back-search doesn't find the `if EXPR…` matcher to which this `then` belongs, despite it being in a different expression (i.e. it still has access to the entire parser stack, not just the subrange for the current EXPR)
        // TO DO: check behavior for `if 1,2 then 3`
        guard let matchIndex = self.tokenStack.lastIndex(where: { $0.matches.contains{ $0.uniqueID == matchID } }) else {
            // the matcher to which this conjunction belongs lies in an earlier (i.e. unrelated) expression; e.g. given the code `if 1, then 2`, the parser fails to fully match `if…then…` due to the delimiter after the test EXPR, pushing the unreduced `if 1` onto stack as a Syntax Error instead; then, upon encountering `then 2` in a subsequent expression, it lands here when it is unable to locate the earlier partial `if EXPR` match to which the `then` conjunction belongs
            let e = InternalError(description: "Syntax Error: Found `\(parentMatch.definition.name.label)` conjunction but the operator to which it belongs is not in the same expression.")
            self.tokenStack.replace(from: self.tokenStack.count - 1, to: self.tokenStack.count, withReduction: .error(e))
            return
        }
        assert(resumeIndex == matchIndex, "BUG in conjunction's resumeIndex: expected \(matchIndex) but got \(resumeIndex)")
        //print(">>>>>", resumeIndex, matchIndex)
        // remove the now-matched (though not yet shifted) conjunction from block stack
        self.blockStack.end(name) // TO DO: don’t _think_ the order of this relative to EXPR reduction is signifcant, but make sure
        //print("Removed matched conjunction from block stack:", name)
        // reduce the preceding EXPR
        let startIndex = matchIndex + 1
        let stopIndex = self.tokenStack.count
        //print("REDUCING EXPR before conjunction: .\(name) from", startIndex, "to", stopIndex, self.tokenStack[startIndex])
        //print("---")
        self.fullyReduceExpression(from: startIndex, to: stopIndex) // start..<stop
        // TO DO: now the reduced EXPR is on stack, we ought to fully match it to be sure [but this applies to pattern-driven reductions in general]
        self.shift() // shift the conjunction onto stack (note: this does not add remaining conjunctions to blockStack; that is done below) // TO DO: should it? the logic should be similar for new and in-progress matches
        // check if this pattern still conjunctions to match (i.e. the previous matchers should have been matched to the EXPR on the stack and are now waiting to match the conjunction)
        let remainingConjunctions = self.tokenStack.last!.matches.filter{$0.originID == parentMatch.originID}.flatMap{$0.next()}.filter{!$0.conjunctions.isEmpty} // get matchers for token after newly-shifted conjunction (if any) to see if there further conjunctions still to match (e.g. `if…then…else…` operator has two conjunctions to match, the second of which is optional)
        if !remainingConjunctions.isEmpty {
            let stopIndex = self.tokenStack.count
            self.blockStack.begin(remainingConjunctions, for: name, from: stopIndex)
        }
    }
    
    
    
    func fullyReduceExpression(from _startIndex: Int = 0, to stopIndex: Int? = nil) { // starting point for reductions called by main loop
        var stopIndex = stopIndex ?? self.tokenStack.count // caution: stopIndex is nearest head of stack, so will no longer be valid once a reduction is performed // TO DO: return new stopIndex via inout?
        // scan back from stopIndex until an expression delimiter is found or original startIndex is reached; that then becomes the startIndex for findLongestMatches // TO DO: is this still needed? currently when fullyReduceExpression is called, how is the _startIndex argument determined?
        var startIndex = self.tokenStack.findStartIndex(from: _startIndex, to: stopIndex)
        //  print("…found startIndex", startIndex)
       // print("fullyReduceExpression:"); self.tokenStack.show(startIndex, stopIndex)
        
        if startIndex == stopIndex { return } // zero length, e.g. `[ ]`
        
        // if the token range starts with a label, stop over it and only reduce the expr after it; this is kludgy, but hopefully it addresses the issue well enough to proceed as `LABEL EXPR` should only [currently?] arise in two places: after an LP command name and in a record field, and in first case we want findStartIndex to skip over labels (which are always preceded by at least one token) while in the second the label, if present, is always the first token in found range (which is what the next line ignores), and the record literal’s reducefunc eventually takes care of it // TO DO: if we allow `LABEL EXPR` for name-value bindings in blocks, how will this affect parsing/matching
        if startIndex < stopIndex, case .label(_) = self.tokenStack[startIndex].form {
            startIndex += 1
        }
        
        // reduce all commands within the specified range in-place, decrementing stopIndex on return by the number of tokens removed during this reduction
        // (note that nested commands are not immediately reduced here but are instead tagged with matchers that will reduce them during reductionForOperatorExpression() as if they were atom/prefix operators of predetermined precedence; also note that full-punctuation commands, i.e. `NAME RECORD`, have already been reduced to .value(Command(…)) by the parser's main loop so are not touched again here)
        self.reduceCommandExpressions(from: startIndex, to: &stopIndex)
        // once all commands’ boundaries have been determined and the commands themselves reduced to .values, reduce all operators
        
        
        // TO DO: FIX: this interferes with e.g. do…done - it’s overly aggressive in what it removes from stack; it should only remove conjunctions whose matchers started within the current EXPR; that's not right either, e.g. given `if test then do, … done`, the comma should not terminate `do`; the problem is operators that have optional/trailing expr (i.e. no explicit terminator) need to be terminated by delimiters, but not blocks
        
        self.blockStack.endConjunctions() // discard any pending conjunctions, e.g. given `if TEST then ACTION.`, this will discard the `else` clause upon encountering period delimiter; note that if an operator has >1 conjunction, reduceExpressionBeforeConjunction() will add a new entry to blockStack after it’s shifted the first conjunction
        
        //   print("<<<",self.blockStack)
        self.tokenStack.reduceOperatorExpression(from: startIndex, to: &stopIndex)
          // print("REDUCED OPERATOR:"); self.tokenStack.show(startIndex); print("…TO: .\(form)\n\n----\n\n")
    }
    
}
