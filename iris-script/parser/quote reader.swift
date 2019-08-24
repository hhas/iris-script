//
//  quote reader.swift
//  iris-script
//

import Foundation


struct QuoteReader: BlockReader { // reduces quoted text (string literal or annotation) to single token
    
    typealias Location = (lineIndex: Int, tokenIndex: Int) // note: these will not be contiguous
    
    let nextReader: BlockReader
    
    var code: String { return self.nextReader.code }
    
    let token: Token
    let location: Location
    
    
    init(_ reader: BlockReader) { // TO DO: check this leaves cursor on correct token in all cases
        let startToken = reader.token
        self.location = reader.location // start position only (not sure how to tell editable script about reductions)
        var reader = reader.next()
        switch startToken.form {
        case .startAnnotation:
            var s = String(startToken.whitespaceAfter ?? "")
            while reader.token.form != .endAnnotation {
                if reader.token.form == .endOfScript { fatalError("expected `»` but found end of code") }
                s += reader.token.content + (reader.token.whitespaceAfter ?? "")
                reader = reader.next()
            }
            let endToken = reader.token
            self.token = Token(.annotation(s),
                               startToken.whitespaceBefore,
                               reader.code[startToken.content.startIndex..<endToken.content.endIndex], endToken.whitespaceAfter,
                               startToken.position.span(to: endToken.position))
            reader = reader.next()
        case .endAnnotation:
            fatalError("found unbalanced `»`") // TO DO
        case .stringDelimiter:
            var s = String(startToken.whitespaceAfter ?? "")
            while true {
                if reader.token.form == .stringDelimiter { //
                    if reader.token.isRightContiguous && reader.next().token.form == .stringDelimiter { // double-quote chars are self-escaping, e.g. "Bob says ""Hello"" to Jane."
                        
                    } else {
                        break
                    }
                }
                s += reader.token.content + (reader.token.whitespaceAfter ?? "")
                reader = reader.next()
            }
            let endToken = reader.token
            self.token = Token(.value(Text(s)),
                               startToken.whitespaceBefore,
                               reader.code[startToken.content.startIndex..<endToken.content.endIndex], // TO DO: confirm slicing original string with substrings' indexes is legal
                endToken.whitespaceAfter,
                startToken.position.span(to: endToken.position))
            reader = reader.next()
        default:
            self.token = startToken
        }
        self.nextReader = reader
    }
    
    
    func next() -> BlockReader {
        return QuoteReader(self.nextReader)
    }
    
}
