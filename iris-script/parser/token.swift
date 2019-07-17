//
//  token.swift
//  iris-script
//

import Foundation



// TO DO: single-line parsing should take a tip from bookkeeping: when balancing a ledger, insert the amount needed to balance CR and DR columns; in this case, where parensed exprs are unbalanced, insert 'placeholder' tokens at start [and/or end?] of line to make that line into a valid expr [sequence]; [Q. should end of each line be 'carry forwards', to be balanced against the expected 'brought forwards' on the next?]


// TO DO: should lexer/parser be concerned with NFC/NFD?


struct Token: CustomStringConvertible {
    
    // tokenization is minimal, recognizing only core punctuation, contiguous digits, whitespace (as delimiter), and words (everything else); determining which tokens actually appear inside string literals and annotations [meaning they're not real tokens after all], assembling complete number literals from multiple tokens, distinguishing operator names from non-operator words [including contiguous combinations where both appear within the same token, e.g. `a*b/c`], etc is left to downstream consumers
    
    var description: String { // underscore before/after quoted token text indicates adjoining whitespace
        return "<.\(self.form) \(self.whitespaceBefore == nil ? "" : "_")\(self.content.debugDescription)\(self.whitespaceAfter == nil ? "" : "_")>"
    }
    
    // Q. what about non-Latin scripts? e.g. Arabic comma is `،` (don't suppose NFKC remaps it to `,`?); probably best to rely on top-level «language:…» annotation to switch/extend lexer's character sets [we can worry about implementing that later]
    
    enum Form { // core punctuation, plus digits and non-digit text
        case startAnnotation    // «
        case endAnnotation      // »
        case startList          // [
        case endList            // ]
        case startRecord        // {
        case endRecord          // }
        case startGroup         // (
        case endGroup           // )
        case comma              // ,
        case semicolon          // ;
        case colon              // :
        case period             // .
        case query              // ?
        case exclamation        // !
        case hash               // #
        case at                 // @
        case stringDelimiter    // any of "“” // note: unlike other grouping delimiters (lists, records, parens, annotations), string quotes do not provide clear indication as to whether start of line is inside or outside quoted text; therefore we tokenize everything and leave the parser to figure out which it is (this is slower than tokenizing the full script, but better able to deal with extra/missing quotes, using both line-by-line balance counts and simple best-guess heuristics comparing relative frequencies of tell-tale characters and words [e.g. known command and operator names, punctuation])
        
        case quotedName         // 'WORD' (quotes may be any of '‘’; WORD may be any character other than whitespace[?] or core punctuation) // single-quotes always appear on single line, without leading/trailing whitespace around the quoted text (the outer edges of the quotes should always be separator/delimiter punctuation or whitespace, although we do need to confirm this, e.g. it's probably reasonable [and sensible] to treat `'foo'mod'bar'` as bad syntax, but what about `'foo'*'bar'`? note that `'foo'.'bar'` is legal [if ugly], as `.` is core punctuation and has its own whitespace-based disambiguation rules)
        
        // no whitespace token as leading/trailing whitespace is associated with token
        // no linebreak token as lexer reads single lines only (Q. any use cases where we'd want a single lexer to scan all lines?)
        
        // how is annotation represented? lexer may want to treat as atomic, with only rule being recursive balancing of nested `«…»` (caveat quoting?)
        
        // Q. underscoreSeparator?
        
        case digits             // 0-9 // Q. should this cover all numerals (e.g. Arabic, Thai, FE, etc scripts have their own numeric glyphs)
        case word // unquoted name (may be command name, operator name, numeric prefix/suffix)
        
        //case whitespace // not sure about this; might want to wrap each significant Token in TokenContext(headWS:String,token:Token,tailWS:String), which allows parsers to inspect adjoining whitespace without having to juggle multiple tokens; e.g. given tokens "123" "." "45", period separators in `123.45` and `123. 45` have different meanings (decimal separator vs expression separator), so numeric parser would concatenate the first into a single `.number` token and emit the second as `.number .periodSeparator .number`.
        
        // tokens that are assembled by single-task interim parsers
        
