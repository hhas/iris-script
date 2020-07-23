//
//  parser stacks.swift
//  iris-script
//
//  extends the `Array<StackInfo>` type used in `Parser.tokenStack` (and `FullMatch.tokens`) with methods for searching and reducing shifted tokens
//
//  extends the `Array<BlockInfo>` type used in `Parser.blockStack`
//
//  extends the `Array<FullMatch>` type used in `Parser.reduceOperatorExpression()`
//

import Foundation

// TO DO: avoid using startIndex/endIndex as names as those are already defined on Array

// Parser’s token stack

extension Array where Element == Parser.TokenInfo {
    
    // DEBUG: list stack tokens + their associated partial/complete matchers
    
    func show(_ startIndex: Int = 0, _ stopIndex: Int? = nil) { // startIndex..<stopIndex
        print(self.dump(startIndex, stopIndex))
    }
    
    func dump(_ startIndex: Int = 0, _ stopIndex: Int? = nil) -> String { // startIndex..<stopIndex
        let stopIndex = stopIndex ?? self.count
        return "Stack[\(startIndex)..<\(stopIndex)]:\n"
            + self[startIndex..<(stopIndex)].enumerated().map{"\($0+startIndex))\t.\($1.form) \($1.matches.map{ "\n\t\t\t\t\($0)"}.joined(separator: ""))"
            }.joined(separator: "\n")
    }
    
    // used by Parser.reduceLowPunctuationCommand() to disambiguate ambigious overloaded operators (e.g. `+`, `-`) according to their surrounding whitespace
    
    //    func hasLeadingWhitespace(at index: Int) -> Bool {
    //        return self[index].hasLeadingWhitespace
    //    }
    //    func hasTrailingWhitespace(at index: Int) -> Bool {
    //        return index+1 < self.count && self[index+1].hasLeadingWhitespace
    //    }
    func hasBalancedWhitespace(at index: Int) -> Bool { // TO DO: what about `foo- 1`? currently this treats it as imbalanced so parses as `foo {-1}`, but it could do with a warning (or else treat it as syntax error) as it can’t be automatically determined if whitespace is missing or transposed
        // if this is last token, whitespace is _always_ imbalanced (i.e. false); this shouldn’t matter as operator is either postfix or missing a right operand (existing parsing behavior will determine which)
        return index+1 < self.count && self[index].hasLeadingWhitespace == self[index+1].hasLeadingWhitespace
    }
    
    //
    
