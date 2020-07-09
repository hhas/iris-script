//
//  block stack.swift
//  iris-script
//
//  tracks start and end of nestable blocks (lists, records, groups, do…done, if…then…else…, etc)

import Foundation

/*
 
 BAD:
 
 Block Stack:
 .(start: -1, form: iris_script.Parser.BlockType.script)
 .(start: 0, form: iris_script.Parser.BlockType.conjunction([#‘then’: [(match: «match `if…then……` U1 O1 G1: () ‘if’ (EXPR ‘then’ EXPR (‘else’ EXPR)?) 104», end: 0)]]))
 .(start: 0, form: iris_script.Parser.BlockType.conjunction([#‘else’: [(match: «match `if…then……` U1 O1 G1: () ‘if’ (EXPR ‘then’ EXPR (‘else’ EXPR)?) 104», end: 0)]]))

 OK:
 
 Block Stack:
 .(start: -1, form: iris_script.Parser.BlockType.script)
 .(start: 0, form: iris_script.Parser.BlockType.conjunction([#‘else’: [(match: «match `if…then……` U1 O1 G1: () ‘if’ (EXPR ‘then’ EXPR (‘else’ EXPR)?) 104», end: 0)]]))
 .(start: 0, form: iris_script.Parser.BlockType.conjunction([#‘then’: [(match: «match `if…then……` U1 O1 G1: () ‘if’ (EXPR ‘then’ EXPR (‘else’ EXPR)?) 104», end: 0)]]))
 
 
 */


extension Parser {
    
    
    
    typealias ConjunctionMatches = [(match: PatternMatch, keywordIndex: Int)]

    typealias Conjunctions = [Symbol: ConjunctionMatches] // [the operator name (conjunction) to look for (if the pattern defines aliases for this operator name, the matches are stored under those names too): all in-progress matches that use this name as a conjunction]
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
    
    mutating func awaitConjunction(for matches: [PatternMatch], at index: Int) {
        // name is the conjunction/block terminator keyword; index is the index at which the previous keyword appears; once the conjunction keyword is found, everything between those keywords is reduced to a single expression, e.g. given `if TEST then EXPR1 else EXPR2`, upon encountering `if` at index 0, the parser's main loop calls awaitConjunction(…) passing it the `if… operator’s in-progress match; a .conjunction entry is added to block stack that awaits an `then` or `else` keyword; when the parser's main loop calls conjunctionMatches(…) with one of those names, the `if…` operator’s in-progress match[es] are removed from block stack and returned, triggering a reduction of the TEST expression, followed by the addition of a new .conjunction entry to await the [optional] `else` keyword
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



