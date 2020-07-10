//
//  expression reduce.swift
//  iris-script
//

import Foundation


extension Parser {
    
    
    // starting from end of a range of tokens, search backwards to find a left-hand expression delimiter; called by Parser.reduceExpression()
    // TO DO: when parsing exprs, what about remembering the index of each expr’s left-hand boundary, avoiding need to back-scan for it each time? (since exprs can be nested, this'd need another stack similar to blockStack) [this is low-priority as this implementation, while crude, does the job]
    fileprivate func findStartIndex(from startIndex: Int, to stopIndex: Int) -> Int { // start..<stop
        // caution: when finding the start of a record field, the resulting range *includes* the field's `.label(NAME)`; e.g. when parsing `{foo: EXPR, EXPR, bar: EXPR}`, the indexes of the opening `{` and two `,` tokens are returned; leaving the caller to process `foo: EXPR` and `bar: EXPR`
        
        let index: Int
        if let i = self.tokenStack[startIndex..<stopIndex].lastIndex(where: { $0.form.isLeftExpressionDelimiter }) {
            index = i + 1 // `i` is the delimiter token; the current expression starts on the token after it
        } else {
            index = startIndex
        }
       // print("findStartIndex:", startIndex..<stopIndex, "expr start", index, "block delim:", self.blockStack.leftDelimiterIndex + 1)
       // return index
        return Swift.max(index, self.blockStack.leftDelimiterIndex + 1)
    }
    
    
    func reduceExpressionBeforeConjunction(_ name: Symbol, matchedBy matchers: ConjunctionMatches) {
        // called by parser before shifting a conjunction keyword onto stack to reduce the EXPR that precedes it
        // note: matching a conjunction keyword forces reduction of the preceding expr; in the event that the operator is nested (e.g. `if test then if test then action`) the caller uses Parser.blockMatches stack to track [potentially nested] in-progress operator matches currently waiting for their conjunction to appear, pairing up the closest, i.e. innermost, pair of primary and conjunction keywords first (thus:  `if test then if test then action` -> `if test then (if test then action)` -> `(if test then (if test then action))`)
        // TO DO: since matchers comes directly from BlockStack’s head .conjunction(…), which in turn corresponds to a single .operatorName(…) token, it will usually contain a single PatternMatch instance stored under one or more names (depending on whether the conjunction keyword includes aliases); occasionally there will be >1 matcher if the primary keyword is overloaded, e.g. `repeat…while…` vs `repeat…until…`; that said, since conjunction matching is greedy, the first conjunction found wins and the rest should be discarded (based on groupID)
        let parentMatch: PatternMatch
        let precedingKeywordIndex: Int
        if matchers.count == 1 {
            (parentMatch, precedingKeywordIndex) = matchers[0]
        } else {
            (parentMatch, precedingKeywordIndex) = matchers.min{ $0.match.count < $1.match.count }! // confirm this logic; if there are multiple matchers in progress it should associate with the nearest/innermost, i.e. shortest = most recently started (e.g. consider nested `if…then…` expressions); it does smell though
        }
        // remove the currently matched (though not yet shifted) conjunction from block stack
        self.blockStack.end(name) // TO DO: don’t _think_ the order of this relative to EXPR reduction is signifcant, but make sure
        // reduce the preceding EXPR
        let startIndex = precedingKeywordIndex + 1
        let stopIndex = self.tokenStack.count
       // print("Reducing EXPR before conjunction \(name) at \(startIndex)..<\(stopIndex)")
        self.reduceExpression(from: startIndex, to: stopIndex) // start..<stop
        // TO DO: now the reduced EXPR is on stack, we ought to fully match it to be sure [but this applies to pattern-driven reductions in general]
        self.shift() // shift the conjunction onto stack (note: this does not add remaining conjunctions to blockStack; that is done below) // TO DO: should it? the logic should be similar for new and in-progress matches
        // check if this pattern still conjunctions to match (i.e. the previous matchers should have been matched to the EXPR on the stack and are now waiting to match the conjunction)
        let remainingConjunctions = self.tokenStack.last!.matches.filter{$0.originID == parentMatch.originID}.flatMap{$0.next()}.filter{!$0.conjunctions.isEmpty} // get matchers for token after newly-shifted conjunction (if any) to see if there further conjunctions still to match (e.g. `if…then…else…` operator has two conjunctions to match, the second of which is optional)
        if !remainingConjunctions.isEmpty {
            let stopIndex = self.tokenStack.count
            self.blockStack.awaitConjunction(for: remainingConjunctions, at: stopIndex)
        }
    }
    
    
    func reduceIfPrecedingExpression() { // called before shifting punctuation/linefeed delimiter token
        
        //print("reduceIfPrecedingExpression:", self.blockStack.leftDelimiterIndex, self.tokenStack.count)
        
        if self.blockStack.leftDelimiterIndex == self.tokenStack.count - 1 {
            return
        }
        self.reduceExpression()
    }
    
    
    func reduceExpression(from startIndex: Int = 0, to stopIndex: Int? = nil) { // starting point for reductions called by main loop
        var stopIndex = stopIndex ?? self.tokenStack.count // caution: stopIndex is nearest head of stack, so will no longer be valid once a reduction is performed // TO DO: return new stopIndex via inout?
        // scan back from stopIndex until a left-hand expression delimiter is found or original startIndex is reached
        // TO DO: track expression start indexes on (block?) stack, avoiding need to iterate backwards here
        var expressionStartIndex = self.findStartIndex(from: startIndex, to: stopIndex)
        if expressionStartIndex == stopIndex { // kludgy (extra .linebreak at end of script [see line reader TODOs] causes unnecessary 'reduce expr before delim', which ends up cutting off here; there may be other cases where reduceExpression is called unnecessarily/inappropriately)
           // print("reduceExpression: ignoring zero-length EXPR at \(expressionStartIndex) in \(startIndex..<stopIndex)")
            //self.tokenStack.show()
            return
        } // zero length, e.g. `[ ]`
        // if the token range starts with a label, step over it and only reduce the expr after it; this is kludgy, but should do for now as `LABEL EXPR` currently only appears in two places: after an LP command name (which reduceLowPunctuationCommand deals with separately) and in a record field where the label, if present, is always the first token in found range (which is what the next line steps over, leaving the reducefunc to deal with) // TO DO: if we also allow `LABEL EXPR` for name-value bindings in blocks, how will this affect parsing/matching? (we might consider limiting other usage to AS-style `property NAME:EXPR` declarations, though as an expression it may be tricky limiting its appearance to certain [non-handler] scopes)
        if expressionStartIndex < stopIndex, case .label(_) = self.tokenStack[expressionStartIndex].form {
            expressionStartIndex += 1
        }
        
        // reduce all commands within the specified range in-place, decrementing stopIndex on return by the number of tokens removed during this reduction
        // (note that nested commands are not immediately reduced here but are instead tagged with matchers that will reduce them during reductionForOperatorExpression() as if they were atom/prefix operators of predetermined precedence; also note that full-punctuation commands, i.e. `NAME RECORD`, have already been reduced to .value(Command(…)) by the parser's main loop so are not touched again here)
        self.reduceCommandExpressions(from: expressionStartIndex, to: &stopIndex)
        // once all commands’ boundaries have been determined and the commands themselves reduced to .values, reduce all operators
        
        
        // TO DO: FIX: this interferes with e.g. do…done - it’s overly aggressive in what it removes from stack; it should only remove conjunctions whose matchers started within the current EXPR; that's not right either, e.g. given `if test then do, … done`, the comma should not terminate `do`; the problem is operators that have optional/trailing expr (i.e. no explicit terminator) need to be terminated by delimiters, but not blocks
        
        self.blockStack.endConjunctions() // discard any pending conjunctions, e.g. given `if TEST then ACTION.`, this will discard the `else` clause upon encountering period delimiter; note that if an operator has >1 conjunction, reduceExpressionBeforeConjunction() will add a new entry to blockStack after it’s shifted the first conjunction
        
        //   print("<<<",self.blockStack)
        //self.tokenStack.show(expressionStartIndex, stopIndex)
        self.tokenStack.reduceOperatorExpression(from: expressionStartIndex, to: &stopIndex)
        //print("REDUCED EXPRESSION:", self.tokenStack[expressionStartIndex].form)
        //self.tokenStack.show(expressionStartIndex, stopIndex)
    }
    
}
