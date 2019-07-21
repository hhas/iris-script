//
//  parser protocols.swift
//  iris-script
//

import Foundation


// extensible lexing/parsing, with emphasis on per-line processing to enable cheap, easy incremental re-parsing when code editing; i.e. we should treat text as text: if the user wants to express syntactically invalid constructs [e.g. pseudocode, plain language remarks] while formulating their scripts, let them do so freely without constant hassling about "syntax errors"; however, this should not prevent partial opportunistic parsing of those sections of script that do resemble valid code; in addition, we want to assist user with parens balancing when writing new code/rearranging existing code, and this includes having the smarts to make best-guesses at where missing opening/closing parens are meant to appear while code is unbalanced (e.g. if initial script is correctly balanced, then user adds/cuts/pastes/deletes some code in the middle that unbalances it, the editor can reasonably assume that the rebalancing should probably be done within or close to the edges of the affected area; i.e. an extra '[' near the start of the script should NOT throw a syntax error indicating a missing ']' at the end of the script; thus `balanced`->EDIT->`balanced unbalanced balanced`->REVIEW->`balanced unbalanced REPORT balanced`, NOT `balanced unbalanced balanced REPORT`) [e.g. in a mixed statement+expression language like Python, an unbalanced `[…]` or `(…)` would be detected at the start of the next statement, which is cheap and easy, but statements are a lousy code construct in every other respect—conceptual and implementation complexity, no composability, no extensibility—compared to expression-only syntax, so we must find other, smarter ways to provide cheap, easy boundary identification]


// note: while multi-step lexing is worse than single-pass O(n) lexing where all tokens are fully delimited and tagged, it shouldn't be drastically worse; i.e. initially undifferentiated words may be re-traversed two or three times as they are progressively broken down and precisely categorized; still, these might only account for 50% of the original code; the biggest hit will be string and annotation literals, as single-line lexing must tokenize their content even though those tokens will eventually be discarded once multi-line parsing correctly identifies the beginning and end of each quoted run; e.g. given `say "Hello, World!"`, there's no way for single-line reader to know sure that `say` is code and `Hello, World!` is quoted; it may be that the actual quoting started on an earlier line, in which case `say` is inside the quotes and `Hello, World!` are code [e.g. postfix `Hello` operator and `World` command], followed by a new string literal; in practice, there are some simple rules by which the relative likelihoods of each interpretation may be calculated; e.g. if there is a known operator named `hello` and a command or operator named `world` then either interpretation looks valid, otherwise it's far more likely that the quoted text is `Hello, World!`, even if an unbalanced `"` delimiter on an earlier line would tell a 'dumb' scanner [e.g. AppleScript's] otherwise


// TO DO: how should we represent the entire script decomposed into lines? there are two ways we could do this: 1. use script.split(omittingEmptySubsequences: false, whereSeparator: linebreakCharacters.contains) to split the script into lines on first pass, with line lexers performing a second pass, or 2. have LineReader take the entire script plus starting index, and populate the line array from that; TBH, the extra string copying is probably the least of our startup performance worries when parsing scripts for execution only (bear in mind that downstream readers will tend to re-traverse word tokens' content), while doing one big string split at the start puts us in a solid position for supporting incremental parsing when operating in code editing/REPL modes



protocol TokenReader { // common API by which [partial] lexers and parsers can be chained together, in order to generate and consume tokens (and not solely in that order), and so incrementally convert the initial [and, in interactive code editing mode, mutable] source code to a complete AST [or again ,in editing mode, a mixture of completed sub-trees and unresolved tokens]
    
    // think we need a var to get at original code from which token's substrings is being obtained; i.e. if we want to 'concatenate' multiple substrings, not sure if slicing a substring with out-of-bounds indexes gets us back to original code or crash
    
    var code: String { get } // used when getting content substring spanning multiple tokens (caution: this includes raw whitespace between tokens; use e.g. matchedTokens.map{$0.content}.joined(separator:" ") to get whitespace-normalized content)
    
    func next() -> (Token, TokenReader) // returns next token plus a reader for the remaining tokens (i.e. each reader represents a fixed point in the token stream, so to backtrack in next() just return the result token along with the tokenreader associated with the last token consumed)
}



protocol Lexeme { // the first-stage LineReader lexer is only concerned with identifying core punctuation and contiguous digits, and does not decompose or differentiate other content beyond .letters tokens, leaving downstream readers to deal with those, e.g. when using library-defined operators, `OperatorLexeme` should describe the
    
    // TO DO: what common interface should Lexemes expose
}






// matchable character sets


// TO DO: what is recommended type for representing a set of Character? CharacterSet smells of NSString and UTF16, which blows chunks outside the base plane (OTOH, we don't want to use Set<Character> as that doesn't scale)

