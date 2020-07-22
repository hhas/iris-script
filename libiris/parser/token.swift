//
//  token.swift
//  iris-script
//

import Foundation

// TO DO: what should be public vs internal?


// TO DO: support `➞ VALUE` syntax as shortcut for `«result: VALUE»` annotation? this'd standardize the syntax for illustrating script results, allowing it to be ignored by eval when it appears in code (`-->` could be used, c.f. AppleScript, as ASCII alias, though unlike AS it would cover to end of value, not just end of line); Q. what should be syntax for illustrating run-time errors? (for that matter, how should errors display natively? if they can appear as literal values, there’s no need for separate syntax; plus that same literal syntax could be used to instantiate them as well; possible represent as an `error {…}` command, with record containing error info? [evaluating `error` would in the first instance raise an error, which might be a discrete Value or possibly an instance of Command or a subclass of Command])

// TO DO: split punctuation and quotes into sub-enums? what about other 'raw' tokens (letters, symbols, underscores, etc)? if we're going to use partial lexers/parsers to assemble names, numbers, etc from raw tokens, then it'll simplify main parser if it never has to deal with unprocessed .letters/.digits/etc

// TO DO: where to define core punctuation's adjoining whitespace rules? (presumably full parser will digest these pattern-matching rules, along with pattern-matching rules for command grammar, and library-defined operator patterns)

// Q. in jargon, should 'quotes' refer to braces, brackets, and/or parens (used to group record, list, and block content) in addition to single, double, and angle quotes (used to group name, text, and annotation content)

// TO DO: should lexer/parser be concerned with NFC/NFD?

// TO DO: code editor should map Shift-SPACEBAR to underscore for easier entry; Q. to what extent should editor infer underscores when multi-word names are entered with spaces (e.g. via dictation), e.g. auto-“correcting” `foo bar` to `foo_bar` if `foo_bar` is already known to be defined and `foo` and `bar` are not

// note: unlike other grouping delimiters (lists, records, parens, annotations), string quotes do not provide clear indication as to whether start of line is inside or outside quoted text; therefore we tokenize everything and leave the parser to figure out which it is (this is slower than tokenizing the full script, but better able to deal with extra/missing quotes, using both line-by-line balance counts and simple best-guess heuristics comparing relative frequencies of tell-tale characters and words [e.g. known command and operator names, punctuation])

// TO DO: need to decide how/where to put annotations, and how to encode them (annotation content follows its own syntactic rules, which are specific to annotation type, e.g. structural headings and dev/user docs are in Markdown, includes/excludes are comma-delimited lists of superglobal [library] names with optional syntax version suffix), TODOs and comments are unstructured plaintext; Q. what about disabled/macro'd code? (might want to retain tokens for pretty printing)

// TO DO: need one or more cases to encapsulate the various possible syntax errors that may be encountered: unbalanced quoting/grouping punctuation, missing/surplus delimiter punctuation (probably one case that takes an Error enum describing the exact issue; whether syntax errors are also Values, allowing them to appear directly in AST, or whether they should be encapsulated in a shim value (for some categories of syntax errors, a mutable shim would allow the user to correct the error in-place, e.g. adding a missing expr into the wrapper or rebalancing an unbalanced group at the wrapper's proposed best-guess boundary, enabling the captured tokens to be reduced to the final Value, without having to disturb the rest of the AST)

// TO DO: separate case for haltingError? (readers would return this to indicate it's not worth continuing; single-to-multiline readers would need to check the final token returned by each line reader and discard rest of job; alternatively, this check could be implemented as dedicated single-line and multi-line readers that are inserted into reader chains when needed, in which case it's probably simpler for it to detect .error tokens and decide which categories of error should trigger a halt)

