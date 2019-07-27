//
//  script reader.swift
//  iris-script
//

import Foundation



protocol ScriptReader {
    
    typealias Location = (lineIndex: Int, tokenIndex: Int)
    
    var code: String { get }
    
    var token: Token { get } // the current token
    var location: Location { get } // the current token's position

    func next() -> ScriptReader?
}



struct TokenStream: ScriptReader {
    
    private let script: ImmutableScript
    
    var code: String { return script.code }
    
    let token: Token // the current token
    let location: Location // the current token's position
    
    private init(script: ImmutableScript, lineIndex: Int, tokenIndex: Int) {
        self.script = script
        self.location = (lineIndex, tokenIndex)
        self.token = script.lines[lineIndex].tokens[tokenIndex]
    }
    
    init?(_ script: ImmutableScript) {
        guard let i = script.lines.firstIndex(where: { !$0.isEmpty }) else { return nil }
        self.init(script: script, lineIndex: i, tokenIndex: 0)
    }
    
    func next() -> ScriptReader? { // returns a new TokenStream identifying the next token
        if self.location.lineIndex < self.script.lines.count {
            let i = self.location.tokenIndex + 1
            if i < self.script.lines[self.location.lineIndex].tokens.count {
                return TokenStream(script: script, lineIndex: self.location.lineIndex, tokenIndex: i)
            } else if let i = self.script.lines.suffix(from: self.location.lineIndex + 1).firstIndex(where: { !$0.isEmpty }) {
                return TokenStream(script: script, lineIndex: i, tokenIndex: 0)
            }
        }
        return nil
    }
}


extension EditableScript {
    
    var tokenStream: TokenStream? { return TokenStream(ImmutableScript(lines: self.lines, code: self.code)) }
    
}




struct QuoteReader: ScriptReader { // reduces quoted text (string literal or annotation) to single token
    
    typealias Location = (lineIndex: Int, tokenIndex: Int) // note: these will not be contiguous
    
    let nextReader: ScriptReader?
    
    var code: String { return self.nextReader?.code ?? "" }
    
    let token: Token
    let location: Location
    
    
    init(_ reader: ScriptReader) {
        var reader = reader
        let startToken = reader.token
        self.location = reader.location // start position only (not sure how to tell editable script about reductions)
        switch startToken.form {
        case .startAnnotation:
            var s = String(startToken.whitespaceAfter ?? "")
            while let r = reader.next() {
                reader = r
                if r.token.form == .endAnnotation { break }
                let t = reader.token
                s += t.content + (t.whitespaceAfter ?? "")
            }
            let endToken = reader.token
            self.token = Token(.annotation(s),
                               startToken.whitespaceBefore,
                               reader.code[startToken.content.startIndex..<endToken.content.endIndex], endToken.whitespaceAfter,
                               startToken.position.span(to: endToken.position))
        case .endAnnotation:
            fatalError("found unbalanced `»`") // TO DO
        case .stringDelimiter:
            var s = String(startToken.whitespaceAfter ?? "")
            while let r = reader.next() {
                reader = r
                if r.token.form == .stringDelimiter { break } // TO DO: need to check if there's a 2nd contiguous .stringDelimiter; if there is, continue
                let t = reader.token
                s += t.content + (t.whitespaceAfter ?? "")
            }
            let endToken = reader.token
            self.token = Token(.value(Text(s)),
                               startToken.whitespaceBefore,
                               reader.code[startToken.content.startIndex..<endToken.content.endIndex], // TO DO: confirm slicing original string with substrings' indexes is legal
                               endToken.whitespaceAfter,
                               startToken.position.span(to: endToken.position))
        default:
            self.token = startToken
        }
        self.nextReader = reader.next()
    }
    
    
    func next() -> ScriptReader? {
        guard let reader = self.nextReader else { return nil }
        return QuoteReader(reader)
    }

}
