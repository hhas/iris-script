//
//  conjunction.swift
//  iris-script
//

// temporarily pulled to its own file for debugging


import Foundation


// TO DO: since matchers comes directly from BlockStack’s head .conjunction(…), which in turn corresponds to a single .operatorName(…) token, it will usually contain a single PatternMatch instance stored under one or more names (depending on whether the conjunction keyword includes aliases); occasionally there will be >1 matcher if the primary keyword is overloaded, e.g. `repeat…while…` vs `repeat…until…`; that said, since conjunction matching is greedy, the first conjunction found wins and the rest should be discarded (based on groupID)


// TO DO: this is all rather kludgy; need to decide what to do in even of overloaded matches


// TO DO: what if this reduction fails?


// note: matching a conjunction keyword forces reduction of the preceding expr; in the event that the operator is nested (e.g. `if test then if test then action`) the caller uses Parser.blockMatches stack to track [potentially nested] in-progress operator matches currently waiting for their conjunction to appear, pairing up the closest, i.e. innermost, pair of primary and conjunction keywords first (thus:  `if test then if test then action` -> `if test then (if test then action)` -> `(if test then (if test then action))`)



extension Parser {
    
    // TO DO: there is another problem here: if a conjunction is optional, it should be automatically removed when a block is closed or [assuming it's part of same EXPR] fullyReduceExpression is called (correction: it should be removed anyway; if it leaves an incomplete match behind, that gets reported as a syntax error)
    
    // Q. is there ever a situation where an EXPR ends where .conjunctions should _not_ be discarded from BlockStack? (i.e. is there any situation where the operator can span >1 expr? the answer _should_ be no)
    
    func reduceExpressionBeforeConjunction(_ name: Symbol, matchedBy matchers: ConjunctionMatches) {
        // called by parser before shifting a conjunction keyword onto stack to reduce the EXPR that precedes it
        
        //print("\nreduceExpressionBeforeConjunction():", name)
        //print("…between head and earlier pattern:"); for m in matchers { print("\t\t",m) }
        //print(); print(">>>>"); self.blockStack.show(); print()
        
        
        let parentMatch: PatternMatch
        let resumeIndex: Int // TO DO: use this rather than lastIndex search below?
        if matchers.count == 1 {
            (parentMatch, resumeIndex) = matchers[0]
        } else {
            (parentMatch, resumeIndex) = matchers.min{ $0.match.count < $1.match.count }! // confirm this logic; if there are multiple matchers in progress it should associate with the nearest/innermost, i.e. shortest = most recently started (e.g. consider nested `if…then…` expressions); it does smell though
        }
        
       // print("Resuming CONJUNCTION matcher from \(resumeIndex):", parentMatch); print("\t…",  self.tokenStack[resumeIndex])
        
        // self.tokenStack.show(self.tokenStack.count - parentMatch.count)
        
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
        self.blockStack.end(conjunction: name) // TO DO: don’t _think_ the order of this relative to EXPR reduction is signifcant, but make sure
        //print("Removed matched conjunction from block stack:", name)
        // reduce the preceding EXPR
        let startIndex = matchIndex + 1
        let stopIndex = self.tokenStack.count
        //print("REDUCING EXPR before conjunction: .\(name) from", startIndex, "to", stopIndex, self.tokenStack[startIndex])
        //print("---")
        self.fullyReduceExpression(from: startIndex, to: stopIndex) // start..<stop
        // TO DO: now the reduced EXPR is on stack, we ought to fully match it to be sure [but this applies to pattern-driven reductions in general]
        
        
       // print()
       // for m in self.tokenStack.last!.matches {print("\t\t",m)}
       // print("HED:", self.tokenStack.last!.form); for m in self.tokenStack.last!.matches {print("\t\t",m)}
       // print()
        
        self.shift() // shift the conjunction onto stack (note: this does not add remaining conjunctions to blockStack; that is done below) // TO DO: should it? the logic should be similar for new and in-progress matches
        
        //print("SHIFTED conjunction onto token stack:", self.tokenStack.last!.form)
        //print("***"); self.blockStack.show()
        
        // check if this pattern still conjunctions to match (i.e. the previous matchers should have been matched to the EXPR on the stack and are now waiting to match the conjunction)
        
        let remainingConjunctions = self.tokenStack.last!.matches.filter{$0.originID == parentMatch.originID}.flatMap{$0.next()}.filter{!$0.conjunctions.isEmpty} // get matchers for token after newly-shifted conjunction (if any) to see if there further conjunctions still to match (e.g. `if…then…else…` operator has two conjunctions to match, the second of which is optional)
         //print("REMAINING CONJUNCTIONS: ", remainingConjunctions)
        if !remainingConjunctions.isEmpty {
            let stopIndex = self.tokenStack.count
            var conjunctions = Conjunctions()
            for match in remainingConjunctions {
                conjunctions[name] = [(match, stopIndex)]
            }
            self.blockStack.begin(.conjunction(conjunctions))
        }
        // print(); print("<<<<"); self.blockStack.show(); print(); print("-------------")
    }
    
    
    
    
}
