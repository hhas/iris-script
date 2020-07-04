//
//  expression reduce.swift
//  iris-script
//

import Foundation


extension Parser {
    
    
    func reduceExpressionBeforeConjunction(matchedBy matchers: [PatternMatch]) {
        // called by parser before shifting a conjunction keyword onto stack to reduce the EXPR that precedes it
        // `matchers` argument is from the head of the blockMatchers stack (used to track nesting)
        let parentMatch: PatternMatch
        if matchers.count == 1 {
            parentMatch = matchers[0]
        } else {
            parentMatch = matchers.min{ $0.count < $1.count }! // confirm this logic; if there are multiple matchers in progress it should associate with the nearest/innermost, i.e. shortest = most recently started (e.g. consider nested `if…then…` expressions); it does smell though
        }
        // print("REDUCE CONJ:")
        // self.stack.show(self.stack.count - parentMatch.count)
        
        // TO DO: this is all rather kludgy; need to decide what to do in even of overloaded matches
        
        
        // TO DO: what if this reduction fails?
        
        
        // TO DO: merge reduceExpressionBeforeConjunction(…) funcs into one?
        // note: matching a conjunction keyword forces reduction of the preceding expr; in the event that the operator is nested (e.g. `if test then if test then action`) the caller uses Parser.blockMatches stack to track [potentially nested] in-progress operator matches currently waiting for their conjunction to appear, pairing up the closest, i.e. innermost, pair of primary and conjunction keywords first (thus:  `if test then if test then action` -> `if test then (if test then action)` -> `(if test then (if test then action))`)
        let matchID = parentMatch.uniqueID // find nearest
        // find the partial match to which this conjunction keyword belongs (e.g. the partial `if EXPR…` match); this must be earlier in the same expression otherwise a syntax error will occur
        // note that a stray conjunction (i.e. one which is not preceded by the operator’s primary keyword, e.g. `notif test then action`) will not trigger reduceExpressionBeforeConjunction(:…)
        // TO DO: not quite sure why this back-search doesn't find the `if EXPR…` matcher to which this `then` belongs, despite it being in a different expression (i.e. it still has access to the entire parser stack, not just the subrange for the current EXPR)
        if let matchIndex = self.stack.lastIndex(where: { $0.matches.contains{ $0.uniqueID == matchID } }) {
            let startIndex = matchIndex + 1
            let stopIndex = self.stack.count
            //print("FULLY REDUCING EXPR before conjunction: .\(conjunction)…")
            self.fullyReduceExpression(from: startIndex, to: stopIndex) // start..<stop
        } else {
            // the matcher to which this conjunction belongs lies in an earlier (i.e. unrelated) expression; e.g. given the code `if 1, then 2`, the parser fails to fully match `if…then…` due to the delimiter after the test EXPR, pushing the unreduced `if 1` onto stack as a Syntax Error instead; then, upon encountering `then 2` in a subsequent expression, it lands here when it is unable to locate the earlier partial `if EXPR` match to which the `then` conjunction belongs
            let e = InternalError(description: "Syntax Error: Found `\(parentMatch.definition.name.label)` conjunction but the operator to which it belongs is not in the same expression.")
            self.stack.replace(from: self.stack.count - 1, to: self.stack.count, withReduction: .error(e))
        }
        // print("…TO:", self.stack.dump(self.stack.count-1))
        
        
        
        
        
        let remainingConjunctions = self.stack.last!.matches.flatMap{$0.next()}.flatMap{$0.conjunctions} // get matchers for token after newly-shifted conjunction (if any) to see if there further conjunctions still to match (e.g. `if…then…else…` operator has two conjunctions to match, the second of which is optional)
        // print("REMAINING: ", remainingConjunctions, parentMatch.next())
        if remainingConjunctions.isEmpty {
            
            
            // TO DO: we could probably use an API for wrangling keywords vs symbols
            
            // TO DO: sort out logic for removing .conjunction once the matcher that spawned it has reduced
            
            if case .conjunction(var c) = self.blockMatchers.last {
                // print("REMOVED", self.blockMatchers.last ?? .record)
                //      c.removeValue(forKey: T##Symbol) // TO DO: finish
                self.blockMatchers.removeLast()
            }
        } else {
            var conjunctions = [Symbol: [PatternMatch]]()
            for name in remainingConjunctions {
                conjunctions[name] = [parentMatch]
            }
            // print("READDED", conjunctions)
            self.blockMatchers.replaceLastItem(with: .conjunction(conjunctions))
            
            //   print()
            //   print(self.stack.last!)
            //   print(self.blockMatchers)
            //   print()
        }
    }
    
    
    
    
    
    
    
    
    func reductionForOperatorExpression(from startIndex: Int, to stopIndex: Int) -> Token.Form? { // start..<stop
        // reduces an expression composed of one or more operations (this includes unreduced nested commands for which matchers have been added, but not LP commands which must be custom-reduced beforehand)
        // important: any commands within the expression must already be reduced to .value(Command(…))
        if startIndex == stopIndex - 1 {
            switch self.stack[startIndex].form {
            case .value(let v):
                return .value(v)
            case .error(let e):
                return .value(BadSyntaxValue(error: e)) // TO DO: where should .error transform to error value?
            default: ()
            }
        }
        //print("reductionForOperatorExpression:"); self.stack.show(startIndex, stopIndex)
        var matches = self.stack.findLongestFullMatches(from: startIndex, to: stopIndex)
        //for m in matches { print("Longest ", m) }
        if matches.isEmpty { // note: this is empty when e.g. `do` keyword is followed by delimiter (since `do` is not an atom but part of a larger `do…done` block that spans multiple expressions, it should not be reduced at this time); we still go through the find-longest step in case there are completed pattern matchers available
            
            return nil
            
            // if startIndex == stopIndex - 1 { // TO DO: is there any situation where there’d be >1 token here that isn’t a syntax error?
            //      return self.stack[startIndex].form
            //  }
            //  return .value(BadSyntaxValue(error: InternalError(description: "Can't fully reduce \(startIndex)..<\(stopIndex) as no full matches found: \(self.stack.dump(startIndex, stopIndex))"))) // TO DO: BadSyntaxValue should always take stack and start+stop indexes and store its own copy of that array slice (may be used in generating syntax error descriptions and, potentially, making corrections in place [this'd need BadSyntaxValue class to delegate all Value operations to a private `Value?` var])
        }
        if matches[0].start != startIndex {
            // TO DO: this may also be due to syntax error, e.g. "if 1 + 2 = 3, 4 then 6, 8, 9." -> Missing first matcher[s] for 0...1
            print("\nBUG: Missing first matcher[s] for \(startIndex)...\(matches[0].start)")
            print(matches[0])
        }
        if matches.last!.stop != stopIndex-1 {print("BUG: Missing last matcher[s] for \(matches.last!.stop)...\(stopIndex-1)")}
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
                case .right: // right expr is prefix/infix operation
                    // print("REDUCE RIGHT MATCH", right.match.name)
                    matches.reduceMatch(at: rightExpressionIndex)
                }
            } else { // e.g. `… POSFIX_OP PREFIX_OP …`
                // TO DO: this also happens if a completed operator match is missing from matches array due to a bug in [e.g.] findLongestMatches()
                // print("no shared operand:\n\n\tLEFT MATCH \(left.start)...\(left.stop):", left.match, "\n\t", left.tokens.map{".\($0.form)"}.joined(separator: "\n\t\t\t "), "\n\n\t RIGHT MATCH \(right.start)...\(right.stop)", right.match, "\n\t\t", right.tokens.map{".\($0.form)"}.joined(separator: "\n\t\t\t "), "\n")
                // TO DO: need to fully reduce right expr[s], move result to stack, remove that matcher and reset indices, then resume
                //   fatalError("TO DO: non-overlapping expressions, e.g. `1+2 3+4`, or missing [e.g. incomplete] match") // pretty sure `EXPR EXPR` is always a syntax error (with opportunities to suggest corrections, e.g. by inserting a delimiter)
                
                // TO DO: should we try to reduce as much as possible before returning partially reduced result in BadSyntaxValue, or should we return BadSyntaxValue straightaway containing the original range of unreduced tokens? (need to work out API for BadSyntaxValue; i.e. what should parser provide it with to enable it to generate meaningful error descriptions and [potentially] suggest corrections which may be applied and reduced in-place) (ability to define pattern matchers for detecting common syntax errors may of help here; e.g. `EXPR EXPR` may result from missing/wrong operator [e.g. user intended an infix operator but parser only found prefix/postfix/atom definitions], or from missing .delimiter)
                
                return .value(BadSyntaxValue(error: InternalError(description: "Found two adjacent expressions at \(leftExpressionIndex)...\(rightExpressionIndex): \(left.tokens.map{".\($0.form)"}) \(right.tokens.map{".\($0.form)"})")))
            }
            //matches.show() // DEBUG
            if rightExpressionIndex == matches.count { // adjust indexes for shortened matches array as needed
                leftExpressionIndex -= 1
                rightExpressionIndex -= 1
            }
        }
        assert(matches.count == 1)
        return matches[0].tokens.reductionFor(fullMatch: matches[0].match) // TO DO: reductionFor(fullMatch:) returns either .value or .error; can/should we change this to Value, in which case reductionForOperatorExpression(…) can return `Value?` rather than `Token.Form?`
    }
    
    
    
    func fullyReduceExpression(from _startIndex: Int = 0, to stopIndex: Int? = nil) { // starting point for reductions called by main loop
        var stopIndex = stopIndex ?? self.stack.count // caution: stopIndex is nearest head of stack, so will no longer be valid once a reduction is performed
        //  print("fullyReduceExpression:"); self.stack.show(_startIndex, stopIndex)
        // scan back from stopIndex until an expression delimiter is found or original startIndex is reached; that then becomes the startIndex for findLongestMatches // TO DO: is this still needed? currently when fullyReduceExpression is called, how is the _startIndex argument determined?
        var startIndex = self.stack.findStartIndex(from: _startIndex, to: stopIndex)
        //  print("…found startIndex", startIndex)
        
        if startIndex == stopIndex { return } // zero length, e.g. `[ ]`
        
        // if the token range starts with a label, leave it and only reduce the expr after it; this may be a bit kludgy, but fingest crossed it solves the problem well enough to proceed as `LABEL EXPR` should only [currently?] appear in two places: after an LP command name and in a record field, and in first case we want findStartIndex to skip over labels (which are always preceded by at least one token) while in the second the label, if present, is always the first token in found range (which is what the next line ignores), and the record literal’s reducefunc eventually takes care of it // TO DO: if we allow `LABEL EXPR` for name-value bindings in blocks, how will this affect parsing/matching
        if startIndex < stopIndex, case .label(_) = self.stack[startIndex].form {
            startIndex += 1
        }
        // reduce all commands within the specified range in-place, decrementing stopIndex on return by the number of tokens removed during this reduction
        // (note that nested commands are not immediately reduced here but are instead tagged with matchers that will reduce them during reductionForOperatorExpression() as if they were atom/prefix operators of predetermined precedence; also note that full-punctuation commands, i.e. `NAME RECORD`, have already been reduced to .value(Command(…)) by the parser's main loop so are not touched again here)
        self.reduceCommandExpressions(from: startIndex, to: &stopIndex)
        // once all commands’ boundaries have been determined and the commands themselves reduced to .values, reduce all operators
        
        // kludgy: upon reducing the expression, make sure any completed conjunction-based matches are removed from Parser.blockMatchers; frankly this is a mess: the logic for popping completed blocks off blockMatchers is all over the place
        //   print(">>>",self.blockMatchers)
        let fullyMatchedGroupIDs = self.stack[startIndex..<stopIndex].flatMap{$0.matches}.filter{$0.isAFullMatch}.map{$0.groupID}
        //print("removing group ids", fullyMatchedGroupIDs)
        if case .conjunction(let matchers) = self.blockMatchers.last {
            var matchers = matchers
            for (k, v) in matchers {
                // print(k, v.map{$0.groupID})
                let v = v.filter{!fullyMatchedGroupIDs.contains($0.groupID)}
                if v.isEmpty {
                    matchers.removeValue(forKey: k)
                } else {
                    matchers[k] = v
                }
            }
            if matchers.isEmpty {
                //   print("NUKED",self.blockMatchers.last!)
                self.blockMatchers.removeLast()
            }
        }
        //   print("<<<",self.blockMatchers)
        if let form = self.reductionForOperatorExpression(from: startIndex, to: stopIndex) { // returns nil if no reduction was made (e.g. pattern is still being matched)
            //      print("REDUCED OPERATOR:"); self.stack.show(startIndex, stopIndex); print("…TO: .\(form)\n")
            self.stack.replace(from: startIndex, to: stopIndex, withReduction: form)
        }
    }
    
}