    // called by reduce(leftMatch:from:onto:stopIndex:found:) to find the right-hand match against which to compare leftMatch (in well-formed code, left and right matches overlap at a common operand); returns the match and the index at which it ends (i.e. right index is INclusive), or nil if no match found
    fileprivate func nextFullMatch(from index: Int, stopIndex: Int, found: inout Set<Int>) -> (PatternMatch, Int)? {
        // expression’s first token should appear at index and last token before stopIndex
        // note: can't use isBeginningOfMatch as we've overwritten new matches with their full version, so keep set of already found IDs
        //print("nextFullMatch:", index, stopIndex, self[index].form, self[index].matches)
        assert(index < stopIndex)
        // TO DO: how should this deal with conflicting matches?
        let matches = self[index].matches.filter{ !found.contains($0.groupID) }
        // check for single-token matches, e.g. `bar` in `foo bar of 1` (at this point, the only single-token matches should be nested commands that don’t have a direct argument); if there isn’t a longer full version of that match then return it so that it is reduced next
        // e.g. given the `bar of 1` subexpression from above, `bar` must be reduced before the longer `…of…` operation can reduce (`bar of 1` ➞ `bar{} of 1` ➞ `of{bar{},1}`), i.e. this is an exception to the "longest match wins" rule below
        if let match = matches.first(where: { $0.count == 1 }),
            !matches.contains(where: { $0.groupID == match.groupID && $0.count > 1 }) {
            found.insert(match.groupID)
            return (match, index)
        }
        // if there is >1 full match starting on this token, use the longest match and discard others; e.g. given a full `if TEST then EXPR1 else EXPR2` match, this discards the shorter `if TEST then EXPR1` version of that match // TO DO: what if matches contains unrelated matches spawned from >1 patterns (i.e. different origin IDs); we still [correctly?] discard the shorter matches, but should we warn of potentially conflicting operator definitions? what if using the longest match results in the following tokens failing to match, whereas using the shorter match allows another pattern to match the remaining tokens? e.g. given the tokens `… OP1 OP2 …`, if OP1 is postfix or infix and OP2 is infix only, `… infix OP2 …` will fail to fully match whereas `… postfix infix …` will - TO DO: build test cases and see what happens, then decide how best to handle (e.g. given a failure to match, the parser could backtrack to an earlier token where there was >1 full match and retry from there using the next-longest match)
        //     if (self[index].matches.filter{ !found.contains($0.uniqueID) }.count > 1) {print("DEBUG: >1 match begins at \(index); will use longest.") //; self.show(index, index+1)}
        if let match = matches.max(by: { $0.count < $1.count }) {
            found.insert(match.groupID)
            let rightIndex = index + match.count - 1 // right index is INclusive
            // print("…nextFullMatch found a \(match.count)-token match for \(match.definition.precis) at \(index...rightIndex) (stop: \(stopIndex), stack: \(self.count)): \(match)");self.show();print()
            assert(!(rightIndex > stopIndex), "BUG: end of match (\(rightIndex)) is outside allowed range \(index..<stopIndex): \(match)") // this should never fail as reduceOperatorExpression’s first-stage filtering only finds full matches that end before stopIndex
            return (match, rightIndex)
        } else { // end of EXPR
            if index != stopIndex - 1 {
                // TO DO: this smells
                //print("…nextFullMatch: no matches at \(index). (stop: \(stopIndex), size: \(self.count))");self.show(index, stopIndex)
            }
            return nil
        }
        
    }
    
    
    // recursively reduces a contiguous sequence of fully-matched operators in order of precedence
    // caution: this method makes working changes to token stack without affecting its length (the final replacement is made by reduceOperatorExpression once this method returns) // TO DO: in event this function errors, what to do with partially modified token stack? (it might be better to work on a copy)
    fileprivate mutating func reduce(leftMatch: PatternMatch, from leftIndex: Int, onto commonIndex: Int, stopIndex: Int, found: inout Set<Int>) throws -> (Token.Form, Int) { // returns start index of last match made, plus the new rightmost index (INclusive) of the expression that was read (upon final return this will be same as stopIndex-1 unless there is a syntax error preventing the expression being read to its end); commonIndex is the token at which two patterns overlap; thus leftIndex...commonIndex and commonIndex..<rightIndex
        if let (rightMatch, rightIndex) = self.nextFullMatch(from: commonIndex, stopIndex: stopIndex, found: &found) {
            assert(rightIndex <= stopIndex)
            //print("PRECEDENCE", leftMatch, rightMatch, reductionOrderFor(leftMatch, rightMatch))
            assert(leftMatch.groupID != rightMatch.groupID) // e.g. `…+…` vs `+…`
            switch reductionOrderFor(leftMatch, rightMatch) {
            case .left: // reduce left match then right match
                let firstForm = try leftMatch.reductionFor(stack: self, startIndex: leftIndex)
                self[commonIndex].form = firstForm
                let (secondForm, newRightIndex) = try self.reduce(leftMatch: rightMatch, from: commonIndex, onto: rightIndex, stopIndex: stopIndex, found: &found)
                self[leftIndex].form = secondForm
                self[newRightIndex].form = secondForm
                return (secondForm, newRightIndex)
            case .right: // reduce right match then left match
                let (firstForm, newRightIndex) = try self.reduce(leftMatch: rightMatch, from: commonIndex, onto: rightIndex, stopIndex: stopIndex, found: &found)
                self[commonIndex].form = firstForm
                let secondForm = try leftMatch.reductionFor(stack: self, startIndex: leftIndex)
                self[leftIndex].form = secondForm
                self[newRightIndex].form = secondForm
                return (secondForm, newRightIndex)
            }
        } else { // no right match to compare (either we’ve reached the expression’s rightmost operation or we’ve reduced the expression down to its last operator) so reduce left match
            let form = try leftMatch.reductionFor(stack: self, startIndex: leftIndex)
            self[leftIndex].form = form
            self[commonIndex].form = form
            return (form, commonIndex)
        }
    }
    
