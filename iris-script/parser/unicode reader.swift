//
//  unicode reader.swift
//  iris-script
//

import Foundation

// TO DO: if an 0u sequence appears where a literal name is expected, convert to Symbol rather than Text? or should we limit it to strings, in which case some sort of cast is required (we can't put 0u sequences in single-quotes, as that would be inconsistent with double-quoted text's behavior; while a dedicated annotation type could work, that'd be inconsistent with unquoted 0u sequences)


struct UnicodeReader: LineReader { // needs applied before NumericReader
    
    let reader: LineReader
    
    var code: String { return self.reader.code }
    
    init(_ reader: LineReader) {
        self.reader = reader
    }
    
    func readCodepoint(_ reader: LineReader) -> (Character, Token, LineReader)? {
        let (token, reader) = reader.next()
        if case .letters = token.form, token.isRightContiguous, token.content.lowercased().hasPrefix("u") {
            var codepoint = token.content.dropFirst()
            var (token, reader) = reader.next()
            var endToken = token
            var endReader = reader
            while token.isLeftContiguous, [.digits, .letters].contains(token.form) {
                endReader = reader
                endToken = token
                codepoint += token.content
                (token, reader) = reader.next()
            }
            if !codepoint.isEmpty, let n = Int(codepoint, radix: 16), let c = UnicodeScalar(n) {
                return (Character(c), endToken, endReader)
            }
        }
        return nil
    }
    
    func next() -> (Token, LineReader) {
        var (token, reader) = self.reader.next()
        let startToken = token
        var result = ""
        var (endToken, endReader) = (token, reader)
        while case .digits = token.form, token.isLeftDelimited, token.isRightContiguous, token.content == "0" {
            guard let (c, t, r) = self.readCodepoint(reader) else { break }
            result += String(c)
            (endToken, endReader) = (t, r)
            (token, reader) = endReader.next()
        }
        if !result.isEmpty {
            // TO DO: what about annotating Text for PP?
            // TO DO: also need to decide if/where contiguous string literals and/or 0u sequences should be merged into single Text value
            endToken = Token(.value(Text(result)), startToken.whitespaceBefore, self.code[startToken.content.startIndex..<endToken.content.endIndex], endToken.whitespaceAfter, startToken.position.span(to: endToken.position))
            //print(endToken)
        }
        return (endToken, UnicodeReader(endReader))
    }
}
