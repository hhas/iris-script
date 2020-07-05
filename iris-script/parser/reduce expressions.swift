//
//  expression reduce.swift
//  iris-script
//

import Foundation


extension Parser {
    
    
    
    
    func reductionForOperatorExpression(from startIndex: Int, to stopIndex: Int) -> (Token.Form, Set<Int>)? { // start..<stop
        // reduces an expression composed of one or more operations (this includes unreduced nested commands for which matchers have been added, but not LP commands which must be custom-reduced beforehand)
        // important: any commands within the expression must already be reduced to .value(Command(…))
        var reducedMatchIDs = Set<Int>()
        if startIndex == stopIndex - 1 {
            switch self.tokenStack[startIndex].form {
            case .value(let v):
                return (.value(v), reducedMatchIDs)
            case .error(let e):
                return (.value(BadSyntaxValue(error: e)), reducedMatchIDs) // TO DO: where should .error transform to error value?
            default: ()
            }
        }
     //   print("reductionForOperatorExpression:"); self.tokenStack.show(startIndex, stopIndex)
        var matches = self.tokenStack.findLongestFullMatches(from: startIndex, to: stopIndex)
        //for m in matches { print("Longest ", m) }
        if matches.isEmpty { // note: this is empty when e.g. `do` keyword is followed by delimiter (since `do` is not an atom but part of a larger `do…done` block that spans multiple expressions, it should not be reduced at this time); we still go through the find-longest step in case there are completed pattern matchers available
            
            return nil
            
            // if startIndex == stopIndex - 1 { // TO DO: is there any situation where there’d be >1 token here that isn’t a syntax error?
            //      return self.tokenStack[startIndex].form
            //  }
            //  return .value(BadSyntaxValue(error: InternalError(description: "Can't fully reduce \(startIndex)..<\(stopIndex) as no full matches found: \(self.tokenStack.dump(startIndex, stopIndex))"))) // TO DO: BadSyntaxValue should always take stack and start+stop indexes and store its own copy of that array slice (may be used in generating syntax error descriptions and, potentially, making corrections in place [this'd need BadSyntaxValue class to delegate all Value operations to a private `Value?` var])
        }
        
        
        if matches[0].start != startIndex {
            // TO DO: this may also be due to syntax error, e.g. "if 1 + 2 = 3, 4 then 6, 8, 9." -> Missing first matcher[s] for 0...1
            // TO DO: how should we represent unmatched tokens at start/end?
            print("\nSyntax Error: Unmatched tokens at start of expression: \(startIndex)...\(matches[0].start)")
            print(matches[0])
        }
        if matches.last!.stop != stopIndex-1 {
            print("nSyntax Error: Unmatched tokens at end of expression: \(matches.last!.stop)...\(stopIndex-1)")
        }
        // starting from right end of specified stack range and comparing two adjacent operations at a time, scan left while both operators share a common operand and left operator has higher precedence than right; once found, reduce the higher-precedence operator; rinse and repeat until only one operator is left to reduce; note that this will also reduce nested commands as those had pattern matchers attached to them by reduceCommandExpressions (nested commands will reduce similar to atom or prefix operators, depending on what follows the command name: an infix/postfix operator, or a prefix operator/other expression)
        var rightExpressionIndex = matches.count - 1
        var leftExpressionIndex = rightExpressionIndex - 1
        while matches.count > 1 {
            //print("matches:", matches.map{ "\($0.start)-\($0.stop) `\($0.match.name.label)`" }.joined(separator: ", "))
            var left = matches[leftExpressionIndex], right = matches[rightExpressionIndex]
            var hasSharedOperand = left.stop >= right.start
            while leftExpressionIndex > 0 && hasSharedOperand && reductionOrderFor(left.match, right.match) == .left {
                leftExpressionIndex -= 1; rightExpressionIndex -= 1
                left = matches[leftExpressionIndex]; right = matches[rightExpressionIndex]
                hasSharedOperand = left.stop >= right.start
            }
            // left = matches[index+1], right = matches[index]
            // print("LEFT:", left, "\nRIGHT:", right, "\n", rightExpressionIndex)
            //print("hasSharedOperand:", hasSharedOperand, left.match.name, right.match.name)
            if hasSharedOperand {
                switch reductionOrderFor(left.match, right.match) {
                case .left: // left expr is infix/postfix operation
                    // print("REDUCE LEFT MATCH", left.match.name)
                    matches.reduceMatch(at: leftExpressionIndex)
                    reducedMatchIDs.insert(left.match.originID)
                case .right: // right expr is prefix/infix operation
                    // print("REDUCE RIGHT MATCH", right.match.name)
                    matches.reduceMatch(at: rightExpressionIndex)
                    reducedMatchIDs.insert(right.match.originID)
                }
            } else { // e.g. `… POSFIX_OP PREFIX_OP …`
                // TO DO: this also happens if a completed operator match is missing from matches array due to a bug in [e.g.] findLongestMatches()
                // print("no shared operand:\n\n\tLEFT MATCH \(left.start)...\(left.stop):", left.match, "\n\t", left.tokens.map{".\($0.form)"}.joined(separator: "\n\t\t\t "), "\n\n\t RIGHT MATCH \(right.start)...\(right.stop)", right.match, "\n\t\t", right.tokens.map{".\($0.form)"}.joined(separator: "\n\t\t\t "), "\n")
                // TO DO: need to fully reduce right expr[s], move result to stack, remove that matcher and reset indices, then resume
                //   fatalError("TO DO: non-overlapping expressions, e.g. `1+2 3+4`, or missing [e.g. incomplete] match") // pretty sure `EXPR EXPR` is always a syntax error (with opportunities to suggest corrections, e.g. by inserting a delimiter)
                
                // TO DO: should we try to reduce as much as possible before returning partially reduced result in BadSyntaxValue, or should we return BadSyntaxValue straightaway containing the original range of unreduced tokens? (need to work out API for BadSyntaxValue; i.e. what should parser provide it with to enable it to generate meaningful error descriptions and [potentially] suggest corrections which may be applied and reduced in-place) (ability to define pattern matchers for detecting common syntax errors may of help here; e.g. `EXPR EXPR` may result from missing/wrong operator [e.g. user intended an infix operator but parser only found prefix/postfix/atom definitions], or from missing .delimiter)
                // TO DO: need to check if EXPRs are immediately adjacent or if there are unmatched tokens between them and adjust message accordingly; see also TODOs above re. unmatched tokens at start/end
                return (.value(BadSyntaxValue(error: InternalError(description: "Found two adjacent expressions at \(leftExpressionIndex)...\(rightExpressionIndex): \(left.tokens.map{".\($0.form)"}) \(right.tokens.map{".\($0.form)"})"))), reducedMatchIDs)
            }
            //matches.show() // DEBUG
            if rightExpressionIndex == matches.count { // adjust indexes for shortened matches array as needed
                leftExpressionIndex -= 1
                rightExpressionIndex -= 1
            }
        }
        assert(matches.count == 1)
        reducedMatchIDs.insert(matches[0].match.originID)
        return (matches[0].tokens.reductionFor(fullMatch: matches[0].match), reducedMatchIDs) // TO DO: reductionFor(fullMatch:) returns either .value or .error; can/should we change this to Value, in which case reductionForOperatorExpression(…) can return `Value?` rather than `Token.Form?`
    }
    
    
    
