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


// Parser’s token stack

extension Array where Element == Parser.TokenInfo {
    
    // DEBUG: list stack tokens + their associated partial/complete matchers
    
    func show(_ startIndex: Int = 0, _ stopIndex: Int? = nil) { // startIndex..<stopIndex
        print(self.dump(startIndex, stopIndex))
    }
    
    func dump(_ startIndex: Int = 0, _ stopIndex: Int? = nil) -> String { // startIndex..<stopIndex
        let stopIndex = stopIndex ?? self.count
        return "Stack[\(startIndex)..<\(stopIndex)]:\n" + self[startIndex..<(stopIndex)].map{
            "\t.\($0.form) \($0.matches.map{ "\n\t\t\t\t\($0)" }.joined(separator: ""))"
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
    
    
    // starting from end of a range of tokens, search backwards to find a left-hand expression delimiter; called by Parser.fullyReduceExpression()
    // TO DO: when parsing exprs, what about remembering the index of each expr’s left-hand boundary, avoiding need to back-scan for it each time? (since exprs can be nested, this'd need another stack similar to blockStack) [this is low-priority as this implementation, while crude, does the job]
    func findStartIndex(from startIndex: Int, to stopIndex: Int) -> Int { // start..<stop
        // caution: when finding the start of a record field, the resulting range *includes* the field's `.label(NAME)`; e.g. when parsing `{foo: EXPR, EXPR, bar: EXPR}`, the indexes of the opening `{` and two `,` tokens are returned; leaving the caller to process `foo: EXPR` and `bar: EXPR`
        if let i = self[startIndex..<stopIndex].lastIndex(where: { $0.form.isLeftExpressionDelimiter }) {
            return i + 1 // `i` is the delimiter token; the current expression starts on the token after it
        } else {
            return startIndex
        }
    }
    
    //
    
    
    fileprivate func longestFullMatch(at index: Int, stopIndex: Int, found: inout Set<Int>) -> (PatternMatch, Int)? {
        // first token should appear at index and last token before stopIndex
        // note: can't use isBeginningOfMatch as we've overwritten new matches with their full version, so keep set of already found IDs
        assert(index<stopIndex)
   //     if (self[index].matches.filter{ !found.contains($0.uniqueID) }.count > 1) {print("DEBUG: >1 match begins at \(index); will use longest.") //; self.show(index, index+1)}
        if let match = (self[index].matches.filter{ !found.contains($0.groupID) }.max{ $0.count < $1.count }) {
            found.insert(match.groupID)
            //            print("Match:", index, match)
            let rightIndex = index + match.count - 1 // right index is INclusive
//            print("longestFullMatch found \(match.name) match at \(index...rightIndex) (stop: \(stopIndex), stack: \(self.count)): \(match)");self.show();print()
            if rightIndex > stopIndex { return nil }
            return (match, rightIndex)
        } else { // end of EXPR (note: if returned index < stopIndex, assume syntax error)
            //     print("No more matches at \(index)."); self.show(index, index+1)
            return nil
        }
        
    }
    
    
    // reduce in-place; this does not change number of tokens in stack
    fileprivate mutating func reduceInPlace(match: PatternMatch, from startIndex: Int) {
        assert(startIndex + match.count <= self.count)
        guard let form = match.reductionFor(stack: self, startIndex: startIndex) else {
            // TO DO: what should we do here? return success flag/throw on failure? caller could see if there are any other full matches it can use, or else give up and encapsulate the problem in a SyntaxErrorDescription; see also below reduce(match:) method, which returns a flag (though an error might be more appropriate, given the need to break out of the recursive `reduce(_:from:to:stopIndex:found:)` method below)
            fatalError("Provisional `\(match.name)` match succeeded but exact match failed at \(startIndex): \n\(self[startIndex])\n\n")
        }
        let rightIndex = startIndex + match.count - 1
        self[startIndex].form = form
        self[rightIndex].form = form
    }
    
    
    // reduces a contiguous sequence of fully-matched operators in order of precedence
    // caution: this method makes working changes to token stack without changing its length (the final replacement is made by reduceOperatorExpression once this method returns)
    fileprivate mutating func reduce(leftMatch: PatternMatch, from leftIndex: Int, overlappingAt commonIndex: Int, stopIndex: Int, found: inout Set<Int>) -> (Int, Int) { // returns start index of last match made, plus the rightmost index (non-inclusive) of the expression that was read (this will be same as stopIndex unless there is a syntax error preventing the expression being read to its end); commonIndex is the token at which two patterns overlap; thus leftIndex...commonIndex and commonIndex..<rightIndex
 //       assert(stopIndex <= self.count)
 //       assert(commonIndex < stopIndex)
        
        //assert(match == nil || rightIndex <= stopIndex)
        //print("RIGHT:", match?.definition.precis as Any, commonIndex, rightIndex, stopIndex, self.count)
        //rightIndex <= stopIndex
        if let (rightMatch, rightIndex) = self.longestFullMatch(at: commonIndex, stopIndex: stopIndex, found: &found) {
            assert(rightIndex <= stopIndex)
            //print("PRECEDENCE", leftMatch, rightMatch, reductionOrderFor(leftMatch, rightMatch))
            assert(leftMatch.groupID != rightMatch.groupID) // e.g. `…+…` vs `+…`
            switch reductionOrderFor(leftMatch, rightMatch) {
            case .left: // reduce left match then right match
                self.reduceInPlace(match: leftMatch, from: leftIndex)
                let rightmostIndex = self.reduce(leftMatch: rightMatch, from: commonIndex, overlappingAt: rightIndex, stopIndex: stopIndex, found: &found).1
                return (commonIndex, rightmostIndex)
            case .right: // reduce right match then left match
                let rightmostIndex = self.reduce(leftMatch: rightMatch, from: commonIndex, overlappingAt: rightIndex, stopIndex: stopIndex, found: &found).1
                self.reduceInPlace(match: leftMatch, from: leftIndex)
                return (leftIndex, rightmostIndex)
            }
        } else { // no right match to compare (either we’ve reached the expression’s rightmost operation or we’ve reduced the expression down to its last operator) so reduce left match
            self.reduceInPlace(match: leftMatch, from: leftIndex)
            return (leftIndex, commonIndex + 1)
        }
    }
    
    
    // replace the specified token sequence with its reduction, updating any in-progress matches
    // used here (when reducing operators) and by `reduce commands.swift`
    mutating func replace(match: PatternMatch? = nil, from startIndex: Int, to stopIndex: Int? = nil, withReduction form: Token.Form) { // start..<stop
        
        // TO DO: passing match is a kludge to remove fully matched and reduced PatternMatchers from token stack so that they aren't re-applied (it’s be better to remove the PatternMatch at the same time as calling its reduce function, but that’s a bit awkward right now as some methods return the reduction rather than perform in place; which in turn is a kludge to perform multiple operator expression reductions on non-head tokens) // TO DO: this should not be necessary as completed matches should be removed upstream
        
        let stopIndex = stopIndex ?? self.count
        assert(startIndex < stopIndex, "BUG: trying to reduce zero tokens at \(startIndex); fullyReduceExpression should have already checked if an expr exists between delimiters and returned immediately if none found (e.g. in empty list/record/group).")
        var matches = [PatternMatch]()
        let currentMatches = self[startIndex].matches
        if startIndex > 0 { // advance any matches from preceding token that aren’t already on current token
            let currentIDs = currentMatches.map{ $0.originID }
            matches += self[startIndex-1].matches.filter{ !currentIDs.contains($0.originID) }.flatMap{$0.next()}
        }
        matches += currentMatches
        if let match = match {
            matches = matches.filter{ match.originID != $0.originID }
        }
        let reduction: Parser.TokenInfo = (form, matches, self[startIndex].hasLeadingWhitespace)
        self.replaceSubrange(startIndex..<stopIndex, with: [reduction])
    }
    
    
    // reduce fully matched operations in the given range; on return, stopIndex is decremented by the number of tokens removed from stack
    
    // TO DO: this should be able to process [some/all?] commands as well
    
    mutating func reduceOperatorExpression(from startIndex: Int, to stopIndex: inout Int) {
        //print("reduceOperatorExpression:", startIndex..<stopIndex);self.show(startIndex, stopIndex);print()
        if startIndex == stopIndex - 1 { // TO DO: this is taken from old Parser.reductionForOperatorExpression(…); we should aim to get rid of this in favor of encapsulating syntax errors where they occur (Q. does this mean .error case is itself redundant and can be removed?)
            switch self[startIndex].form {
            case .error(let e):
                print("reduceOperatorExpression() found .error at \(startIndex)")
                self[startIndex].form = .value(SyntaxErrorDescription(error: e))
            default: ()
            }
        }
        // in a well-matched expression, the last token of one operation is also the first token of the next; thus to determine which full matches to reduce (longest first) and which to ignore (shorter matches overlapped by longer ones), we start from left edge of expression and jump from one boundary to the next until we reach the right edge, and the only thing we need to do along the way is compare adjoining operations’ precedence to determine which to reduce first
        // to prepare the expression’s tokens on the stack (which we treat as an array slice) for performing these reductions, and working from right to left, remove partial matches and move each full match from end to start of its range
        //self.show(startIndex, stopIndex); print()
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
        // now, working from left to right and jumping from expression boundary to expression boundary, recursively search for the highest precedence expression and reduce that first, followed by next highest, and so on
        // to avoid shortening the stack after every reduction (more expensive and liable to off-by-one bugs), we replace the first _and_ last tokens of each operation with its reduction; once all reductions have been applied, the entire range is replaced with the final .value and stopIndex updated to reflect the reduced token range’s new length (1)
        index = startIndex
        var foundIDs = Set<Int>()
        var result = [Token.Form]()
        // given well formed code, this loop should iterate once then exit
        while index < stopIndex { // this loop will repeat for any unmatched token sequences (syntax errors)
            // TO DO: when reporting syntax error, should we reduce as much as possible and return that, or return the original unreduced token sequence? (attempting remaining reductions may infer user’s intent incorrectly whereas not reducing at all offers no help in guessing that intent)
            if let (leftMatch, commonIndex) = self.longestFullMatch(at: index, stopIndex: stopIndex, found: &foundIDs) { // check comparison
                let (resultIndex, rightmostIndex) = self.reduce(leftMatch: leftMatch, from: index, overlappingAt: commonIndex, stopIndex: stopIndex, found: &foundIDs)
                result.append(self[resultIndex].form) // get the final reduced value (or multiple values if there are missing matches due to syntax errors)
                index = rightmostIndex
            } else {
                print("Missing last match in reduceOperatorExpression")
                index = stopIndex // TO DO: this skips remaining matches in EXPR; should we increment index by 1 and keep looping?
                result.append(.error(BadSyntax.missingExpression)) // TO DO: better error message
            }
        }
        if result.count == 1 {
            self.replace(from: startIndex, to: stopIndex, withReduction: result[0])
        } else {
            fatalError("TODO: return bad syntax value for: \(result)") // TO DO: reduce as SyntaxErrorDescription
        }
        stopIndex = startIndex + 1
    }
    
    
    
    mutating func reduce(match: PatternMatch) -> Bool { // called by Parser.shift() when auto-reducing; this performs a normal SR reduction at head of stack; returns Bool flag indicating if reduction was performed //
        //print("REDUCING", match)
        let stopIndex = self.count // non-inclusive
        let startIndex = stopIndex - match.count
        if let form = match.reductionFor(stack: self, startIndex: startIndex) {
            // TO DO: this is only place that match is passed to replace; is it still needed?
            self.replace(match: match, from: startIndex, to: stopIndex, withReduction: form)
            return true
        } else {
            //  print("Reduction not performed at this time:", fullMatch)
            return false
        }
    }
    
}


