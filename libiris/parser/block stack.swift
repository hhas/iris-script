//
//  block stack.swift
//  iris-script
//
//  tracks start and end of nestable blocks (lists, records, groups, do…done) and conjunctive clauses (if…then…else…, etc)


// TO DO: formalize block structures (e.g. Keywords at beginning and end, and any number of delimited exprs inbetween) and restrict the patterns that can describe blocks (e.g. no leading/trailing operands and if conjunctions are permitted, e.g. for subdividing blocks, there should be fixed rules on where they must appear); right now this doesn’t matter too much as there is only the built-in `Block` and its two built-in syntaxes—`(…)` and `do…done`—to support, but if alternate evaluators (which is what blocks are) are also to be supported (e.g. for declarative evaluation) then we really need to set down formal rules by which they must operate so that DSLs don’t slide into chaos


import Foundation


extension Parser {
    
    public typealias ConjunctionMatches = [(match: PatternMatch, keywordIndex: Int)]

    public typealias Conjunctions = [Symbol: ConjunctionMatches] // [the operator name (conjunction) to look for (if the pattern defines aliases for this operator name, the matches are stored under those names too): all in-progress matches that use this name as a conjunction]
}



extension Parser.BlockStack {
    
    func show() {
        print("Block Stack:")
        for f in self {
            print("\t\t.\(f)")
        }
    }
    
    // begin/end punctuation- and keyword-based blocks (i.e. any multi-token structure that starts and ends with fixed tokens, e.g. `[…]`, `{…}`, `(…)`, `do…done`)
    
    mutating func beginBlock(for form: Parser.BlockType, at index: Int) { // index is first token of block
        if case .conjunction(_) = form {
            fatalError("BUG: Use `BlockStack.beginConjunction(…)` to add conjunctions.")
        }
        self.append((index, form))
    }
    
    mutating func endBlock(for form: Parser.BlockType, at index: Int) throws -> Parser.BlockInfo {
        assert(!self.isEmpty, "Can't remove \(form) from parser’s block stack as it is already empty.")
        switch (self.last!.form, form) {
        case (.list, .list), (.record, .record), (.group, .group), (.script, .script):
            return self.removeLast()
        case (_, .conjunction(_)):
            fatalError("BUG: Use `BlockStack.endConjunction(…)` to remove conjunctions.")
        default:
            // TO DO: what error(s) should this raise? what do do with the value currently at top of stack? leave/discard/speculatively rebalance? (for now we leave as-is, but would probably benefit from scanning rest of code to see how well [or not] that balances against the current stack and suggest fixes based on that)
            print("Syntax Error: Expected end of .\(self.last!) but found end of .\(form) instead.")
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
    
    func blockMatches(for name: Symbol) -> Parser.ConjunctionMatches? {
        if case .block(let matches) = self.last?.form {
            assert(!matches.isEmpty, "BUG: blockMatches(for: \(name)) should never return an empty array.")
            return matches[name]
        }
        return nil
    }
    
    // begin/end conjunctive clauses (i.e. any multi-keyword operator where a non-left operand may be terminated by a keyword, e.g. `if…then…else`, `while…repeat…`)
    
    mutating func beginConjunction(for matches: [PatternMatch], at index: Int) {
        //print("awaitConjunction:", index)
        // matches is the partially-matched conjunction/block matcher[s]; index is the index at which the previous keyword appears; once the conjunction keyword is found, everything between those keywords is reduced to a single expression, e.g. given `if TEST then EXPR1 else EXPR2`, upon encountering `if` at index 0, the parser's main loop calls awaitConjunction(…) passing it the `if… operator’s in-progress match; a .conjunction entry is added to block stack that awaits an `then` or `else` keyword; when the parser's main loop calls conjunctionMatches(…) with one of those names, the `if…` operator’s in-progress match[es] are removed from block stack and returned, triggering a reduction of the TEST expression, followed by the addition of a new .conjunction entry to await the [optional] `else` keyword
        var conjunctions = Parser.Conjunctions()
        var blocks = Parser.Conjunctions()
        for match in matches {
            if !match.definition.hasRightOperand { // TO DO: this is kludgy: we need to know if keyword terminates a block or is conjunction before trailing operand; for now we assume anything without a right operand is an auto-reducing block with no intermediate conjunctions
                for name in match.conjunctions {
                    blocks[name] = [(match, index)]
                }
            } else {
                for name in match.conjunctions {
                    conjunctions[name] = [(match, index)]
                }
            }
        }
        if !conjunctions.isEmpty && !blocks.isEmpty {
            // TO DO: what to do here? (need to figure out a test case first; once we understand the behavior, we can decide whether to fatalError here or, if not, which should take priority: conjunction or block?; either way, operator glue generator needs to check for conflicting patterns within a given library and deal with appropriately; Q. should each library include lookup tables that can be used at import-time to cross-check multiple unrelated libraries for any operator arity and keyword usage conflicts; a simple Set<Symbol> intersection should be sufficient to confirm no overloaded keywords - if a keyword is overloaded, additional checks can then be made, e.g. a linereader may be inserted to detect problem keywords in source code, flagging any found as .error)
            print("WARNING: conflicting matches use a keyword as both a block terminator and a conjunction. \(matches)")
        }
        // operators cannot span multiple sub-exprs, so any unmatched conjunctions will be discarded when end of expr is reached
        if !conjunctions.isEmpty { self.append((index, .conjunction(conjunctions))) }
        // blocks can span multiple sub-exprs; the closing keyword is part of the same expr as the opening keyword
        if !blocks.isEmpty { self.beginBlock(for: .block(blocks), at: index) }
    }
    
    // end conjunctive clause or keyword block
    mutating func endConjunction(at name: Symbol) {
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
    
    // discards any pending conjunctions at top of stack when the current expression’s right-delimiter is reached, e.g. given `if TEST then ACTION LF`, at the linebreak the parser will ignore the `if…then…else…` operator’s unmatched optional `else EXPR` clause and reduce it to a two-argument `‘if’ {TEST, ACTION}` command
    mutating func endConjunctions() {
        //print("endConjunctions")
        while case .conjunction(_) = self.last?.form {
          //  print("Discarding unfinished conjunctions from block stack:", conjunctions)
            self.removeLast()
        }
    }
    
    func conjunctionMatches(for name: Symbol) -> Parser.ConjunctionMatches? {
        //print("conjunctionMatches:", name, self)
        if case .conjunction(let matches) = self.last?.form {
            assert(!matches.isEmpty, "BUG: conjunctionMatches(for: \(name)) should never return an empty array.")
            return matches[name]
        }
        return nil
    }
    
    //
    
    var leftDelimiterIndex: Int { return self.last?.start ?? -1 }
}



