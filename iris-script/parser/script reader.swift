//
//  script reader.swift
//  iris-script
//

import Foundation


// TO DO: need a reader to intercept top-level include/exclude annotations and load the specified libraries' syntax into the parser's operator registry, and flag those libraries handlers' for direct inclusion in the script's global namespace (note: this reader is active only until the first code token is encountered, whereupon it removes itself from the reader chain/replaces itself with a reader that throws on any subsequent includes/excludes [right now we don't have an easy way to restrict availability of library-defined operators to a sub-scope c.f. AppleScript's `tell application…` blocks, and it's debatable whether we'd want to anyway])


// Q. how to splice line edits into an existing reader stream? e.g. assume the script `A B C`, if B is 'edited' - i.e. replaced by D - then A and C are undisturbed; thus we restart parsing from end of A, now reading D instead of A, and on completion of D we want to reconcile with the previous parse of C, firstly by comparing the balance at end of D to balance at end of B/beginning of C (any difference means a correction or error has been introduced), then reusing as much as possible of A and C's previous parse sub-trees (AST nodes) in completing the `A D C` iteration's revised parse tree (for sake of sanity, we want to synchronize at the per-line level, not per-token; which is still a lot more precise than synchronizing at the top-level statement level, especially when determining where new syntax errors are introduced during interactive editing and limiting the scope of their effect)


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
