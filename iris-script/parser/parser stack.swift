//
//  parser stack.swift
//  iris-script
//
//  extends the `[Parser.StackItem]` type (used in `Parser.stack` and `FullMatch.tokens`) with methods for searching and reducing shifted tokens
//

import Foundation


extension Array {
    mutating func replaceFirstItem(with item: Element) {
        self[0] = item
    }
    mutating func replaceLastItem(with item: Element) {
        self[self.count - 1] = item
    }
}


extension Array where Element == Parser.StackItem {
    
    // DEBUG: list stack tokens + their associated partial/complete matchers

    func show(_ startIndex: Int = 0, _ stopIndex: Int? = nil) { // startIndex..<stopIndex
        print(self.dump(startIndex, stopIndex))
    }
    
    func dump(_ startIndex: Int = 0, _ stopIndex: Int? = nil) -> String { // startIndex..<stopIndex
        let stopIndex = stopIndex ?? self.count
        return "Stack[\(startIndex)..<\(stopIndex)]:\n" + self[startIndex..<(stopIndex)].map{
            "\t.\($0.form) [\($0.matches.count)]\($0.matches.map{ "\n\t\t\t\t\($0)" }.joined(separator: ""))"
        }.joined(separator: "\n")
    }
    
    // used to disambiguate ambigious overloaded operators (e.g. `+`, `-`) based on surrounding whitespace
    
    func hasLeadingWhitespace(at index: Int) -> Bool {
        return self[index].hasLeadingWhitespace
    }
    func hasTrailingWhitespace(at index: Int) -> Bool {
        return index+1 < self.count && self[index+1].hasLeadingWhitespace
    }
    func hasBalancedWhitespace(at index: Int) -> Bool {
        // if this is last token, whitespace is _always_ imbalanced (i.e. false)
        return index+1 < self.count && self[index].hasLeadingWhitespace == self[index+1].hasLeadingWhitespace
    }
    
    // starting from end of a range of tokens, search backwards to find a left-hand expression delimiter
    
    func findStartIndex(from startIndex: Int, to stopIndex: Int) -> Int { // start..<stop
        // caution: when finding the start of a particular record field, the resulting range *includes* the field's `.label(NAME)`; e.g. when parsing `{foo: EXPR, EXPR, bar: EXPR}`, the indexes of the opening `{` and two `,` tokens are returned; leaving caller to wrangle labels in `foo: EXPR` and `bar: EXPR` itself
        // TO DO: when parsing exprs, what about remembering the index of each expr’s left-hand boundary, avoiding need to back-scan for it each time? (since exprs can be nested, this'd need another stack similar to blockMatchers) [this is low-priority as the current approach, while crude, does the job]
        if let i = self[startIndex..<stopIndex].lastIndex(where: { $0.form.isLeftExpressionDelimiter }) {
            return i + 1
        } else {
            return startIndex
        }
    }
    
    
    // find full operation matchers in the given range; reductionForOperatorExpression() uses the result in determining the order in which to reduce nested operators according to the operators’ arity, precedence, and/or associativity
    