let linebreakCharacters     = CharacterSet.newlines
let whitespaceCharacters    = CharacterSet.whitespaces // TO DO: how to treat vtab, nbsp?
let nonWhitespaceCharacters = whitespaceCharacters.inverted
let digitCharacters         = CharacterSet.decimalDigits // 0-9; parsing
let punctuationCharacters   = CharacterSet(Token.corePunctuation.keys.map{ $0.unicodeScalars.first! })



// key characters specifically recognized by lexer
let _coreCharacters    = linebreakCharacters.union(whitespaceCharacters).union(digitCharacters).union(punctuationCharacters)

// non-printing control characters and illegal Unicode (we don't want these appearing anywhere in code, not even in string literals)
// TO DO: are there any control characters we do need to allow?
let _controlCharacters = CharacterSet.controlCharacters.subtracting(CharacterSet.whitespacesAndNewlines)
let _invalidCharacters = CharacterSet.illegalCharacters.union(_controlCharacters)

// non-core punctuation and symbol chars (P* + S* - core-punctuation chars)
let symbolCharacters   = CharacterSet.punctuationCharacters.union(CharacterSet.symbols).subtracting(punctuationCharacters)


// TO DO: should wordCharacters be defined as CharacterSet.letters (L* + M*)? i.e. opt-in rather than opt-out?
let wordCharacters     = _coreCharacters.inverted.subtracting(symbolCharacters).subtracting(_invalidCharacters) // undifferentiated text; downstream tokenizers and parsers may consume as-is, decompose and output as new tokenstreams, halt on as unrecoverable 'syntax error' (not recommended for editing mode, but may be preferable when parsing for execution only), or some combination

// -/+ aren't part of core syntax, but do need to be recognized when processing numeric literals so define matchable symbols here
// TO DO: should pretty printer replace ASCII +/- chars with true Unicode symbols?
let minusCharacters    = CharacterSet(charactersIn: "-\u{2212}\u{FF0D}\u{FE63}")
let plusCharacters     = CharacterSet(charactersIn: "+\u{FF0B}")
let numericSignCharacters = minusCharacters.union(plusCharacters)

// TO DO: these should really be calculated from corePunctuation
let quotedNameDelimiterCharacters = CharacterSet(charactersIn: "'‘’")
let quotedStringDelimiterCharacters = CharacterSet(charactersIn: "\"“”")
let annotationDelimiterCharacters = CharacterSet(charactersIn: "«»")

// characters that may appear within single quotes
let quotedNameCharacters = (quotedNameDelimiterCharacters.union(quotedStringDelimiterCharacters)
                            .union(annotationDelimiterCharacters).union(linebreakCharacters).union(_invalidCharacters)).inverted


// hex numbers will be decomposed into `[+|-]? 0 [xX] [ DIGITS | WORDS ]+`
let hexadecimalMarkerCharacters = CharacterSet(charactersIn: "xX") // e.g. 0x12AB
let hexadecimalCharacters = CharacterSet(charactersIn: "aAbBcCdDeEfF") // e.g. 0x12AB

let exponentMarkerCharacters = CharacterSet(charactersIn: "eE") // scientific-notation, e.g. 1.23e-5



extension String {

    func conforms(to characters: CharacterSet) -> Bool { // checks string contains characters in given set only
        return self != "" && CharacterSet(charactersIn: self).subtracting(characters) == []
    }

}


extension CharacterSet { // being UTF16-y, CharacterSet works with single codepoints, so won't work outside of base plane // TO DO: what to replace CharacterSet with?
    
    func contains(_ character: Character) -> Bool {
        assert(character.unicodeScalars.count == 1)
        guard let c = character.unicodeScalars.first else { return false }
        return self.contains(c) // kludge
    }
    
    func contains(_ character: Substring) -> Bool { // TO DO: this is receiving entire word; why? (it's NumericReader.readSign; it just chucks the entire word)
        //assert(character.unicodeScalars.count == 1, "<\(character)> <\(character.unicodeScalars)>")
        guard character.count == 1, let c = character.unicodeScalars.first else { return false }
        return self.contains(c) // kludge
    }
}

extension CharacterSet { // convenience extension, allows CharacterSet instances to be matched directly by 'switch' cases
    
    static func ~= (a: CharacterSet, b: Unicode.Scalar) -> Bool {
        return a.contains(b)
    }
    static func ~= (a: CharacterSet, c: Character) -> Bool {
        guard let b = c.unicodeScalars.first, c.unicodeScalars.count == 1 else { return false }
        return a ~= b
    }
    static func ~= (a: CharacterSet, s: String) -> Bool {
        return s.conforms(to: a)
    }
}

