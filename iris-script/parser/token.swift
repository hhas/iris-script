//
//  token.swift
//  iris-script
//

import Foundation


// TO DO: should lexer/parser be concerned with NFC/NFD?


struct Token: CustomStringConvertible {
    
    // initial tokenization by LineReader is minimal, recognizing only core punctuation, contiguous digits, whitespace (as delimiter), and symbols and words (everything else); determining which tokens actually appear inside string literals and annotations [meaning they're not real tokens after all], assembling complete number literals from multiple tokens, distinguishing operator names from command names, etc is left to downstream consumers
    
    var description: String { // underscore before/after quoted token text indicates adjoining whitespace
        return "<.\(self.form) \(self.whitespaceBefore == nil ? "" : "_")\(self.content.debugDescription)\(self.whitespaceAfter == nil ? "" : "_")>"
    }
    
    // Q. what about non-Latin scripts? e.g. Arabic comma is `،` (don't suppose NFKC remaps it to `,`?); probably best to rely on top-level «language:…» annotation to switch/extend lexer's character sets [we can worry about implementing that later]
    
    enum Position {
        case first
        case middle
        case last
        case full // a token can span the entire line, in which case it is both first and last
        
        var isFirst: Bool { return self == .first || self == .full }
        var isLast: Bool { return self == .last || self == .full }
    }
    
    enum Form: Equatable { // core punctuation, plus digits and non-digit text
        // expression separators
        case comma              // ,
        case semicolon          // ;
        case colon              // :
        case period             // .
        case query              // ?
        case exclamation        // !
        case hash               // #
        case at                 // @
        
        // TO DO: is there any benefit to underscoreSeparator being a distinct case? (right now, it's part of undifferentiated words); e.g. does splitting phrases into discrete words (`'document' '_' 'file'` instead of `'document_file'`) provide any benefits to editor when fuzzy matching user's typed input to available domain knowledge; e.g. a user may type `document file` within a `tell @com.apple.Finder to: do…done` block, either accidentally or intentionally [if confident the editor's autocorrect can interpret their intent based on current context], which is certainly beneficial from a touch-typing perspective as Space Bar is much quicker and easier to hit than combined Shift+Minus keys
        
        // grouping delimiters
        case startAnnotation    // «
        case endAnnotation      // »
        case startList          // [
        case endList            // ]
        case startRecord        // {
        case endRecord          // }
        case startGroup         // (
        case endGroup           // )
        
        case stringDelimiter    // any of "“” // note: unlike other grouping delimiters (lists, records, parens, annotations), string quotes do not provide clear indication as to whether start of line is inside or outside quoted text; therefore we tokenize everything and leave the parser to figure out which it is (this is slower than tokenizing the full script, but better able to deal with extra/missing quotes, using both line-by-line balance counts and simple best-guess heuristics comparing relative frequencies of tell-tale characters and words [e.g. known command and operator names, punctuation])
        
        case nameDelimiter      // any of '‘’ // LineReader will convert these to quotedName
        
        // no whitespace token as leading/trailing whitespace is associated with token
        // no linebreak token as lexer reads single lines only (Q. any use cases where we'd want a single lexer to scan all lines?)
        
        // how is annotation represented? lexer may want to treat as atomic, with only rule being recursive balancing of nested `«…»` (caveat quoting?)
        
        // other contiguous characters
        case digits             // 0-9 // Q. should this cover all numerals (e.g. Arabic, Thai, FE, etc scripts have their own numeric glyphs)
        
        case symbols // non-core punctuation/symbol character
        
        case word // undifferentiated text (may be command name, operator name, numeric prefix/suffix, etc, or a mixture of these; it's up to downstream readers to interpret as appropriate)
        
        case quotedName(String) // 'WORD' (quotes may be any of '‘’; WORD may be any character other than whitespace[?] or core punctuation) // single-quotes always appear on single line, without leading/trailing whitespace around the quoted text (the outer edges of the quotes should always be separator/delimiter punctuation or whitespace, although we do need to confirm this, e.g. it's probably reasonable [and sensible] to treat `'foo'mod'bar'` as bad syntax, but what about `'foo'*'bar'`? note that `'foo'.'bar'` is legal [if ugly], as `.` is core punctuation and has its own whitespace-based disambiguation rules)
        
