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
            var depth = 1
            (token, reader) = reader.next()
            while token.form != .endOfCode {
                switch token.form {
                case .startAnnotation:
                    depth += 1
                case .endAnnotation:
                    depth -= 1
                    if depth == 0 { break }
                default: ()
                }
                s += token.content + (token.trailingWhitespace ?? "")
                (token, reader) = reader.next()
            }
            if token.form == .endOfCode {
                fatalError("TODO")
                
            } else {
                token = self.newToken(for: .annotation(s), from: startToken, to: token) // TO DO: this slice fails if `»` appears on a new line (think we need to fix .lineBreak tokens so they contain the original linebreaks, not empty placeholder); we should probably also capture original string's indexes within Token, rather than taking them from substrings (which may be both undocumented behavior and a golden opportunity for obscure bugs to sneak in [not to mention it's just a right old pain]); alternatively, implement a proper code-slicing API on Token that takes the start and end tokens and a new Form and synthesizes a new Token spanning from start of one to end of the other (which is what this line and others are trying to do in awkwardly repetitive and ad-hoc fashion)
            }
        case .endAnnotation:
            fatalError("found unbalanced `»`") // TO DO: ditto
        case .stringDelimiter:
            var s = String(startToken.trailingWhitespace ?? "")
            var (prevToken, prevReader) = (token, reader)
            (token, reader) = reader.next()
            while true {
                if case .endOfCode = token.form { // closing quote was not found
                    let form = Token.Form.beginningOfQuote(kind: .string, content: s,
                                                           leadingWhitespace: startToken.leadingWhitespace)
                    return (self.newToken(for: form, from: startToken, to: prevToken), prevReader)
                    
                }
                (prevToken, prevReader) = (token, reader)
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


public struct RemainingStringQuoteReader: LineReader {
        
    // TO DO: `code` is new code only (caution: next() relies on this assumption); however, BaseLexer expects entire code, plus offset from which to start reading; what downstream code relies on `code`?
    
    public typealias ResumeLexer = (String) -> LineReader // TO DO: what about resume index, etc?
    
    private let resumeLexer: ResumeLexer
    
    public let code: String
    
    public init(_ code: String, resumeLexer: @escaping ResumeLexer) { // TO DO: should this take entire (concatenated) code + an index at which to resume lexing (see above TODO)
        self.code = code
        self.resumeLexer = resumeLexer
    }
        
    public func next() -> (Token, LineReader) {
        let form: Token.Form
        let token: Token
        let reader: LineReader
        if let offset = self.code.firstIndex(where: quotedStringDelimiterCharacters.contains) { // found end of string literal // TO DO: unless next char is also quote, in which case consume first quote, step over second, and continue
            let trailingWhitespace: Substring?
            let remainingIndex = self.code.index(after: offset)
            let restartIndex = self.code.suffix(from: remainingIndex).firstIndex(where: { !whitespaceCharacters.contains($0) }) ?? self.code.endIndex
            if restartIndex < self.code.endIndex { // TO DO: also check if remaining substring is whitespace only
                if remainingIndex < restartIndex {
                    trailingWhitespace = self.code[remainingIndex..<restartIndex]
                } else {
                    trailingWhitespace = nil // TO DO: trailingWhitespace
                }
                // TO DO: upon resuming code parsing, this needs to construct full lexer chain, which requires passing a lexer constructor to init and calling it here, not calling BaseLexer directly
                reader = self.resumeLexer(self.code)
            } else {
                trailingWhitespace = nil
                reader = EndOfCodeReader()
            }
            // TO DO: what should be startindex of content? (depends if code is entire code, or just new [line of] code)
            form = .endOfQuote(kind: .string, content: String(self.code[self.code.startIndex..<offset]))
            token = Token(form, nil, self.code[self.code.startIndex..<offset], trailingWhitespace, .first)
        } else {
            form = .middleOfQuote(kind: .string, content: self.code)
            token = Token(form, nil, Substring(self.code), nil, .full)
            reader = EndOfCodeReader()
        }
        return (token, reader)
    }
}

// TO DO: public struct RemainingAnnotationQuoteReader: LineReader