// characters that are not allowed anywhere in code should be represented as `.error(BadSyntax.illegalCharacters)`: anything in CharacterSet.illegalCharacters, non-printing control characters [not counting whitespace/linebreaks] (Q. how many non-valid character constructs are there in Unicode standard/ObjC UTF16 NSStrings/Swift Strings; i.e. what do we need to look for, vs what can we trust Swift to reject outright before it ever gets to us?)

// initial tokenization by BaseLexer is minimal, recognizing only core punctuation, contiguous digits, whitespace (as delimiter), and symbols and words (everything else); determining which tokens actually appear inside string literals and annotations [meaning they're not real tokens after all], assembling complete number literals from multiple tokens, distinguishing operator names from command names, etc is left to downstream consumers

// Q. what about non-Latin scripts? e.g. Arabic comma is `،` (don't suppose NFKC remaps it to `,`?); probably best to rely on top-level «language:…» annotation to switch/extend lexer's character sets [we can worry about implementing that later]

// TO DO: when disambiguating token sequences, should the type and length of whitespace be considered? e.g. `100 000 000` might be considered a single number in some locales; for now, best just to treat presence/absence of whitespace as a Boolean condition [the one exception is when analyzing previously indented code when generating best-guesses on where to rebalance unbalanced parens, as there we expect to find N tabs but should also be prepared to find 2N/3N/4N/8N spaces if code has been indented by other tools]

// TO DO: should .digits cover all numerals (e.g. Arabic, Thai, FE, etc scripts have their own numeric glyphs); if so, how do we convert to/from canonical numbers



public typealias Annotation = String

public typealias Precedence = Int16

public enum Associativity {
    case left
    case right
    // TO DO: `case none` (e.g. `1 thru 2 thru 3` should be a syntax error; ditto for `at`, `named`, etc) [note that treating `a OP b OP c` as syntax error isn't absolute protection as parenthesizing one or other operation will allow it to parse, as will using underlying command syntax, at which point it's up to argument unpacking to reject the bad operand as being the wrong type]
}


let commandPrecedence: Precedence = 999 // used when parsing low-punctuation commands to determine if a right-hand infix/postfix operator should be part of command’s argument or if command should be operator's left operand, e.g. `foo 1 + 1` vs `foo bar of baz`; note that PP should automatically parenthesize where clarity is needed, e.g. `(foo 1) + 1` // TO DO: what should argument precedence be? e.g. given `foo 1 + 2`, should it parse as `foo {1 + 2}` or `foo {1} + 2`; currently math operators are ~600; `else` is 90




public struct Token: CustomStringConvertible {
    
    public var description: String { // underscore before/after quoted token text indicates adjoining whitespace
        let form: String
        switch self.form {
        case .operatorName(_):  form = "operatorName"
        case .quotedName(_):    form = "quotedName"
        case .unquotedName(_):  form = "unquotedName"
        default:                form = String(describing: self.form)
        }
        return "<.\(form) \(self.leadingWhitespace == nil ? "" : "_")\(self.content.debugDescription)\(self.trailingWhitespace == nil ? "" : "_")>"
    }
    
    public enum Position {
        case first
        case middle
        case last
        case full // a token can span the entire line, in which case it is both first and last
        
        var isFirst: Bool { return self == .first || self == .full }
        var isAFullMatch: Bool { return self == .last || self == .full }
        
        func span(to endPosition: Position) -> Position {
            switch (self, endPosition) {
            case (.full, .full), (.first, .last): return .full
            case (.first, .middle):               return .first
            case (.middle, .last):                return .last
            default:                              return .middle
            }
        }
    }
    
    public enum Form: Equatable { // core punctuation, plus digits and non-digit text
        
        public enum Separator: CustomDebugStringConvertible { // all act as expr separators and can be used interchangeably within blocks, lists, records; only difference is how they behave at runtime (essentially they act as debugger hooks, optionally inserting extra instructions at parse-time)
            case comma              // ,
            case period             // .
            case query              // ?
            case exclamation        // !
        }
        
        public enum Quoting {
            case annotation(depth: Int)
            case string
        }
                
