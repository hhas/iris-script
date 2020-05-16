//
//  operator definition.swift
//  iris-script
//
//  a struct encapsulating an operator's canonical name, syntax (pattern), precedence, and associativity
//  defined by libraries' operator glues and added to operator registry during bootstrap


// TO DO: "negative" and "positive" operator definitions need custom reducefuncs that can optimize away the underlying command when RH EXPR is a number literal, e.g. `-a` tokenizes as ["-", "a"] which reduces to Command("-",Command("a")), but `-2` tokenizes as ["-", "2"] which reduces to Int(-2)


import Foundation


func formatPattern(_ pattern: [Pattern]) -> String {
    return "(\(pattern.map{String(describing:$0)}.joined(separator: " ")))"
}


struct OperatorDefinition: CustomDebugStringConvertible { // TO DO: Equatable
        
    var debugDescription: String {
        return formatPattern(self.pattern)
    }
    
    // e.g. [EXPR, +, EXPR] // Q. how to define `plus`/`added_to`/Unicode full-width aliases for `+`? Q. should spoken aliases be distinguished from written aliases?
    // registry.add("positive", .prefix, 598, .left, ["+", "＋"])
    
    
    var keywords: [Symbol] { return self.pattern.reduce([], { result, pattern in // all keywords used by this operator, including aliases and conjunctions; canonical name should appear first (need to check this)
        switch pattern {
        case .keyword(let kw): return result + [kw.name] + kw.aliases
        default: return result
        }
    })}
    
    // TO DO: precedence, associativity (any cases where these aren't the same for all keywords in pattern?)
    
    enum Associativity {
        case left
        case right
        // TO DO: `case none` (e.g. `1 thru 2 thru 3` should be a syntax error)
    }
    
    var name: Symbol { return self.keywords.first! } // canonical name
    var conjunctions: ArraySlice<Symbol> { return self.keywords.dropFirst() }
    // let aliases: [Symbol] // any other recognized names (pp will typically reduce these to canonical names), e.g. `.symbol(Symbol("/"))`; in particular, symbolic operators may define a word-based alternative to aid dictation-driven coding, e.g. `.word(Symbol("divided_by"))`
    
    // parser resolves operator precedence by either reducing LH expr (if LH operator has higher precedence) or shifting RH operator and finishing that match first (once RH operation is reduced, the LH operation can be reduced as well); similarly, associativity reduces LH operation if the operator is .left associative or shifts operand if .right and matches RH operation first
    
    let pattern: [Pattern] // TO DO: initializer should ideally enforce a non-empty array containing one or more keywords (or punctuation), also we may want to ensure keywords and exprs are not adjacent [e.g. `if…then…` alternates the two, while in the case of `do…done` multiple exprs in the body should have delimiters between them or, if the block is empty, then `Kw LF Kw`]; that said, we want to minimize bootstrap overheads so may be best to perform these checks at glue generation time; note: a keyword may occasionally appear more than once, e.g. `YYYY-MM-DD`
    let precedence: Precedence
    let associate: Associativity // only relevant to infix operators, e.g. `^`, `else`
    
}



