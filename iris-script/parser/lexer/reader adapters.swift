//
//  reader adapters.swift
//  iris-script
//

import Foundation



struct NullReader: TokenReader { // returned once line reader is exhausted; always outputs .eol token
    
    let code = ""
    
    func next() -> (Token, TokenReader) {
        return (nullToken, self)
    }
}

let nullReader = NullReader()




struct UnpopToken: TokenReader { // analogous to pushing an existing/modified token back onto the head of the token stream
    
    // e.g. given the token-reader tuple `(Token(.letters, "a*b"), R)`, where the "*" operator is written without delimiting whitespace, an operator disambiguating reader might output -> `(Token(.letters, "a"), UnpopToken(.letters "*", UnpopToken(.letters "b", R)))`; in practice, we probably want the "*" token tagged as `.lexeme(L)` form where L provides a more specific description of this token, in this case, an infix operator of known precedence and associativity that maps to the corresponding handler in a known library; this added information enables the final bottom-up precedence-climbing parser to resolve operator exprs into a correctly nested Command(…) [note that whereas earlier readers are single-line, the final reader needs to operate across all lines; need to give some thought as to how this is represented]
    
    var code: String { return reader.code }
    
    let token: Token
    let reader: TokenReader
    
    init(_ token: Token, _ reader: TokenReader) {
        self.token = token
        self.reader = reader
    }
    
    func next() -> (Token, TokenReader) {
        return (self.token, self.reader)
    }
}



// TO DO: adapter for hashbang and mentions? (this might need to include reverse domain name matching)