    func fullyReduceExpression(from _startIndex: Int = 0, to stopIndex: Int? = nil) { // starting point for reductions called by main loop
        var stopIndex = stopIndex ?? self.tokenStack.count // caution: stopIndex is nearest head of stack, so will no longer be valid once a reduction is performed
        // scan back from stopIndex until an expression delimiter is found or original startIndex is reached; that then becomes the startIndex for findLongestMatches // TO DO: is this still needed? currently when fullyReduceExpression is called, how is the _startIndex argument determined?
        var startIndex = self.tokenStack.findStartIndex(from: _startIndex, to: stopIndex)
        //  print("…found startIndex", startIndex)
       // print("fullyReduceExpression:"); self.tokenStack.show(startIndex, stopIndex)
        
        if startIndex == stopIndex { return } // zero length, e.g. `[ ]`
        
        // if the token range starts with a label, leave it and only reduce the expr after it; this may be a bit kludgy, but fingest crossed it solves the problem well enough to proceed as `LABEL EXPR` should only [currently?] appear in two places: after an LP command name and in a record field, and in first case we want findStartIndex to skip over labels (which are always preceded by at least one token) while in the second the label, if present, is always the first token in found range (which is what the next line ignores), and the record literal’s reducefunc eventually takes care of it // TO DO: if we allow `LABEL EXPR` for name-value bindings in blocks, how will this affect parsing/matching
        if startIndex < stopIndex, case .label(_) = self.tokenStack[startIndex].form {
            startIndex += 1
        }
        
        // reduce all commands within the specified range in-place, decrementing stopIndex on return by the number of tokens removed during this reduction
        // (note that nested commands are not immediately reduced here but are instead tagged with matchers that will reduce them during reductionForOperatorExpression() as if they were atom/prefix operators of predetermined precedence; also note that full-punctuation commands, i.e. `NAME RECORD`, have already been reduced to .value(Command(…)) by the parser's main loop so are not touched again here)
        self.reduceCommandExpressions(from: startIndex, to: &stopIndex)
        // once all commands’ boundaries have been determined and the commands themselves reduced to .values, reduce all operators
        
        self.blockStack.endConjunctionMatches() // discard any pending conjunctions, e.g. given `if TEST then ACTION.`, this will discard the `else` clause upon encountering period delimiter; note that if an operator has >1 conjunction, reduceExpressionBeforeConjunction() will add a new entry to blockStack after it’s shifted the first conjunction // TO DO: check this doesn't interfere with do…done (it’s overly aggressive in what it removes from stack; it should only remove conjunctions whose matchers started within the current EXPR)
        
        //   print("<<<",self.blockStack)
        if let (form, reducedMatchIDs) = self.reductionForOperatorExpression(from: startIndex, to: stopIndex) { // returns nil if no reduction was made (e.g. pattern is still being matched)
          //  print("REDUCING OPERATOR:"); self.tokenStack.show(startIndex, stopIndex); print("…TO: .\(form)\n\n----\n\n")
            self.tokenStack.replace(reducedMatchIDs: reducedMatchIDs, from: startIndex, to: stopIndex, withReduction: form)
          // print("REDUCED OPERATOR:"); self.tokenStack.show(startIndex); print("…TO: .\(form)\n\n----\n\n")
        }
    }
    
}