    //
    
    // replace the specified token sequence with its reduction, updating any in-progress matches
    // used here (when reducing operators) and by `reduce commands.swift`
    mutating func replace(from startIndex: Int, to stopIndex: Int? = nil, withReduction form: Token.Form) { // start..<stop
        let stopIndex = stopIndex ?? self.count
        //assert(startIndex < stopIndex, "BUG: trying to reduce zero tokens at \(startIndex); reduceExpression should have already checked if an expr exists between delimiters and returned immediately if none found (e.g. in empty list/record/group).")
        //print("REPLACING", startIndex..<stopIndex, "with .\(form)"); self.show()
        // in-place expr reductions mean that the first token of range no longer has in-progress matches attached to it; in practice this suits us as we want now to confirm that in-progress matches, which previously only provisionally matched the first token of this range, now fully match its reduction
        // TO DO: we still need to test to confirm this doesn't mess with punctuation-based blocks, keyword-based blocks, and operators with conjunctions
        let matches: [PatternMatch]
        if startIndex > 0 { // redo any in-progress matches from preceding token (this time fully, not just provisionally)
            matches = self[startIndex-1].matches.flatMap{$0.next()}.filter{$0.fullyMatches(form:form)}
        } else {
            matches = []
        }
        //print("REPLACED", form, matches)
        let reduction: Parser.TokenInfo = (form, matches, self[startIndex].hasLeadingWhitespace)
        self.replaceSubrange(startIndex..<stopIndex, with: [reduction])
    }
    
    
    // reduce fully matched operations in the given range; on return, stopIndex is decremented by the number of tokens removed from stack
    
