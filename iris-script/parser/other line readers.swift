//
//  other line readers.swift
//  iris-script
//

import Foundation


// TO DO: need adapter for reducing #…, @…, A.B.C


struct NullReader: LineReader { // returned once line reader is exhausted; always outputs .lineBreak token
    
    let code = ""
    
    func next() -> (Token, LineReader) {
        return (nullToken, self)
    }
}

let nullReader = NullReader()




struct UnpopToken: LineReader { // analogous to pushing an existing/modified token back onto the head of the token stream
    
    // e.g. given the token-reader tuple `(Token(.letters, "a*b"), R)`, where the "*" operator is written without delimiting whitespace, an operator disambiguating reader might output -> `(Token(.letters, "a"), UnpopToken(.operatorName("*"), UnpopToken(.letters "b", R)))`
    
    var code: String { return reader.code }
    
    let token: Token
    let reader: LineReader
    
    init(_ token: Token, _ reader: LineReader) {
        self.token = token
        self.reader = reader
    }
    
    func next() -> (Token, LineReader) {
        return (self.token, self.reader)
    }
}



// TO DO: adapter for hashbang and mentions? (this might need to include reverse domain name matching)
