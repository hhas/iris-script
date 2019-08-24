//
//  name reader.swift
//  iris-script
//

import Foundation

// note: one reason for treating underscore as separate token is to facilitate context-aware matching of spoken phrases during incremental voice input (e.g. within tell Finder block, it's natural to say "get first document file of home"; a longest-match heuristic can reasonably assume that "document file" is a single name, given it appears in Finder's dictionary, `document_file`, and insert the underscore automatically; the less likely interpretation, `document {file}`, would require an explicit control to put `file` in argument to `document` command); Q. what, if anything, can emacs/vi teach us about good modal input UI design?


struct NameReader: LineReader {
    
    let reader: LineReader
    
    var code: String { return self.reader.code }
    
    init(_ reader: LineReader) {
        self.reader = reader
    }
    
    func next() -> (Token, LineReader) {
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
            let name = self.code[startToken.content.startIndex..<endToken.content.endIndex]
            token = Token(.unquotedName(String(name)), startToken.whitespaceBefore, name,
                          endToken.whitespaceAfter, startToken.position.span(to: endToken.position))
        //print("read name:", token, reader)
        default: ()
        }
        return (token, NameReader(reader))
    }
    
}
