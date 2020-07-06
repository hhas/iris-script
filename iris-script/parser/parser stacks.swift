//
//  parser stacks.swift
//  iris-script
//
//  extends the `Array<StackInfo>` type used in `Parser.tokenStack` (and `FullMatch.tokens`) with methods for searching and reducing shifted tokens
//
//  extends the `Array<BlockInfo>` type used in `Parser.blockStack`
//
//  extends the `Array<FullMatch>` type used in `Parser.reductionForOperatorExpression()`
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
        // TO DO: when parsing exprs, what about remembering the index of each expr’s left-hand boundary, avoiding need to back-scan for it each time? (since exprs can be nested, this'd need another stack similar to blockStack) [this is low-priority as the current approach, while crude, does the job]
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
            for m in self[rightExpressionIndex].matches where m.isAFullMatch { // this may pick up >1 full match of same pattern (i.e. same origin ID) and/or same pattern group (same group ID, i.e. started on same .operatorName, which is superset of origin ID); the following code will filter out the non-longest matches
                
                // if it's a full match and doesn't extend outside startIndex..<stopIndex then store it (be aware that a leading/trailing operand may only be provisionally matched at this time, in which case the operation cannot yet be reduced; this will be checked downstream)
                
                // TO DO: make sure this respects optional conjunctions (e.g. `EXPR is_before EXPR ( as EXPR )?`; while `EXPR is_before EXPR` is a full match, if it's followed by `as` conjunction then the longer match should be used)
                let matchStart = m.startIndex(from: rightExpressionIndex)
                // of all matches that started on same .operatorName token (this may include both prefix and infix)
                if (matchStart >= startIndex) && (matches[m.groupID] == nil || matches[m.groupID]!.match.count < m.count) {
                    matches[m.groupID] = (matchStart, rightExpressionIndex, m,
                                          [Parser.TokenInfo](self[matchStart...rightExpressionIndex]))
                }
            }
        }
        // return the longest matches for each operator, ordered from left to right
        return matches.values.sorted{ ($0.start, $0.stop) < ($1.start, $1.stop) }
    }
    
    
    mutating func replace(reducedMatchIDs: Set<Int>? = nil, from startIndex: Int, to stopIndex: Int? = nil, withReduction form: Token.Form) { // start..<stop
        
        // TO DO: reducedMatchIDs is a kludge to remove fully matched and reduced PatternMatchers from token stack so that they aren't re-applied (it’s be better to remove the PatternMatch at the same time as calling its reduce function, but that’s a bit awkward right now as some methods return the reduction rather than perform in place; which in turn is a kludge to perform multiple operator expression reductions on non-head tokens)
        
        // reapply the preceding stack frame's matchers to newly reduced value
        // TO DO: make sure this correctly resumes in-progress matches
        let stopIndex = stopIndex ?? self.count
        assert(startIndex < stopIndex, "BUG: trying to reduce zero tokens at \(startIndex); fullyReduceExpression should have already checked if an expr exists between delimiters and returned immediately if none found (e.g. in empty list/record/group).")
        var matches = [PatternMatch]()
        let currentMatches = self[startIndex].matches
        if startIndex > 0 { // advance any matches from preceding token that aren’t already on current token
            let currentIDs = currentMatches.map{ $0.originID }
            matches += self[startIndex-1].matches.filter{ !currentIDs.contains($0.originID) }.flatMap{$0.next()}
        }
        matches += currentMatches
        if let matchIDs = reducedMatchIDs {
          //  print("REMOVING COMPLETED MATCH:", matchIDs)
            matches = matches.filter{ !matchIDs.contains($0.originID) }
        }
        let reduction: Parser.TokenInfo = (form, matches, self[startIndex].hasLeadingWhitespace)
       // print("REPLACED WITH:", reduction)
        self.replaceSubrange(startIndex..<stopIndex, with: [reduction])
    }
    
    
    mutating func reduce(fullMatch: PatternMatch) -> Bool { // called by Parser.shift() when auto-reducing; this performs a normal SR reduction at head of stack // TO DO: return Bool flag indicating if reduction was performed?
        //print("REDUCING", fullMatch)
        if let form = fullMatch.reductionFor(stack: self) {
            let stopIndex = self.count // non-inclusive
            let startIndex = stopIndex - fullMatch.count
            self.replace(reducedMatchIDs: [fullMatch.originID], from: startIndex, to: stopIndex, withReduction: form)
            return true
        } else {
          //  print("Reduction not performed at this time:", fullMatch)
            return false
        }
    }
    
    mutating func append(matches: [PatternMatch]) {
        assert(!self.isEmpty, "Can't append following matches to head of parser stack as it is empty: \(matches)")
        self[self.count-1].matches += matches
    }
    
    mutating func append(match: PatternMatch) {
        assert(!self.isEmpty, "Can't append following match to head of parser stack as it is empty: \(match)")
        self[self.count-1].matches.append(match)
    }
}


// block matching

extension Array where Element == Parser.BlockInfo {
    
    func show() {
        print("Block Stack:")
        for f in self {
            print("\t\t.\(f)")
        }
    }
    
    // secondary stack used to track nested structures (lists, records, groups, keyword-based blocks)
    
    mutating func begin(_ form: Parser.BlockInfo) {
        self.append(form)
    }
    
