//
//  block stack.swift
//  iris-script
//
//  tracks start and end of nestable blocks (lists, records, groups, do…done, if…then…else…, etc)

import Foundation


extension Parser {
    
    typealias ConjunctionMatches = [(match: PatternMatch, end: Int)]

    typealias Conjunctions = [Symbol: ConjunctionMatches]
}


extension Parser.BlockStack {
    
    func show() {
        print("Block Stack:")
        for f in self {
            print("\t\t.\(f)")
        }
    }
    
    // secondary stack used to track nested structures (lists, records, groups, keyword-based blocks)
    
    mutating func begin(_ form: Parser.BlockType, at index: Int) {
        self.append((index, form))
    }
    
    mutating func end(_ form: Parser.BlockType, at index: Int) throws { // TO DO: this is impractical for removing conjunctions: for those we need keyword (and index?)
        assert(!self.isEmpty, "Can't remove \(form) from parser’s block stack as it is already empty.")
        switch (self.last!.form, form) {
        case (.list, .list), (.record, .record), (.group, .group), (.script, .script):
            self.removeLast()
        case (_, .conjunction(_)):
            fatalError("BUG: Use `BlockStack.end(conjunction: NAME)` to remove conjunctions.")
        default:
            // TO DO: what error(s) should this raise? what do do with the value currently at top of stack? leave/discard/speculatively rebalance? (for now we leave as-is, but would probably benefit from scanning rest of code to see how well [or not] that balances against the current stack and suggest fixes based on that)
            print("Expected end of .\(self.last!) but found end of .\(form) instead.")
            switch self.last!.form {
            case .list:           throw BadSyntax.unterminatedList
            case .record:         throw BadSyntax.unterminatedRecord
            case .group:          throw BadSyntax.unterminatedGroup
            case .script:         throw BadSyntax.missingExpression
            case .conjunction(_): throw BadSyntax.missingExpression
            case .block(_):       throw BadSyntax.missingExpression
            }
        }
    }
    
    mutating func begin(_ matches: [PatternMatch], for name: Symbol, from index: Int) {
        // name is the conjunction/block terminator keyword; index is the index at which the conjunction keyword appears
        var conjunctions = Parser.Conjunctions()
        var blocks = Parser.Conjunctions()
        for match in matches {
            if !match.definition.hasRightOperand { // TO DO: this is kludgy: we need to know if keyword terminates a block or is conjunction before trailing operand; for now we assume anything without a right operand is an auto-reducing block with no intermediate conjunctions
                blocks[name] = [(match, index)]
            } else {
                conjunctions[name] = [(match, index)]
            }
        }
        if !conjunctions.isEmpty && !blocks.isEmpty {
            print("WARNING: \(name) keyword is both a block terminator and conjunction.")
        }
        // operators cannot span multiple sub-exprs, so any unmatched conjunctions will be discarded when end of expr is reached
        if !conjunctions.isEmpty { self.begin(.conjunction(conjunctions), at: index) }
        // blocks can span multiple sub-exprs; the closing keyword is part of the same expr as the opening keyword
        if !blocks.isEmpty { self.begin(.block(blocks), at: index) }
    }
    
    func blockMatches(for name: Symbol) -> Parser.ConjunctionMatches? {
        if case .block(let matches) = self.last?.form {
            assert(!matches.isEmpty, "BUG: blockMatches(for: \(name)) should never return an empty array.")
            return matches[name]
        }
        return nil
    }
    
    func conjunctionMatches(for name: Symbol) -> Parser.ConjunctionMatches? {
        if case .conjunction(let matches) = self.last?.form {
            assert(!matches.isEmpty, "BUG: conjunctionMatches(for: \(name)) should never return an empty array.")
            return matches[name]
        }
        return nil
    }
    
    mutating func end(_ name: Symbol) {
        switch self.last?.form {
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
        while case .conjunction(_) = self.last?.form {
          //  print("Discarding unfinished conjunctions from block stack:", conjunctions)
            self.removeLast()
        }
    }
    
    var leftDelimiterIndex: Int { return self.last?.start ?? -1 }
}

//


extension Parser.Conjunctions {

    mutating func addPartialMatch(_ match: PatternMatch, currentlyEndingAt index: Int) { // index = keyword preceding the expression that will be read once the conjunction keyword is found, e.g. given `if 1 = 2 then 3 else 4`, `index` is first 0 (identifying the `if` keyword, when searching for `then`) then 2 (the `then` keyword, when searching for `else`, once the `1 = 2` expression has been reduced to a single .value)
        for name in match.conjunctions { // this adds a lookup for the conjunction's canonical name _and_ any aliases
            if self[name] == nil {
                self[name] = [(match, index)]
            } else {
                self[name]!.append((match, index))
            }
        }
    }
}