        case value(Value) // holds any completed value; this'd allow chained parsers to convert token stream from lexer tokens to parsed nodes, with the expectation that the final parser in chain emits a single .value containing the entire AST as a single Value [caveat the whole single-line lexing thing, which'll require some kind of 'stitcher' that tries to balance lines as best it can, inserting best-guess 'fixers' to rebalance where unbalanced]; having a pure token stream for each line is, on the one hand, a bit inefficient (string and annotation literals are presented as sequences of tokens instead of just one atomic .stringLiteral [we could optimize a bit by keeping a per-line list of where the .stringDelimiter tokens appear, allowing us to splice the string's entire content from the original code using beginning and end string indices [caution: if `""` indicates escaped quote, there will be some extra wrangling involved as the splices won't be contiguous]])
        
        // Q. how does lexer determine unquoted words, i.e. are there any special boundary rules (e.g. no mixing of unicode scripts/categories or alnum vs symbols), e.g. how is `foo123` treated - as `.word`, or `.word .digits`? (there may be some value to the decomposed form as it allows more flexibility when matching, say, currencies; e.g. `USD 1.00`); and to what extent should single characters be tokenized, e.g. `$12` could be `.word(String, UnicodeCategory) .digits(String)`
        
        // Q. what about quantities? (this'd include weights and measurements, temperature, currency; what else?)
        
        case illegal
        
        case eol
    }
    
    static let corePunctuation: [Character:Form] = [
        // TO DO: which punctuation chars need associated whitespace rules; e.g. `.` has different meanings depending on whether it has no leading/trailing whitespace, or has trailing whitespace only (note: whitespace before the `.` should probably be considered a typo and removed by pretty printer, although we should consider whether `.` at start of a line may indicate a legal cosmetic linewrap within a long expr; e.g. Swift allows this, although it's of less interest to us as `A.B` is generally only used for reverse domain names, with `B of A` being the standard form for attribute selection)
        "«": .startAnnotation,
        "»": .endAnnotation,
        "[": .startList,
        "]": .endList,
        "{": .startRecord,
        "}": .endRecord,
        "(": .startGroup,
        ")": .endGroup,
        ",": .comma,
        ";": .semicolon,
        ":": .colon,
        ".": .period,
        "?": .query,
        "!": .exclamation,
        "#": .hash,
        "@": .at,
    ]
    
    let form: Form   // enum
    let content: Substring   // the matched character[s]
    let whitespaceBefore: Substring?
    let whitespaceAfter: Substring? // nil = no adjoining whitespace; if non-nil, 1 or more non-linebreaking whitespace characters (space, tab, vtab, nbsp, etc) // TO DO: when disambiguating token sequences, should the type and length of whitespace be considered? e.g. `100 000 000` might be considered a single number in some locales; for now, best just to treat presence/absence of whitespace as a Boolean condition [the one exception is when analyzing previously indented code when generating best-guesses on where to rebalance unbalanced parens, as there we expect to find N tabs but should also be prepared to find 2N/3N/4N/8N spaces if code has been indented by other tools]
}




// TO DO: what is recommended type for representing a set of Character? CharacterSet smells of NSString and UTF16, which blows chunks outside the base plane (OTOH, we don't want to use Set<Character> as that doesn't scale)

// white space
let linebreakCharacters = CharacterSet.newlines
let whitespaceCharacters = CharacterSet.whitespaces
let nonWhitespaceCharacters = whitespaceCharacters.inverted
let digitCharacters = CharacterSet.decimalDigits // 0-9; parsing
let punctuationCharacters = CharacterSet(Token.corePunctuation.keys.map{ $0.unicodeScalars.first! })


// all valid characters recognized by lexer
let _coreCharacters    = linebreakCharacters.union(whitespaceCharacters).union(digitCharacters).union(punctuationCharacters)

let illegalCharacters  = CharacterSet.illegalCharacters

let wordCharacters     = _coreCharacters.inverted.subtracting(illegalCharacters)

// -/+ aren't part of core syntax, but do need to be recognized when processing numeric literals so define matchable symbols here
// TO DO: should pretty printer replace ASCII +/- chars with true Unicode symbols?
let minusCharacters    = CharacterSet(charactersIn: "-\u{2212}\u{FF0D}\u{FE63}")
let plusCharacters     = CharacterSet(charactersIn: "+\u{FF0B}")
let exponentCharacters = CharacterSet(charactersIn: "eE") // scientific-notation, e.g. 1.23e-5


extension CharacterSet {
    
    func contains(_ character: Character) -> Bool {
        guard let c = character.unicodeScalars.first else { return false }
        return self.contains(c) // kludge
    }
}