    mutating func reduceOperatorExpression(from startIndex: Int, to stopIndex: inout Int) {
        // a single .value probably[?] won’t have a full match attached to it, so return it immediately as no further reduction is required
        if startIndex == stopIndex - 1, case .value(_) = self[startIndex].form,
            !self[startIndex].matches.contains(where: { $0.isAFullMatch }) { return } // TO DO: what if token is .error? (although we should probably be boxing errors as `.value(SyntaxErrorDescription)` upstream)
        // in a well-matched expression, the last token of one operation is also the first token of the next; thus to determine which full matches to reduce (longest first) and which to ignore (shorter matches overlapped by longer ones), we start from left edge of expression and jump from one boundary to the next until we reach the right edge, and the only thing we need to do along the way is compare adjoining operations’ precedence to determine which to reduce first
        // to prepare the expression’s tokens on the stack (which we treat as an array slice) for performing these reductions, and working from right to left, remove partial matches and move each full match from end to start of its range
        var previousMatches = [(count: Int, pattern: PatternMatch)]()
        var index = stopIndex - 1
        while index >= startIndex {
            let fullMatches = self[index].matches.filter{ $0.isAFullMatch }
            previousMatches += fullMatches.map{ ($0.count, $0) }
            self[index].matches = []
            for (i, (count, pattern)) in previousMatches.enumerated().reversed() {
                // TO DO: check this doesn't cause problems with e.g. `if EXPR then EXPR ( else EXPR )?`
                if count == 1 {
                    previousMatches.remove(at: i)
                    self[index].matches.append(pattern)
                } else {
                    previousMatches[i].count = count - 1
                }
            }
            index -= 1
        }
        //print("---------", startIndex..<stopIndex); self.show(); print()
        //exit(1)
        // now, working from left to right and jumping from expression boundary to expression boundary, recursively search for the highest precedence expression and reduce that first, followed by next highest, and so on
        // to avoid shortening the stack after every reduction (more expensive and liable to off-by-one bugs), we replace the first _and_ last tokens of each operation with its reduction; once all reductions have been applied, the entire range is replaced with the final .value and stopIndex updated to reflect the reduced token range’s new length (1)
        index = startIndex
        var foundIDs = Set<Int>() // if a pattern has >1 match, ignore the shorter matches (iterating backwards encounters the longest match first, so we just store that full match’s ID and ignore subsequent matches with the same ID)
        var result = [Token.Form]()
        // given well formed code, this loop should iterate once then exit
        while index < stopIndex { // if code is well-formed this loop should execute once and exit, having reduced the entire expression to a single value; if any unmatched token sequences (syntax errors) are found it will repeat to collect them all and return as a single syntax error instance // TO DO: when reporting syntax error, should we reduce as much as possible and return that, or return the original unreduced token sequence? (attempting remaining reductions may infer user’s intent incorrectly whereas not reducing at all offers no help in guessing that intent)
            if let (leftMatch, commonIndex) = self.nextFullMatch(from: index, stopIndex: stopIndex, found: &foundIDs) { // check comparison
                do {
                    let (form, newRightIndex) = try self.reduce(leftMatch: leftMatch, from: index, onto: commonIndex, stopIndex: stopIndex, found: &foundIDs)
                    result.append(form) // get the final reduced value (or multiple values if there are missing matches due to syntax errors)
                    index = newRightIndex + 1 // step over last token matched by reducefunc
                    // TO DO: probably better to replace() here, adjusting stopIndex accordingly; avoids need for extra `result` accumulator
                } catch { // TO DO: handle error
                    result.append(.value(SyntaxErrorDescription("Failed match in reduceOperatorExpression: \(index), \(stopIndex)"))) // TO DO: better error message
                    index += 1
                }
            } else if index == stopIndex - 1, case .value(_) = self[index].form {
                result.append(self[index].form)
                index += 1
            } else {
                print("Missing last match in reduceOperatorExpression: \(index..<stopIndex), \(self[index])")
                self.show(index, stopIndex)
                result.append(.value(SyntaxErrorDescription("Missing last match in reduceOperatorExpression: \(index..<stopIndex)"))) // TO DO: better error message
                index += 1 //
            }
        }
        let form: Token.Form
        if result.count == 1 {
            form = result[0]
        } else {
            //print("Couldn’t reduce \(startIndex..<stopIndex): \(result)") // TO DO: reduce as SyntaxErrorDescription
            //self.show(startIndex, stopIndex); print()
            form = .value(SyntaxErrorDescription("Couldn’t fully reduce expression \(startIndex..<stopIndex): \(result)\n\n\(self.dump(startIndex, stopIndex))"))
        }
        self.replace(from: startIndex, to: stopIndex, withReduction: form)
        stopIndex = startIndex + 1
    }
    
    
    mutating func reduce(match: PatternMatch) -> Bool { // called by Parser.shift() when auto-reducing; this performs a normal SR reduction at head of stack; returns Bool flag indicating if reduction was performed //
        //print("AUTO-REDUCING", match)
        let stopIndex = self.count // non-inclusive
        let startIndex = stopIndex - match.count
        do {
            let form = try match.reductionFor(stack: self, startIndex: startIndex)
            self.replace(from: startIndex, to: stopIndex, withReduction: form)
            return true
        } catch { // TO DO: what to do with error?
            //  print("Reduction not performed at this time:", fullMatch)
            return false
        }
    }
}