    func findLongestFullMatches(from startIndex: Int, to stopIndex: Int) -> [FullMatch] { // start..<stop // given a range of shifted stack frames denoting a delimited simple/compound expression, returns the longest full matches grouped with their associated tokens // TO DO: decide if end index is inclusive or exclusive and standardize across all code
        // TO DO: would it be easier to work with if findLongestMatches() returned a single array/doubly-linked list containing [mostly alternating] .operatorName()/.operand() enums and have reductionForOperatorExpression() traverse that?
        assert(startIndex >= 0 && stopIndex <= self.count)
        // important: this should only be used to identify longest matches in a contiguous sequence; it cannot be used to identify matches that span over other matches (at least, not until all those nested matches have already been reduced; e.g. given `if EXPR1 then EXPR2`, findLongestMatches should be called for EXPR1 only, then for EXPR2 only, and only then for `if VALUE1 then VALUE2` once its operands are all reduced to .values)
        var matches = [Int: FullMatch]() // [groupID:(start...stop,match,tokens)] // note that first/last tokens in sub-array may represent incomplete matches, e.g. given `1 * - 2`, the `*` match's tokens will be [`1`,`*`,`-`]; it's up to the reducer to reduce [`-`,`2`] to value `-2` and substitute that in place of the `*` match's `-` token
        //print("findLongestMatches:")
        for rightExpressionIndex in (startIndex..<stopIndex).reversed() { // TO DO: confirm right-to-left vs left-to-right
            for m in self[rightExpressionIndex].matches where m.isAFullMatch {
                // if it's a full match and doesn't extend outside startIndex..<stopIndex then store it
                // TO DO: make sure this respects optional conjunctions (e.g. `EXPR is_before EXPR ( as EXPR )?`; while `EXPR is_before EXPR` is a full match, if it's followed by `as` conjunction then the longer match should be used)
                let matchStart = m.startIndex(from: rightExpressionIndex)
                // of all matches that started on same .operatorName token (this may include both prefix and infix)
                if (matchStart >= startIndex) && (matches[m.groupID] == nil || matches[m.groupID]!.match.count < m.count) {
                    matches[m.groupID] = (matchStart, rightExpressionIndex, m,
                                          [Parser.StackItem](self[matchStart...rightExpressionIndex]))
                }
            }
        }
        // return the longest matches for each operator, ordered from left to right
        return matches.values.sorted{ ($0.start, $0.stop) < ($1.start, $1.stop) }
    }
    
    
    func reductionFor(fullMatch: PatternMatch) -> Token.Form {
        // reduce a single fully matched expression at head of stack to a single value
        let endIndex = self.count // end index is non-inclusive
        let startIndex = endIndex - fullMatch.count
        let result: Token.Form
        do {
            result = .value(try fullMatch.definition.reduce(self, fullMatch, startIndex, endIndex))
        } catch {
            result = .error(error as? NativeError ?? InternalError(error))
        }
        //        print("REDUCED COMPLETED MATCH \(fullMatch) ➞ .\(result)")
        return result
    }
    
    
    mutating func replace(from startIndex: Int, to stopIndex: Int? = nil, withReduction form: Token.Form) { // start..<stop
        // reapply the preceding stack frame's matchers to newly reduced value
        // TO DO: make sure this correctly resumes in-progress matches
        let stopIndex = stopIndex ?? self.count
        assert(startIndex < stopIndex, "BUG: trying to reduce zero tokens at \(startIndex); fullyReduceExpression should have already checked if an expr exists between delimiters and returned immediately if none found (e.g. in empty list/record/group).")
        let matches: [PatternMatch]
        if startIndex > 0 {
            //print(">", form)
            // TO DO: when re-matching EXPR before conjunction (e.g. the test expr in `if…then…`), this should probably be done with allowingPartialMatch:false to ensure the full expr is matched; this'd also allow `.testValue(TESTFUNC)` pattern to distinguish between initial provisional “is it an expr?” match (which is the most that can be asked until that expr is fully reduced) and final “is it an expr that satisfies TESTFUNC?”
            // retry in-progress matches from preceding token
            let precedingMatches = self[startIndex - 1].matches.flatMap{ $0.next() }.filter{ $0.provisionallyMatches(form: form) }
       //     print("reapplying preceding matches:")
            let currentMatches = self[startIndex].matches.filter{ !precedingMatches.contains($0) && $0.provisionallyMatches(form: form) }
        //    print("reapplying current matches:")
            matches = precedingMatches + currentMatches
        } else {
            matches = self[startIndex].matches.filter{ $0.provisionallyMatches(form: form) }
        }
        let reduction: Parser.StackItem = (form, matches, self[startIndex].hasLeadingWhitespace)
        self.replaceSubrange(startIndex..<stopIndex, with: [reduction])
    }
    
    
    mutating func reduce(fullMatch: PatternMatch) { // called by Parser.shift() when auto-reducing; this performs a normal SR reduction at head of stack
        //print("REDUCING", fullMatch)
        let stopIndex = self.count // non-inclusive
        let startIndex = stopIndex - fullMatch.count
        let form = self.reductionFor(fullMatch: fullMatch)
        self.replace(from: startIndex, to: stopIndex, withReduction: form)
    }
    
