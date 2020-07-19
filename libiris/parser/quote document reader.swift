//
//  quote reader.swift
//  iris-script
//

//  TO DO: if we treat «…» and «TODO:…» as developer comments (private), how should user documentation be indicated? alternatively, we could treat «…» as either depending on context (e.g. in handler definitions, the operator syntax provides natural attach points for command [name], argument [parameter], and result descriptions)

// TO DO: this reader handles multi-line strings and annotations, but has different API to line readers; we need to standardize on a single API for lexers and lexer adapters, and figure how best to track line and column positions in such a way that it can report token locations at any point from original input string to pretty printed output (this includes UTF8-encoded char* buffer with VT100 codes, NSAttributedString, HTML, and anything else)

import Foundation


public struct QuoteDocumentReader: DocumentReader { // reduces quoted text (string literal or annotation) to single token
    
    public typealias Location = (lineIndex: Int, tokenIndex: Int) // note: these will not be contiguous
    
    private let nextReader: DocumentReader
    
    public var code: String { return self.nextReader.code }
    
    public let token: Token
    public let location: Location
    
    
    public init(_ reader: DocumentReader) { // TO DO: check this leaves cursor on correct token in all cases
        let startToken = reader.token
        self.location = reader.location // start position only (not sure how to tell editable script about reductions)
        var reader = reader.next()
        switch startToken.form {
        case .startAnnotation:
            var s = String(startToken.trailingWhitespace ?? "")
            while reader.token.form != .endAnnotation {
                if reader.token.form == .endOfCode { fatalError("expected `»` but found end of code") } // TO DO: output .error(…)
                s += reader.token.content + (reader.token.trailingWhitespace ?? "")
                reader = reader.next()
            }
            let endToken = reader.token
            self.token = Token(.annotation(s),
                               startToken.leadingWhitespace,
                               // TO DO: this slice fails if `»` appears on a new line (think we need to fix .lineBreak tokens so they contain the original linebreaks, not empty placeholder); we should probably also capture original string's indexes within Token, rather than taking them from substrings (which may be both undocumented behavior and a golden opportunity for obscure bugs to sneak in [not to mention it's just a right old pain]); alternatively, implement a proper code-slicing API on Token that takes the start and end tokens and a new Form and synthesizes a new Token spanning from start of one to end of the other (which is what this line and others are trying to do in awkwardly repetitive and ad-hoc fashion)
                               reader.code[startToken.content.startIndex..<endToken.content.endIndex], endToken.trailingWhitespace,
                               startToken.position.span(to: endToken.position)) // TO DO: make sure this picks up entire content
            reader = reader.next()
        case .endAnnotation:
            fatalError("found unbalanced `»`") // TO DO: ditto
        case .stringDelimiter:
            var s = String(startToken.trailingWhitespace ?? "")
            while true {
                
                // TO DO: FIX: a stray (unbalanced) double quote causes this to loop endlessly
                
                if reader.token.form == .stringDelimiter { //
                    if reader.token.isRightContiguous && reader.next().token.form == .stringDelimiter { // double-quote chars are self-escaping, e.g. "Bob says ""Hello"" to Jane."
                        
                    } else {
                        break
                    }
                }
                s += reader.token.content + (reader.token.trailingWhitespace ?? "")
                reader = reader.next()
            }
            let endToken = reader.token
            self.token = Token(.value(Text(s)),
                               startToken.leadingWhitespace,
                               reader.code[startToken.content.startIndex..<endToken.content.endIndex], // TO DO: confirm slicing original string with substrings' indexes is legal
                endToken.trailingWhitespace,
                startToken.position.span(to: endToken.position))
            reader = reader.next()
        default:
            self.token = startToken
        }
        self.nextReader = reader
    }
    
    
    public func next() -> DocumentReader {
        return QuoteDocumentReader(self.nextReader)
    }
    
}
