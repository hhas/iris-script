//
//  operator definition.swift
//  iris-script
//
//  a struct encapsulating an operator's canonical name, syntax (pattern), precedence, and associativity
//  defined by libraries' operator glues and added to operator registry during bootstrap


// TO DO: "negative" and "positive" operator definitions need custom reducefuncs that can optimize away the underlying command when RH EXPR is a number literal, e.g. `-a` tokenizes as ["-", "a"] which reduces to Command("-",Command("a")), but `-2` tokenizes as ["-", "2"] which reduces to Int(-2)

// parser resolves operator precedence by either reducing LH expr (if LH operator has higher precedence) or shifting RH operator and finishing that match first (once RH operation is reduced, the LH operation can be reduced as well); similarly, associativity reduces LH operation if the operator is .left associative or shifts operand if .right and matches RH operation first


// default reduction funcs for prefix, infix, postfix, atom, prefix+conjunction, block


import Foundation



struct OperatorDefinition: CustomDebugStringConvertible { // TO DO: Equatable
        
    var debugDescription: String {
        return String(describing: self.pattern)
    }
    
    // Q. should spoken aliases be distinguished from written aliases?
    
    // note: returned arrays may contain duplicate keywords/names
    
    var keywords: [Keyword] { return self.pattern.flatMap{$0.keywords} }
    
    var allNames: [Symbol] { return self.pattern.flatMap{$0.keywords.flatMap{$0.allNames}} } // all names used by this operator, including aliases and conjunctions; canonical name typically appears first, although that depends on pattern structure and may not hold in future
    
    // TO DO: precedence, associativity (any cases where these aren't the same for all keywords in pattern?)
    
    enum Associativity {
        case left
        case right
        // TO DO: `case none` (e.g. `1 thru 2 thru 3` should be a syntax error)
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
    
    var fullName: String {
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
            case .expression, .value(_), .test(_), .label, .name: return "…"
            default: return "…"
            }
        }.joined(separator: "")
    }
    
    // TO DO: `fullName` property that returns e.g. `if…then…` representation (or should full name be the canonical name? e.g. `repeat…while…`, `repeat…until…` will be ambiguous - "repeat" - unless written in full; conversely, if non-numeric comparison operators - `same_as`, etc - have an optional `as` clause, do we want that clause to appear in canonical name?)
    
    /*
    func reduce(_ stack: inout Parser.Stack) {
        print("\nREDUCE", self, " ", stack, "\n")
    }*/
}



