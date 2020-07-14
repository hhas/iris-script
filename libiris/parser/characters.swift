//
//  characters.swift
//  iris-script
//

import Foundation


// matchable character sets

/*
Unicode 6.0 has 7 character categories, and each category has subcategories:

    Letter (L): lowercase (Ll), modifier (Lm), titlecase (Lt), uppercase (Lu), other (Lo)
    Number (N): decimal digit (Nd), letter (Nl), other (No)
    Symbol (S): currency (Sc), modifier (Sk), math (Sm), other (So)
    Punctuation (P): connector (Pc), dash (Pd), initial quote (Pi), final quote (Pf), open (Ps), close (Pe), other (Po)
    Mark (M): spacing combining (Mc), enclosing (Me), non-spacing (Mn)
    Separator (Z): line (Zl), paragraph (Zp), space (Zs)
    Other (C): control (Cc), format (Cf), not assigned (Cn), private use (Co), surrogate (Cs)

There are 3 ranges reserved for private use (Co subcategory): U+E000—U+F8FF (6,400 code points), U+F0000—U+FFFFD (65,534) and U+100000—U+10FFFD (65,534). Surrogates (Cs subcategory) use the range U+D800—U+DFFF (2,048 code points).

    Letter: 100,520 (91.8%)
        Letter, lowercase (Ll): 1,759
        Letter, uppercase (Lu): 1,436
        Letter, titlecase (Lt): 31
        Letter, modifier (Lm): 210
    Number: 1,100 (1.0%)
    Symbol: 5,508 (5.0%)
        Symbol, math (Sm): 948
        Symbol, currency (Sc): 47
        Symbol, modifier (Sk): 115
    Punctuation: 598 (0.5%)
    Mark: 1,498 (1.4%)
    Separator: 20 (0.0%)
    Other: 205 (0.2%)

*/




// TO DO: what is recommended type for representing a set of Character? CharacterSet smells of NSString and UTF16, which blows chunks outside the base plane (OTOH, we don't want to use Set<Character> as that doesn't scale)

let linebreakCharacters     = CharacterSet.newlines
let whitespaceCharacters    = CharacterSet.whitespaces // TO DO: how to treat vtab, nbsp?
let nonWhitespaceCharacters = whitespaceCharacters.inverted
let digitCharacters         = CharacterSet.decimalDigits // 0-9; parsing
let punctuationCharacters   = CharacterSet(Token.predefinedSymbols.keys.map{ $0.unicodeScalars.first! })



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

let nameCharacters = wordCharacters.union(CharacterSet(charactersIn: "_")) // operator names (these do not include digits)

// -/+ aren't part of core syntax, but do need to be recognized when processing numeric literals so define matchable symbols here
// TO DO: should pretty printer replace ASCII +/- chars with true Unicode symbols?
let minusCharacters    = CharacterSet(charactersIn: "-\u{2212}\u{FF0D}\u{FE63}") // ASCII hyphen, minus sign
let plusCharacters     = CharacterSet(charactersIn: "+\u{FF0B}")
let numericSignCharacters = minusCharacters.union(plusCharacters)

// TO DO: these should really be calculated from predefinedSymbols
let quotedNameDelimiterCharacters = CharacterSet(charactersIn: "'‘’") // TO DO: what about Unicode apostrophes? (semantically distinct but visually similar)
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
        return !self.isEmpty && CharacterSet(charactersIn: self).subtracting(characters).isEmpty
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