        // tokens created by single-task interim parsers
        case lexeme(Lexeme) // Swift enums are not runtime-extensible so we provide an 'extensibility' slot; used by OperatorReader (and, potentially, other partial readers) when decomposing words
        case value(Value) // holds any completed value; this'd allow chained parsers to convert token stream from lexer tokens to parsed nodes, with the expectation that the final parser in chain emits a single .value containing the entire AST as a single Value [caveat the whole single-line lexing thing, which'll require some kind of 'stitcher' that tries to balance lines as best it can, inserting best-guess 'fixers' to rebalance where unbalanced]; having a pure token stream for each line is, on the one hand, a bit inefficient (string and annotation literals are presented as sequences of tokens instead of just one atomic .stringLiteral [we could optimize a bit by keeping a per-line list of where the .stringDelimiter tokens appear, allowing us to splice the string's entire content from the original code using beginning and end string indices [caution: if `""` indicates escaped quote, there will be some extra wrangling involved as the splices won't be contiguous]])
        
        case error(NativeError) // TO DO: need one or more cases to encapsulate the various possible syntax errors that may be encountered: unbalanced quoting/grouping punctuation, missing/surplus delimiter punctuation (probably one case that takes an Error enum describing the exact issue; whether syntax errors are also Values, allowing them to appear directly in AST, or whether they should be encapsulated in a shim value (for some categories of syntax errors, a mutable shim would allow the user to correct the error in-place, e.g. adding a missing expr into the wrapper or rebalancing an unbalanced group at the wrapper's proposed best-guess boundary, enabling the captured tokens to be reduced to the final Value, without having to disturb the rest of the AST)
        
        // TO DO: separate case for haltingError? (readers would return this to indicate it's not worth continuing; single-to-multiline readers would need to check the final token returned by each line reader and discard rest of job; alternatively, this check could be implemented as dedicated single-line and multi-line readers that are inserted into reader chains when needed, in which case it's probably simpler for it to detect .error tokens and decide which categories of error should trigger a halt)
        
        case invalid // anything in CharacterSet.illegalCharacters, non-printing control characters [not counting whitespace/linebreaks] (Q. how many non-valid character constructs are there in Unicode standard/ObjC UTF16 NSStrings/Swift Strings; i.e. what do we need to look for, vs what can we trust Swift to reject outright before it ever gets to us?)

        case eol
        
        // TO DO: associated values on enums significantly increase complexity (e.g. no automatic Equatable); would it be better to move the details to a separate Content enum? // Q. should we also consolidate expr separators and grouping delimiters into two Form cases (.separator + .grouping), with SeparatorForms and GroupingForms enums under Content?
        
        static func ==(lhs: Form, rhs: Form) -> Bool { // caution: this only indicates if two tokens have the same form; it does not compare content
            switch (lhs, rhs) {
            case (.comma, .comma): return true
            case (.semicolon, .semicolon): return true
            case (.colon, .colon): return true
            case (.period, .period): return true
            case (.query, .query): return true
            case (.exclamation, .exclamation): return true
            case (.hash, .hash): return true
            case (.at, .at): return true
            case (.startAnnotation, .startAnnotation): return true
            case (.endAnnotation, .endAnnotation): return true
            case (.startList, .startList): return true
            case (.endList, .endList): return true
            case (.startRecord, .startRecord): return true
            case (.endRecord, .endRecord): return true
            case (.startGroup, .startGroup): return true
            case (.endGroup, .endGroup): return true
            case (.stringDelimiter, .stringDelimiter): return true
            case (.digits, .digits): return true
            case (.symbols, .symbols): return true
            case (.word, .word): return true
            case (.quotedName(_), .quotedName(_)): return true
            case (.lexeme(_), .lexeme(_)): return true
            case (.value(_), .value(_)): return true
            case (.error(_), .error(_)): return true
            case (.invalid, .invalid): return true
            case (.eol, .eol): return true
            default: return false // caution: this will mask missing cases, but Swift compiler insists on it; make sure these cases are updated whenever Form enum is modified
            }
        }
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
        // unlike annotation/list/record/group delimiters, single/double quotes do not reliably indicate start/end
       "\"": .stringDelimiter,
        "“": .stringDelimiter,
        "”": .stringDelimiter,
        "'": .nameDelimiter,
        "‘": .nameDelimiter,
        "’": .nameDelimiter,
    ]
    