        // punctuation
        case separator(Separator) // expression separators (,.?!)
        case colon                // label suffix (LABEL:)
        case semicolon            // pipe (;) passes output of LH expr as first argument to RH command
        case hashtag              // symbol literal prefix (#NAME)
        case mentions             // system name prefix (@NAME), e.g. module namespace, `@com.example.foo`
        case underscore           // word separator (_) in names, e.g. `is_in`
        
        // grouping delimiters
        case startAnnotation    // «
        case endAnnotation      // »
        case startList          // [
        case endList            // ]
        case startRecord        // {
        case endRecord          // }
        case startGroup         // (
        case endGroup           // )
        case stringDelimiter    // any of "“”
        case nameDelimiter      // any of '‘’ (BaseLexer will convert these to .quotedName)
                
        // other contiguous characters
        case digits  // 0-9
        case symbols // non-core punctuation/symbol character
        case letters // undifferentiated text (may be command name, operator name, numeric prefix/suffix, etc, or a mixture of these; it's up to downstream readers to interpret as appropriate)
        
        // partial reductions
        
        case beginningOfQuote(kind: Quoting, content: String, leadingWhitespace: Substring?)
        case middleOfQuote(kind: Quoting, content: String)
        case endOfQuote(kind: Quoting, content: String)
        
        case quotedName(Symbol)     // `'NAME'` (quotes may be any of '‘’; NAME is empty or any characters except linebreaks or single/double/annotation quotes; see BaseLexer)
        case unquotedName(Symbol)   // reduction of .letters, .underscore, and/or subsequent .digits (see NameReader)
        case label(Symbol)                      // `NAME COLON` reduction (see NameReader)
        case operatorName(OperatorDefinitions)  // one or more PatternDefinition instances (see OperatorReader)
        case annotation(Annotation) // metadata to be attached to an adjacent/containing value
        case value(Value)           // any reduced Value (including values shifted by parser as it reads commands/blocks)
        case error(NativeError)     // TO DO: delete in favor of always using .value(SyntaxErrorDescription)?
        
        // other delimiters
        case lineBreak
        case endOfCode
    }
    
    public let form: Form   // enum
    let leadingWhitespace: Substring?
    let content: Substring   // the matched character[s]
    let trailingWhitespace: Substring? // nil = no adjoining whitespace; if non-nil, 1 or more non-linebreaking whitespace characters (space, tab, vtab, nbsp, etc)
    let position: Position
        
    init(_ form: Form, _ leadingWhitespace: Substring?, _ content: Substring,
                       _ trailingWhitespace: Substring?, _ position: Position) {
        assert(leadingWhitespace?.count != 0 && trailingWhitespace?.count != 0) // must be nil or non-empty
        self.form = form
        self.leadingWhitespace = leadingWhitespace
        self.content = content
        self.trailingWhitespace = trailingWhitespace
        self.position = position
    }
    
    // used by operator reader to decompose contiguous symbol chars (which tokenizer reads as single token) into individual operators
    
    func extract(_ form: Form, from startIndex: Substring.Index, to endIndex: Substring.Index) -> Token {
        assert (startIndex != endIndex) // TO DO: or return nil?
        let position: Position
        switch self.position {
        case .full:
            if startIndex == self.content.startIndex {
                position = endIndex == self.content.endIndex ? .full : .first
            } else {
                position = endIndex == self.content.endIndex ? .last : .middle
            }
        case .first where startIndex == self.content.startIndex:
            position = .first
        case .last where endIndex == self.content.endIndex:
            position = .last
        default:
            position = .middle
        }
        return Token(form,
                     (startIndex == self.content.startIndex ? self.leadingWhitespace : nil),
                     self.content[startIndex..<endIndex],
                     (endIndex == self.content.endIndex ? self.trailingWhitespace : nil),
                     position)
    }
    
