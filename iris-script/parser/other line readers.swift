//
//  other line readers.swift
//  iris-script
//

import Foundation


// TO DO: reader for 0uXXXX Unicode codepoints; these are probably best as UTF8 with implicit concatenation, e.g. `0u32 0u456 0u101DEF` would concat to 3-codepoint string; Q. how should they concat to string literals? (we don't really want to require an explicit `&` operator as e.g. data files may not have access to that; see also string interpolation)

// TO DO: reader[s] for reducing #…, @…, A.B.C (note: hashtags are currently reduced by main parser, but wouldn't hurt to move this forward) // Q. should `com.example.foo` convert to `‘com.example.foo’` rather than `foo of example of com`? or should we define a `UTI`/`Namespace` struct that encodes it as linked list/array of symbols? (or convert to an objspec with PP annotation?)


struct NullReader: LineReader { // returned once line reader is exhausted; always outputs .lineBreak token
    
    let code = ""
    
    func next() -> (Token, LineReader) {
        return (nullToken, self)
    }
}

let nullReader = NullReader()




struct UnpopToken: LineReader { // analogous to pushing an existing/modified token back onto the head of the token stream
    
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