    mutating func end(_ form: Parser.BlockInfo) throws { // TO DO: this is impractical for removing conjunctions: for those we need keyword (and index?)
        assert(!self.isEmpty, "Can't remove \(form) from parser’s block stack as it is already empty.")
        switch (self.last!, form) {
        case (.list, .list), (.record, .record), (.group, .group), (.script, .script):
            self.removeLast()
        case (_, .conjunction(_)):
            fatalError("BUG: Use `BlockStack.end(conjunction: NAME)` to remove conjunctions.")
        default:
            // TO DO: what error(s) should this raise? what do do with the value currently at top of stack? leave/discard/speculatively rebalance? (for now we leave as-is, but would probably benefit from scanning rest of code to see how well [or not] that balances against the current stack and suggest fixes based on that)
            print("Expected end of .\(self.last!) but found end of .\(form) instead.")
            switch self.last! {
            case .list:           throw BadSyntax.unterminatedList
            case .record:         throw BadSyntax.unterminatedRecord
            case .group:          throw BadSyntax.unterminatedGroup
            case .script:         throw BadSyntax.missingExpression
            case .conjunction(_): throw BadSyntax.missingExpression
            case .block(_):       throw BadSyntax.missingExpression
            }
        }
    }
    
    mutating func begin(_ matches: [PatternMatch], for name: Symbol, from stopIndex: Int) {
        // name is the conjunction/block terminator keyword
        var conjunctions = Conjunctions()
        var blocks = Conjunctions()
        for match in matches {
            if !match.definition.hasRightOperand { // TO DO: this is kludgy: we need to know if keyword terminates a block or is conjunction before trailing operand; for now we assume anything without a right operand is an auto-reducing block with no intermediate conjunctions
                blocks[name] = [(match, stopIndex)]
            } else {
                conjunctions[name] = [(match, stopIndex)]
            }
        }
        if !conjunctions.isEmpty && !blocks.isEmpty {
            print("WARNING: \(name) keyword is both a block terminator and conjunction.")
        }
        // operators cannot span multiple sub-exprs, so any unmatched conjunctions will be discarded when end of expr is reached
        if !conjunctions.isEmpty { self.begin(.conjunction(conjunctions)) }
        // blocks can span multiple sub-exprs; the closing keyword is part of the same expr as the opening keyword
        if !blocks.isEmpty { self.begin(.block(blocks)) }
    }
    
    func blockMatches(for name: Symbol) -> ConjunctionMatches? {
        if case .block(let matches) = self.last {
            assert(!matches.isEmpty, "BUG: blockMatches(for: \(name)) should never return an empty array.")
            return matches[name]
        }
        return nil
    }
    
    func conjunctionMatches(for name: Symbol) -> ConjunctionMatches? {
        if case .conjunction(let matches) = self.last {
            assert(!matches.isEmpty, "BUG: conjunctionMatches(for: \(name)) should never return an empty array.")
            return matches[name]
        }
        return nil
    }
    
    mutating func end(_ name: Symbol) {
        switch self.last {
        case .block(let matches), .conjunction(let matches):
            if matches[name] != nil {
                self.removeLast()
                return
            }
        default: ()
        }
        fatalError("BUG: BlockStack.end(\(name)) should never fail as it should only be called after blockMatches/conjunctionMatches(for: \(name)) has returned a non-nil result.")
    }
    
    mutating func endConjunctions() {
        while case .conjunction(_) = self.last {
          //  print("Discarding unfinished conjunctions from block stack:", conjunctions)
            self.removeLast()
        }
    }
}

typealias ConjunctionMatches = [(match: PatternMatch, end: Int)]

typealias Conjunctions = [Symbol: ConjunctionMatches] // TO DO: we should be able to capture end indexes for each PatternMatch (assuming we don’t try to use them after in-place reductions have been performed), which saves us having to backscan the stack for them

extension Dictionary where Key == Conjunctions.Key, Value == Conjunctions.Value {

    mutating func add(_ match: PatternMatch, endingAt stopIndex: Int) {
        for name in match.conjunctions { // this adds a lookup for the conjunction's canonical name _and_ any aliases
            if self[name] == nil {
                self[name] = [(match, stopIndex)]
            } else {
                self[name]!.append((match, stopIndex))
            }
        }
    }
}


// FullMatch describes a single fully matched pattern; findLongestFullMatches() returns an array of FullMatch tuples, which are used by `Parser.reductionForOperatorExpression(…)` to fully reduce one or more compound operator expressions (e.g. `1+2*-3=4`) to a single Value in order of operators’ precedence and associativity rules

typealias FullMatch = (start: Int, stop: Int, match: PatternMatch, tokens: [Parser.TokenInfo]) // important: stop index is INclusive (start...stop); use `left.stop == right.start` to check for overlapping operations (caution: this assumes the shared operand has already been fully reduced to a single .value token)


extension Array where Element == FullMatch {
    
    func show() { // DEBUG
        print("  ->")
        for m in self { print("    \(m.start)-\(m.stop) \(m.match) [\(m.tokens.map{".\($0.form)"}.joined(separator: ", "))]") }
        //print()
    }
    
    mutating func reduceMatch(at index: Int) -> Bool { // returns Bool flag indicating if reduction was performed
        // in order to reduce nested operations, reductionForOperatorExpression() first copies each operator and its associated operand[s] from the main stack to its own private array (`FullMatch.tokens`); it then calls `[FullMatch].tokens(at:)` to reduce each subarray to a single Value, comparing each operator’s precedence and/or associativity to its neighbors’ to determine which operation to reduce next (typically the operator with the highest precedence)
        // each time an operator expression is reduced, its neighbors’ right and/or left operands are replaced with that reduction, and the process repeated until only a single value remains
        // TO DO: Q. is there a less crude algorithm than this dice-and-slice approach? (for now, it's “good enough”)
        let matchInfo = self[index]
        guard let form = matchInfo.match.reductionFor(stack: matchInfo.tokens) else { return false }
       // print("…TO: \(form)")
        // e.g. `3 + - 1 * 2`
        let reduction: Parser.TokenInfo = (form, [], matchInfo.tokens[0].hasLeadingWhitespace)
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
        return true
    }
}