    func extract(_ form: Form) -> Token {
        return Token(form, self.leadingWhitespace, self.content, self.trailingWhitespace, self.position)
    }
    
    // caution: these only indicate presence/absence of adjoining whitespace; they do not indicate if contiguous tokens are self-delimiting (e.g. `foo123` vs `foo]`; `123.45` vs `123. 45`); only parsers can determine that (this is a problem for e.g. numeric parser, which needs to know start of number match is left-delimited)
    
    var hasLeadingWhitespace: Bool { return self.leadingWhitespace != nil || self.position.isFirst }
    var hasTrailingWhitespace: Bool { return self.trailingWhitespace != nil || self.position.isAFullMatch }
    
    var isLeftContiguous: Bool { return !self.hasLeadingWhitespace }
    var isRightContiguous: Bool { return !self.hasTrailingWhitespace }
    
    var isContiguous: Bool { return self.isLeftContiguous && self.isRightContiguous }
    
    
    var isLeftDelimited: Bool { // TO DO: FIX; currently used by UnicodeReader
        // TO DO: this needs to be set by tokenizer based on preceding token's form and/or isRightContiguous, otherwise name/number/etc readers won't detect start of contiguous letter+digit sequences correctly, e.g. `a0u12` should read as identifier, not as `a` + `0u12`
        // [one of the problems here is that `word*` is a delimiter if `*` is an operator, otherwise it isn't, which implies that operators must be lexed before numbers can be extracted]; simplest way to force a solution is to require users to whitespace-separate all operators, thus `1*2` must be written as `1 * 2` or a syntax error occurs; this rule could be limited to cases where operator has adjoining words or digits, in which case `"a"&"b"` is still legal (since core punctuation always delimits), though we may want to keep the whitespace rule consistent; worth noting that in AS, `1mod 2` is legal [if unhelpful] while `1mod2` is a syntax error, so definitely something to be said for consistent clearance; main exception is unary +/-, where right-hand clearance should be non-required (or possibly even disallowed), thus `-foo`, not `- foo` (since the latter becomes ambiguous if the preceding token is a word)

        return true
    }

    
    var requiresLeftOperand: Bool { if let oc = self.definitions { fatalError("Can't get Token.requiresLeftOperand for \(oc)") } else { return false } /*return self.definitions?.requiresLeftOperand ?? false*/ }
    
    var definitions: OperatorDefinitions? {
        if case .operatorName(let definitions) = self.form { return definitions } else { return nil }
    }
}




extension Token.Form.Separator {
    
    public var debugDescription: String {
        switch self {
        case .comma:        return "\",\""
        case .period:       return "\".\""
        case .query:        return "\"?\""
        case .exclamation:  return "\"!\""
        }
    }
}

public extension Token.Form {
    
    static let predefinedSymbols: [Character:Token.Form] = [
        // TO DO: which punctuation chars need associated whitespace rules; e.g. `.` has different meanings depending on whether it has no leading/trailing whitespace, or has trailing whitespace only (note: whitespace before the `.` should probably be considered a typo and removed by pretty printer, although we should consider whether `.` at start of a line may indicate a legal cosmetic linewrap within a long expr; e.g. Swift allows this, although it's of less interest to us as `A.B` is generally only used for reverse domain names, with `B of A` being the standard form for attribute selection)
        // punctuation (separators/terminators)
        ",": .separator(.comma),
        ".": .separator(.period),
        "?": .separator(.query),
        "!": .separator(.exclamation),
        ";": .semicolon,
        ":": .colon,
        "_": .underscore,
        // name modifiers
        "#": .hashtag,
        "@": .mentions,
        // quotes
        "«": .startAnnotation,
        "»": .endAnnotation,
        "[": .startList,
        "]": .endList,
        "{": .startRecord,
        "}": .endRecord,
        "(": .startGroup,
        ")": .endGroup,
        // unlike annotation/list/record/group delimiters, single/double quotes do not reliably indicate start/end
       "\"": .stringDelimiter,
        "“": .stringDelimiter,
        "”": .stringDelimiter,
        "'": .nameDelimiter,
        "‘": .nameDelimiter,
        "’": .nameDelimiter,
        // Q. what about Unicode apostrophes, given their visual similarity? (main thing is to ensure code that has been chewed by e.g. TextEdit's standard autocorrect still parses correctly; more testing needed)
    ]
    