    let form: Form   // enum
    let whitespaceBefore: Substring?
    let content: Substring   // the matched character[s]
    let whitespaceAfter: Substring? // nil = no adjoining whitespace; if non-nil, 1 or more non-linebreaking whitespace characters (space, tab, vtab, nbsp, etc) // TO DO: when disambiguating token sequences, should the type and length of whitespace be considered? e.g. `100 000 000` might be considered a single number in some locales; for now, best just to treat presence/absence of whitespace as a Boolean condition [the one exception is when analyzing previously indented code when generating best-guesses on where to rebalance unbalanced parens, as there we expect to find N tabs but should also be prepared to find 2N/3N/4N/8N spaces if code has been indented by other tools]
    let position: Position
    
    // TO DO: could do with isLeftDelimited:Bool, which needs to know if preceding token (if any) is punctuation (checking for right-delimited is a lookahead); Q. what about lexeme/value/error? [one of the problems here is that `word*` is a delimiter if `*` is an operator, otherwise it isn't, which implies that operators must be lexed before numbers can be extracted]; simplest way to force a solution is to require users to whitespace-separate all operators, thus `1*2` must be written as `1 * 2` or a syntax error occurs; this rule could be limited to cases where operator has adjoining words or digits, in which case `"a"&"b"` is still legal (since core punctuation always delimits), though we may want to keep the whitespace rule consistent; worth noting that in AS, `1mod 2` is legal [if unhelpful] while `1mod2` is a syntax error, so definitely something to be said for consistent clearance; main exception is unary +/-, where right-hand clearance should be non-required (or possibly even disallowed), thus `-foo`, not `- foo` (since the latter becomes ambiguous if the preceding token is a word)
    
    init(_ form: Form, _ whitespaceBefore: Substring?, _ content: Substring, _ whitespaceAfter: Substring?, _ position: Position) {
        assert(whitespaceBefore?.count != 0 && whitespaceAfter?.count != 0) // must be nil or non-empty
        self.form = form
        self.whitespaceBefore = whitespaceBefore
        self.content = content
        self.whitespaceAfter = whitespaceAfter
        self.position = position
    }
    
    var hasLeadingWhitespace: Bool { return self.whitespaceBefore != nil || self.position.isFirst }
    var hasTrailingWhitespace: Bool { return self.whitespaceAfter != nil || self.position.isLast }
    
    var isLeftContiguous: Bool { return !self.hasLeadingWhitespace }
    var isRightContiguous: Bool { return !self.hasTrailingWhitespace }
    
    var isContiguous: Bool { return self.isLeftContiguous && self.isRightContiguous }

    var isPunctuation: Bool {
        switch self.form {
        case .startAnnotation, .endAnnotation, .startList, .endList, .startRecord, .endRecord, .startGroup, .endGroup,
             .comma, .semicolon, .colon, .period, .query, .exclamation, .hash, .at: return true // caution: copied from corePunctuation; update this whenever corePunctuation is modified
        default: return false
        }
    }
    var isDigits: Bool { if case .digits = self.form { return true } else { return false } }
    var isWord: Bool { if case .word = self.form { return true } else { return false } }    
    var isEnd: Bool { if case .eol = self.form { return true } else { return false } }
}

let nullToken = Token(.eol, nil, "", nil, .last) // caution: eol tokens should be treated as opaque placeholders only; they do not capture adjoining whitespace nor indicate their position in original line/script source

