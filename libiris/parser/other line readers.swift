//
//  other line readers.swift
//  iris-script
//

import Foundation

// TO DO: what about date and time readers for matching `YYYY-MM-DD`, `HH-MM-SS…` patterns?

// TO DO: what about Markdown reader? outside of annotations, this'd probably be limited to headings (LF "="+ … LF), which is useful for high-level organization (both in auto-generated user documentation and in IDE code browsers), and maybe hashtags (being used as searchable key words)

// TO DO: reader for 0uXXXX Unicode codepoints; these are probably best as UTF8 with implicit concatenation, e.g. `0u32 0u456 0u101DEF` would concat to 3-codepoint string; Q. how should they concat to string literals? (we don't really want to require an explicit `&` operator as e.g. data files may not have access to that; see also string interpolation)

// TO DO: reader[s] for reducing #…, @…, A.B.C // Q. should `com.example.foo` convert to `‘com.example.foo’` rather than `foo of example of com`? or should we define a `UTI`/`Namespace` struct that encodes it as linked list/array of symbols? (or convert to an objspec with PP annotation?)

// TO DO: if we use UTI line readers for namespace access, users should be able to write `tell @com.apple.TextEdit to …` rather than `tell app “…” to …`; the same syntax can work for libraries too, with the obvious caveat that if a library has the same UTI-based name as an app's bundle ID, we'll need some way to disambiguate


public struct EndOfCodeReader: LineReader { // returned once line reader is exhausted; always outputs .lineBreak token
    
    public let code = ""
    
    public func next() -> (Token, LineReader) {
        return (endOfCodeToken, self)
    }
}

public let endOfCodeReader = EndOfCodeReader()




public struct UnpopToken: LineReader { // analogous to pushing an existing/modified token back onto the head of the token stream
    
    public var code: String { return reader.code }
    
    private let token: Token
    private let reader: LineReader
    
    public init(_ token: Token, _ reader: LineReader) {
        self.token = token
        self.reader = reader
    }
    
    public func next() -> (Token, LineReader) {
        return (self.token, self.reader)
    }
}

