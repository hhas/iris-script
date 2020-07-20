//
//  quote reader.swift
//  iris-script
//
//  modified version of document readers’ quote reader
//
//  TO DO: this is temporary implementation and currently doesn’t work right if quoted text contains linebreaks

//  TO DO: what about defining a .partiallyQuotedText(type,content) token form? that should allow interim reduction of text between quote and linebreak (not sure how this should signal to next line that it should continue reading quoted content, but can think about that later; ideally, we also want a heuristic for making "best guess" as to whether a given text is intended to appear inside or outside quotes, providing error messages and autocorrection with smarter boundary detection when quoted text is missing closing quote)

// TO DO: when scanning a line to best-guess if it’s inside or outside quotes, need a negative-probability heuristic for "word word word word…" sequences as while these are valid code they are unlikely to be as commands rarely nest more than 2 or 3 deep in real-world use

import Foundation


public struct QuoteReader: LineReader { // reduces quoted text (string literal or annotation) to single token
    
    private let nextReader: LineReader
    
    public var code: String { return self.nextReader.code }
    
    public init(_ reader: LineReader) { // TO DO: check this leaves cursor on correct token in all cases
        self.nextReader = reader
    }
    
    public func next() -> (Token, LineReader) {
        var (startToken, reader) = self.nextReader.next()
        var token = startToken
        switch startToken.form {
        case .startAnnotation:
            var s = String(startToken.trailingWhitespace ?? "")
            (token, reader) = reader.next()
            while token.form != .endAnnotation {
                if token.form == .endOfCode { fatalError("expected `»` but found end of code") } // TO DO: output .error(…)
                s += token.content + (token.trailingWhitespace ?? "")
                (token, reader) = reader.next()
            }
            let endToken = token
            token = self.newToken(for: .annotation(s), from: startToken, to: endToken) // TO DO: this slice fails if `»` appears on a new line (think we need to fix .lineBreak tokens so they contain the original linebreaks, not empty placeholder); we should probably also capture original string's indexes within Token, rather than taking them from substrings (which may be both undocumented behavior and a golden opportunity for obscure bugs to sneak in [not to mention it's just a right old pain]); alternatively, implement a proper code-slicing API on Token that takes the start and end tokens and a new Form and synthesizes a new Token spanning from start of one to end of the other (which is what this line and others are trying to do in awkwardly repetitive and ad-hoc fashion)
        case .endAnnotation:
            fatalError("found unbalanced `»`") // TO DO: ditto
        case .stringDelimiter:
            var s = String(startToken.trailingWhitespace ?? "")
            (token, reader) = reader.next()
            while true {
                
                // TO DO: FIX: a stray (unbalanced) double quote causes this to loop endlessly
                
                if token.form == .stringDelimiter { //
                    if token.isRightContiguous && reader.next().0.form == .stringDelimiter { // double-quote chars are self-escaping, e.g. "Bob says ""Hello"" to Jane."
                        (token, reader) = reader.next() // step over the extra quote
                    } else {
                        break
                    }
                }
                s += token.content + (token.trailingWhitespace ?? "")
                (token, reader) = reader.next()
            }
            let endToken = token
            token = self.newToken(for: .value(Text(s)), from: startToken, to: endToken)
        default:
            token = startToken
        }
        return (token, QuoteReader(reader))
    }
    
}