    // does this token terminate the expression to its right/left side?
    //
    // caution: these methods only consider punctuation-described boundaries, sufficient for first-pass division of source code into [hopefully] reducible expressions; determining if a given .[un]quotedName, .operatorName, and/or .error form describes the beginning/end of an expr requires further examination of a token and its neighbors
            
    static func ==(lhs: Token.Form, rhs: Token.Form) -> Bool { // caution: this only indicates if two tokens have the same form; it does not compare content
        switch (lhs, rhs) {
        case (.startAnnotation, .startAnnotation): return true
        case (.endAnnotation, .endAnnotation): return true
        case (.startList, .startList): return true
        case (.endList, .endList): return true
        case (.startRecord, .startRecord): return true
        case (.endRecord, .endRecord): return true
        case (.startGroup, .startGroup): return true
        case (.endGroup, .endGroup): return true
        case (.separator(let a), .separator(let b)): return a == b
        case (.semicolon, .semicolon): return true
        case (.colon, .colon): return true
        case (.hashtag, .hashtag): return true
        case (.mentions, .mentions): return true
        case (.underscore, .underscore): return true
        case (.stringDelimiter, .stringDelimiter): return true
        case (.nameDelimiter, .nameDelimiter): return true
        case (.digits, .digits): return true
        case (.symbols, .symbols): return true
        case (.letters, .letters): return true
        case (.label(let a), .label(let b)): return a == b
        case (.unquotedName(let a), .unquotedName(let b)): return a == b
        case (.quotedName(let a), .quotedName(let b)): return a == b
        case (.operatorName(let a), .operatorName(let b)): return a.name == b.name
        case (.value(_), .value(_)): return true
        case (.error(_), .error(_)): return true
        case (.lineBreak, .lineBreak): return true
        case (.endOfCode, .endOfCode): return true
        default: return false // caution: this will mask missing cases, but Swift compiler insists on it; make sure these cases are updated whenever Form enum is modified
        }
    }
    
    var isLeftExpressionDelimiter: Bool {
        switch self {
            // TO DO: what about start of script? (need a new form for that)
        case.colon, .separator(_), .startList, .startRecord, .startGroup, .lineBreak: return true
        default: return false
        }
    }
    
    var isRightExpressionDelimiter: Bool { // currently unused
        switch self {
        case .colon, .separator(_), .endList, .endRecord, .endGroup, .lineBreak, .endOfCode: return true
        default: return false
        }
    }
    
    //
    
    func asCommandName() -> Symbol? { // caution: this assumes line readers have already reduced contiguous .letters, .digits, .underscore, etc. to an .[un]quotedName(…)
        switch self {
        case .unquotedName(let n), .quotedName(let n): return n
        default: return nil
        }
    }
    
    var isCommandName: Bool {
        switch self {
        case .unquotedName(_), .quotedName(_): return true
        default: return false
        }
    }
    
    func asArgumentLabel() -> Symbol? { // TO DO: currently unused
        switch self {
        case .label(let n): return n
        default: return nil
        }
    }
    var isArgumentLabel: Bool {
        switch self {
        case .label(_): return true
        default: return false
        }
    }
}


// delimiter token constants

public let lineBreakToken = Token(.lineBreak, nil, "", nil, .last)

public let endOfCodeToken = Token(.endOfCode, nil, "", nil, .last) // caution: endOfCode tokens should be treated as opaque placeholders only; they do not capture adjoining whitespace nor indicate their position in original line/script source

