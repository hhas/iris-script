//
//  operator definition.swift
//  iris-script
//
//  a struct encapsulating an operator's canonical name, syntax (pattern), precedence, and associativity
//  defined by libraries' operator glues and added to operator registry during bootstrap

// parser resolves operator precedence by either reducing LH expr (if LH operator has higher precedence) or shifting RH operator and finishing that match first (once RH operation is reduced, the LH operation can be reduced as well); similarly, associativity reduces LH operation if the operator is .left associative or shifts operand if .right and matches RH operation first

// caution: auto-reducing operator patterns must not have more than one end point as they reduce as soon as a full match is made (i.e. they do not look for a longer match before reducing), e.g. `A … B` is acceptable (always ends on B) but `A … B C?` is not (may end on B or C)


import Foundation



struct OperatorDefinition: CustomStringConvertible { 
        
    var description: String { return self.pattern.description }
    
    // Q. should spoken aliases be distinguished from written aliases?
    
    // note: returned arrays _may_ contain duplicate keywords/names (i.e. if pattern branches, and both branches include same keyword, that keyword is collected twice); we don't bother discarding duplicates here as it shouldn't matter to code that currently uses these methods
    
    var keywords: [Keyword] { return self.pattern.flatMap{$0.keywords} }
    
    var allNames: [Symbol] { return self.keywords.flatMap{$0.allNames} } // all names used by this operator, including aliases and conjunctions; canonical name typically appears first, although that depends on pattern structure and may not hold in future
    
    // TO DO: var for getting primary keywords only? (these are the ones for which we want to spawn matchers - unless we plan on full bidirectional matching support, in which case matchers could legitimately spawn at any opname [i.e. it should be possible to transform a branching pattern so that branches radiate both forwards and backwards from a single keyword anywhere in pattern])
    
    // TO DO: precedence, associativity (any cases where these aren't the same for all keywords in pattern?)
    
    enum Associativity {
        case left
        case right
        // TO DO: `case none` (e.g. `1 thru 2 thru 3` should be a syntax error) [note that treating `a OP b OP c` as syntax error isn't absolute protection as parenthesizing one or other operation will allow it to parse, as will using underlying command syntax, at which point it's up to argument unpacking to reject the bad operand as being the wrong type]
    }
    
    let _name: Symbol?
    
    var name: Symbol { return self._name ?? self.keywords.first?.name ?? nullSymbol } // canonical name
    //var conjunctions: ArraySlice<Symbol> { return self.keywords.dropFirst() }
        
    let pattern: [Pattern] // TO DO: initializer should ideally enforce a non-empty array containing one or more keywords (or punctuation), also we may want to ensure keywords and exprs are not adjacent [e.g. `if…then…` alternates the two, while in the case of `do…done` multiple exprs in the body should have delimiters between them or, if the block is empty, then `Kw LF Kw`]; that said, we want to minimize bootstrap overheads so may be best to perform these checks at glue generation time; note: a keyword may occasionally appear more than once, e.g. `YYYY-MM-DD`
    let precedence: Precedence
    let associate: Associativity // only relevant to infix operators, e.g. `^`, `else`
    
    let reduce: Parser.ReduceFunc
    let autoReduce: Bool
    
    init(name: Symbol? = nil, pattern: [Pattern], precedence: Precedence = 0,
         associate: Associativity = .left, autoReduce: Bool = false, reducer: @escaping Parser.ReduceFunc) {
        self._name = name
        self.pattern = pattern
        self.precedence = precedence
        self.associate = associate
        self.autoReduce = autoReduce
        self.reduce = reducer
    }
    
    var precis: String {
        if let name = self._name { return name.label }
        return self.pattern.map{
            switch $0 {
            case .keyword(let kw): return kw.name.label
            case .token(.startList): return "["
            case .token(.endList): return "]"
            case .token(.startRecord): return "{"
            case .token(.endRecord): return "}"
            case .token(.startGroup): return "("
            case .token(.endGroup): return ")"
            case .token(.colon): return ":"
            case .expression, .label, .name: return "…"
            default: return "…" // Q. what about .testToken?
            }
        }.joined(separator: "")
    }
    
    // caution: these query unmatched patterns, which may branch into forms whose start/end is expr in some cases and non-exprs in other cases, so can only tell you if a particular operator *can* have a leading/trailing expr (constructing such patterns is not recommended, but it's not disallowed; and in case of command pattern is unavoidable as a command’s right operand [argument] is _always_ optional); where possible, use PatternMatcher.has[Leading/Trailing]Expression to check which was *actually* matched
    var hasLeadingExpression: Bool {
   //     print("WARNING: OperatorDefinition.hasLeadingExpression should probably not be used")
        return self.pattern.first!.hasLeadingExpression
    }
    var hasTrailingExpression: Bool {
  //      print("WARNING: OperatorDefinition.hasTrailingExpression should probably not be used")
        return self.pattern.last!.hasTrailingExpression
    }
}



