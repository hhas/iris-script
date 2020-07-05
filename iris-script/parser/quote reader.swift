//
//  quote reader.swift
//  iris-script
//

//  TO DO: if we treat «…» and «TODO:…» as developer comments (private), how should user documentation be indicated? alternatively, we could treat «…» as either depending on context (e.g. in handler definitions, the operator syntax provides natural attach points for command [name], argument [parameter], and result descriptions)

import Foundation


struct QuoteReader: DocumentReader { // reduces quoted text (string literal or annotation) to single token
    
    typealias Location = (lineIndex: Int, tokenIndex: Int) // note: these will not be contiguous
    
    let nextReader: DocumentReader
    
    var code: String { return self.nextReader.code }
    
    let token: Token
    let location: Location
    
    
    init(_ reader: DocumentReader) { // TO DO: check this leaves cursor on correct token in all cases
        let startToken = reader.token
        self.location = reader.location // start position only (not sure how to tell editable script about reductions)
        var reader = reader.next()
        switch startToken.form {
        case .startAnnotation:
            var s = String(startToken.whitespaceAfter ?? "")
            while reader.token.form != .endAnnotation {
                if reader.token.form == .endOfScript { fatalError("expected `»` but found end of code") } // TO DO: output .error(…)
                s += reader.token.content + (reader.token.whitespaceAfter ?? "")
                reader = reader.next()
            }
            let endToken = reader.token
            self.token = Token(.annotation(s),
                               startToken.whitespaceBefore,
                               // TO DO: this slice fails if `»` appears on a new line (think we need to fix .lineBreak tokens so they contain the original linebreaks, not empty placeholder); we should probably also capture original string's indexes within Token, rather than taking them from substrings (which may be both undocumented behavior and a golden opportunity for obscure bugs to sneak in [not to mention it's just a right old pain]); alternatively, implement a proper code-slicing API on Token that takes the start and end tokens and a new Form and synthesizes a new Token spanning from start of one to end of the other (which is what this line and others are trying to do in awkwardly repetitive and ad-hoc fashion)
                               reader.code[startToken.content.startIndex..<endToken.content.endIndex], endToken.whitespaceAfter,
                               startToken.position.span(to: endToken.position)) // TO DO: make sure this picks up entire content
            reader = reader.next()
        case .endAnnotation:
            fatalError("found unbalanced `»`") // TO DO: ditto
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
    
    
    func next() -> DocumentReader {
        return QuoteReader(self.nextReader)
    }
    
}