    mutating func append(matches: [PatternMatch]) {
        assert(!self.isEmpty, "Can't append following matches to head of parser stack as it is empty: \(matches)")
        self[self.count-1].matches += matches
    }
}



extension Array where Element == Parser.BlockMatch {
    
    // secondary stack used to track nested structures (lists, records, groups, keyword-based blocks)
    
    mutating func start(_ form: Parser.BlockMatch) {
        self.append(form)
    }
    
    mutating func stop(_ form: Parser.BlockMatch) throws {
        if form.matches(self.last!) {
            self.removeLast()
        } else {
            // TO DO: what do do with mismatched last item? leave/discard/speculatively rebalance?
            switch self.last! {
            case .list:           throw BadSyntax.unterminatedList
            case .record:         throw BadSyntax.unterminatedRecord
            case .group:          throw BadSyntax.unterminatedGroup
            case .script:         throw BadSyntax.missingExpression // TO DO: what error?
            case .conjunction(_): throw BadSyntax.missingExpression // TO DO: what error?
            }
        }
    }
    
    func conjunctionMatches(for name: Symbol) -> [PatternMatch]? {
        // print("check for", name, "in", self.blockMatchers.last!)
        if case .conjunction(let conjunctions) = self.last! {
            return conjunctions[name]
        } else {
            return nil
        }
    }
}


// FullMatch describes a single fully matched pattern; findLongestFullMatches() returns an array of FullMatch tuples, which are used by `Parser.reductionForOperatorExpression(…)` to fully reduce one or more compound operator expressions (e.g. `1+2*-3=4`) to a single Value in order of operators’ precedence and associativity rules

typealias FullMatch = (start: Int, stop: Int, match: PatternMatch, tokens: [Parser.StackItem]) // important: stop index is INclusive (start...stop); use `left.stop == right.start` to check for overlapping operations (caution: this assumes the shared operand has already been fully reduced to a single .value token)


extension Array where Element == FullMatch {
    
    func show() { // DEBUG
        print("  ->")
        for m in self { print("    \(m.start)-\(m.stop) \(m.match) [\(m.tokens.map{".\($0.form)"}.joined(separator: ", "))]") }
        //print()
    }
    
    mutating func reduceMatch(at index: Int) {
        // in order to reduce nested operations, reductionForOperatorExpression() first copies each operator and its associated operand[s] from the main stack to its own private array (`FullMatch.tokens`); it then calls `[FullMatch].tokens(at:)` to reduce each subarray to a single Value, comparing each operator’s precedence and/or associativity to its neighbors’ to determine which operation to reduce next (typically the operator with the highest precedence)
        // each time an operator expression is reduced, its neighbors’ right and/or left operands are replaced with that reduction, and the process repeated until only a single value remains
        // TO DO: Q. is there a less crude algorithm than this dice-and-slice approach? (for now, it's “good enough”)
        let matchInfo = self[index]
        let form = matchInfo.tokens.reductionFor(fullMatch: matchInfo.match)
       // print("…TO: \(form)")
        // e.g. `3 + - 1 * 2`
        let reduction: Parser.StackItem = (form, [], matchInfo.tokens[0].hasLeadingWhitespace)
        // if subsequent match takes left operand, copy the reduced value to that
        if index+1 < self.count && self[index+1].match.hasLeftOperand {
            self[index+1].tokens.replaceFirstItem(with: reduction)
            self[index+1].start = matchInfo.start // start...stop range absorbs the extra tokens
        }
        // if preceding match takes right operand, copy the reduced value to that
        if index > 0 && self[index-1].match.hasRightOperand {
            self[index-1].tokens.replaceLastItem(with: reduction)
            self[index-1].stop = matchInfo.stop // start...stop range absorbs the extra tokens
        }
        self.remove(at: index)
    }
}


