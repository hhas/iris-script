//
//  name reader.swift
//  iris-script
//

import Foundation

// note: one reason for treating underscore as separate token is to facilitate context-aware matching of spoken phrases during incremental voice input (e.g. within tell Finder block, it's natural to say "get first document file of home"; a longest-match heuristic can reasonably assume that "document file" is a single name, given it appears in Finder's dictionary, `document_file`, and insert the underscore automatically; the less likely interpretation, `document {file}`, would require an explicit control to put `file` in argument to `document` command); Q. what, if anything, can emacs/vi teach us about good modal input UI design?


public struct NameReader: LineReader {

    // reduces contiguous .letters, .underscore, and/or [subsequent] .digits to .unquotedName; optionally reduces .[un]quotedName + .colon sequence to .label
    
    private let reader: LineReader
    private let reduceLabels: Bool // if true, also reduce `NAME COLON` to .label(NAME)
    
    public var code: String { return self.reader.code }
    
    public init(_ reader: LineReader, reduceLabels: Bool = true) {
        self.reader = reader
        self.reduceLabels = reduceLabels
    }
    
    public func next() -> (Token, LineReader) {
        var (token, reader) = self.reader.next()
        // TO DO: what about .symbols?
        switch token.form {
        case .letters, .underscore:
            let startToken = token
            var (nextToken, nextReader) = reader.next()
            while token.isRightContiguous && [.letters, .underscore, .digits].contains(nextToken.form) {
                (token, reader) = (nextToken, nextReader)
                (nextToken, nextReader) = reader.next()
            }
            let endToken = token
            let name = Symbol(String(self.sliceCode(from: startToken, to: endToken)))
            if case .colon = nextToken.form, self.reduceLabels {
                token = self.newToken(for: .label(name), from: startToken, to: nextToken)
                reader = nextReader
            } else {
                token = self.newToken(for: .unquotedName(name), from: startToken, to: endToken)
            }
        case .quotedName(let name) where self.reduceLabels:
            let (nextToken, nextReader) = reader.next()
            if case .colon = nextToken.form {
                token = self.newToken(for: .label(name), from: token, to: nextToken)
                reader = nextReader
            }
        default: ()
        }
        return (token, NameReader(reader))
    }
    
}




public struct NameModifierReader: LineReader { // read hashtag, mentions, dot-notation // TO DO: currently only `#NAME` is implemented (Q. should dot notation be limited to `@NAME.NAME…`, or might it also be used outside of `@…`?)
    
    public var code: String { return reader.code }
    
    private let reader: LineReader
    
    public init(_ reader: LineReader) {
        self.reader = reader
    }
    
    public func next() -> (Token, LineReader) {
        var (startToken, reader) = self.reader.next()
        switch startToken.form {
        case .hashtag, .mentions:
            let (endToken, endReader) = reader.next()
            switch endToken.form {
            case .quotedName(let name), .unquotedName(let name):
                switch startToken.form {
                case .hashtag:
                    startToken = self.newToken(for: .value(name), from: startToken, to: endToken)
                default: fatalError("TODO: support .mentions token")
                }
                reader = endReader
            default: ()
            }
        default: ()
        }
        return (startToken, NameModifierReader(reader))
    }
}

