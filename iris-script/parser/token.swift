//
//  token.swift
//  iris-script
//

import Foundation



// TO DO: split punctuation and quotes into sub-enums? what about other 'raw' tokens (letters, symbols, underscores, etc)? if we're going to use partial lexers/parsers to assemble names, numbers, etc from raw tokens, then it'll simplify main parser if it never has to deal with unprocessed .letters/.digits/etc

// TO DO: where to define core punctuation's adjoining whitespace rules? (presumably full parser will digest these pattern-matching rules, along with pattern-matching rules for command grammar, and library-defined operator patterns)

// Q. in jargon, should 'quotes' refer to braces, brackets, and/or parens (used to group record, list, and block content) in addition to single, double, and angle quotes (used to group name, text, and annotation content)

// TO DO: should lexer/parser be concerned with NFC/NFD?

// TO DO: code editor should map Shift-SPACEBAR to underscore for easier entry; Q. to what extent should editor infer underscores when multi-word names are entered with spaces (e.g. via dictation), e.g. auto-“correcting” `foo bar` to `foo_bar` if `foo_bar` is already known to be defined and `foo` and `bar` are not


typealias Precedence = Int16


let argumentPrecedence: Precedence = 300 // used when parsing low-punctuation commands only // important: this must have higher precedence than punctuation // TO DO: what should argument precedence be? e.g. given `foo 1 + 2`, should it parse as `foo {1 + 2}` or `foo {1} + 2`; currently math operators are ~600; `else` is 90

let operatorPrecedences: Range<Int16> = 100..<1000 // TO DO: decide valid range; currently unused



struct Token: CustomStringConvertible {
    
    // initial tokenization by CoreLexer is minimal, recognizing only core punctuation, contiguous digits, whitespace (as delimiter), and symbols and words (everything else); determining which tokens actually appear inside string literals and annotations [meaning they're not real tokens after all], assembling complete number literals from multiple tokens, distinguishing operator names from command names, etc is left to downstream consumers
    
    var description: String { // underscore before/after quoted token text indicates adjoining whitespace
        let form: String
        switch self.form {
        case .operatorName(_):  form = "operatorName"
        case .quotedName(_):    form = "quotedName"
        case .unquotedName(_):  form = "unquotedName"
        default:                form = String(describing: self.form)
        }
        return "<.\(form) \(self.whitespaceBefore == nil ? "" : "_")\(self.content.debugDescription)\(self.whitespaceAfter == nil ? "" : "_")>"
    }
    
    // Q. what about non-Latin scripts? e.g. Arabic comma is `،` (don't suppose NFKC remaps it to `,`?); probably best to rely on top-level «language:…» annotation to switch/extend lexer's character sets [we can worry about implementing that later]
    
    enum Position {
        case first
        case middle
        case last
        case full // a token can span the entire line, in which case it is both first and last
        
        var isFirst: Bool { return self == .first || self == .full }
        var isLast: Bool { return self == .last || self == .full }
        
        func span(to endPosition: Position) -> Position {
            switch (self, endPosition) {
            case (.full, .full), (.first, .last): return .full
            case (.first, .middle):               return .first
            case (.middle, .last):                return .last
            default:                              return .middle
            }
        }
    }
    
    enum Form: Equatable { // core punctuation, plus digits and non-digit text
        
        enum Separator { // all act as expr separators and can be used interchangeably within blocks, lists, records; only difference is how they behave at runtime (essentially they act as debugger hooks, optionally inserting extra instructions at parse-time)
            case comma              // ,
            case period             // .
            case query              // ?
            case exclamation        // !
        }
        
        // TO DO: restructure as .punctuation(), .unaryQuote(), .beginQuote(), .endQuote(), .letters(), .symbols(), .digits(), .lexeme() primitives, where primitives are progressively converted to .lexemes (.string(), .numeric(), .identifier(), etc)?
        
        // expression separators // TO DO: combine into single .separator(Separator) case
        case separator(Separator)
        //case comma              // ,
        //case period             // .
        //case query              // ?
        //case exclamation        // !
        
        // key-value pairing // colon is defined as a builtin rather than a table-defined operator since key-value list and record syntax+types are builtins; Q. should `name:value` bindings in block contexts map to `set` command or to dedicated Bind Value? (i.e. if `set` is stdlib-defined, we probably still want a way to store values in env even when stdlib isn't loaded)
        case colon              // :

        // pipe (passes output of LH expr as first argument to RH command) // TO DO: defining this as builtin could allow for RH operand to be LF-wrapped onto next line - not sure if this is a good or bad idea (forcing both operands to appear on same line prevents editing accidents); other reason for making it a builtin is that the parser can apply the `A;B`->`B{A}` transform directly (annotating B Command for PP), whereas an operator would apply at eval time
        case semicolon          // ;
        
        case hashtag            // #  // #NAME = symbol literal
        case mentions           // @  // @NAME = special names, i.e. system namespace (e.g. module namespace, e.g. `@com.example.foo`; any config-defined constants, e.g. @USER)
        case underscore         // _
        
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
        
        case nameDelimiter      // any of '‘’ // CoreLexer will convert these to quotedName
        
        // no whitespace token as leading/trailing whitespace is associated with token
        // no linebreak token as lexer reads single lines only (Q. any use cases where we'd want a single lexer to scan all lines?)
        
        // how is annotation represented? lexer may want to treat as atomic, with only rule being recursive balancing of nested `«…»` (caveat quoting?)
        
        // other contiguous characters
        case digits             // 0-9 // Q. should this cover all numerals (e.g. Arabic, Thai, FE, etc scripts have their own numeric glyphs)
        
        case symbols // non-core punctuation/symbol character
        
        case letters // undifferentiated text (may be command name, operator name, numeric prefix/suffix, etc, or a mixture of these; it's up to downstream readers to interpret as appropriate) // TO DO: may want to rename 'letters', to avoid singular vs plural inconsistency with other names
        
        case unquotedName(String)
        case quotedName(String) // 'WORD' (quotes may be any of '‘’; WORD may be any character other than linebreaks or single/double/annotation quotes) // single-quotes always appear on single line, without leading/trailing whitespace around the quoted text (the outer edges of the quotes should always be separator/delimiter punctuation or whitespace, although we do need to confirm this, e.g. it's probably reasonable [and sensible] to treat `'foo'mod'bar'` as bad syntax, but what about `'foo'*'bar'`? note that `'foo'.'bar'` is legal [if ugly], as `.` is core punctuation and has its own whitespace-based disambiguation rules)
        
        // tokens created by single-task interim parsers
        case operatorName(OperatorGroup) // Swift enums are not runtime-extensible so we provide an 'extensibility' slot; used by OperatorReader (and, potentially, other partial readers) when decomposing words
        case value(Value) // holds any completed value; this'd allow chained parsers to convert token stream from lexer tokens to parsed nodes, with the expectation that the final parser in chain emits a single .value containing the entire AST as a single Value [caveat the whole single-line lexing thing, which'll require some kind of 'stitcher' that tries to balance lines as best it can, inserting best-guess 'fixers' to rebalance where unbalanced]; having a pure token stream for each line is, on the one hand, a bit inefficient (string and annotation literals are presented as sequences of tokens instead of just one atomic .stringLiteral [we could optimize a bit by keeping a per-line list of where the .stringDelimiter tokens appear, allowing us to splice the string's entire content from the original code using beginning and end string indices [caution: if `""` indicates escaped quote, there will be some extra wrangling involved as the splices won't be contiguous]])
        
        case annotation(String) // TO DO: need to decide how/where to put annotations, and how to encode them (annotation content follows its own syntactic rules, which are specific to annotation type, e.g. structural headings and dev/user docs are in Markdown, includes/excludes are comma-delimited lists of superglobal [library] names with optional syntax version suffix), TODOs and comments are unstructured plaintext; Q. what about disabled/macro'd code? (might want to retain tokens for pretty printing)
        
        case error(NativeError) // TO DO: need one or more cases to encapsulate the various possible syntax errors that may be encountered: unbalanced quoting/grouping punctuation, missing/surplus delimiter punctuation (probably one case that takes an Error enum describing the exact issue; whether syntax errors are also Values, allowing them to appear directly in AST, or whether they should be encapsulated in a shim value (for some categories of syntax errors, a mutable shim would allow the user to correct the error in-place, e.g. adding a missing expr into the wrapper or rebalancing an unbalanced group at the wrapper's proposed best-guess boundary, enabling the captured tokens to be reduced to the final Value, without having to disturb the rest of the AST)
        
        // TO DO: separate case for haltingError? (readers would return this to indicate it's not worth continuing; single-to-multiline readers would need to check the final token returned by each line reader and discard rest of job; alternatively, this check could be implemented as dedicated single-line and multi-line readers that are inserted into reader chains when needed, in which case it's probably simpler for it to detect .error tokens and decide which categories of error should trigger a halt)
        
        case invalid // characters that are not allowed anywhere in code: anything in CharacterSet.illegalCharacters, non-printing control characters [not counting whitespace/linebreaks] (Q. how many non-valid character constructs are there in Unicode standard/ObjC UTF16 NSStrings/Swift Strings; i.e. what do we need to look for, vs what can we trust Swift to reject outright before it ever gets to us?)

        case lineBreak
        case endOfScript
        
        // TO DO: associated values on enums significantly increase complexity (e.g. no automatic Equatable); would it be better to move the details to a separate Content enum? // Q. should we also consolidate expr separators and grouping delimiters into two Form cases (.separator + .grouping), with SeparatorForms and GroupingForms enums under Content?
        
        static func ==(lhs: Form, rhs: Form) -> Bool { // caution: this only indicates if two tokens have the same form; it does not compare content
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
            case (.unquotedName(_), .unquotedName(_)): return true
            case (.quotedName(_), .quotedName(_)): return true
            case (.operatorName(let a), .operatorName(let b)): return a.name == b.name
            case (.value(_), .value(_)): return true
            case (.error(_), .error(_)): return true
            case (.invalid, .invalid): return true
            case (.lineBreak, .lineBreak): return true
            case (.endOfScript, .endOfScript): return true
            default: return false // caution: this will mask missing cases, but Swift compiler insists on it; make sure these cases are updated whenever Form enum is modified
            }
        }

        // TO DO: how to describe precedences by name/category? (using hardcoded ints will become problematic) e.g. arithmetic operators should be one category, with relative precedences between operators within that category (`+` = `-` < `*` = `/`; caveat we need to distinguish operands as well)
        
        // 0 is default precedence (literal values)
        var precedence: Precedence { // TO DO: this needs moved/deleted as operator precedence cannot be determined from .operatorName(_) tokens, only from matched patterns
            switch self {
                
            // expression sequence separators // TO DO: what about adjoining whitespace as precedence modifier? e.g. `com.example.foo` has different precedence to `com. example. foo`
            
            case .separator(_): return -10 // TO DO: what precedence?
            case .lineBreak: return 90
            case .semicolon: return 96 // important: precedence needs to be higher than expr sep punctuation (comma, period, etc), but lower than lp command’s argument label [Q. lp command argument shouldn't have precedence]
            case .colon: return 94 // caution: this must be higher than .separator/.lineBreak to ensure dict/record items parse correctly (TO DO: is this still an issue with SR parser?)
                                
                
            case .hashtag: return 2000      // name modifier; this must always bind to following name
            case .mentions: return 2000     // name modifier; Q. what if the name is multipart (reverse domain name, aka UTI), e.g. `@com.example.my_lib`? one option is to construct it as standard specifier, with pp annotations so that it prints as `A.B` instead of `B of A`; in this case, binding `@` to first part only means that `@com` is the superglobal's name; OTOH, binding `@` to entire name means that `com.example.my_lib` is the superglobal's name, thus `@` is effectively a prefix operator that switches the context in which the chunk expr is evaluated from current to superglobal; we could even implement this as a [non-maskable] command: `'@'{com.example.my_lib}`. It all comes down to how we want to evaluate chunk exprs in general and UTIs in particular; e.g. if we use a partial LineReader to extract UTIs to value representation, binding the `@` to the entire UTI later on will occur naturally. Also note that .period form's precedence is that of expr sep punctuation; if we want full parser to treat .period differently when left-and-right-contiguous (property selector) vs left- and/or right-delimited (expr sep) then we'll need to move `Form.precedence` to `Token`. Thus question becomes: do we want contiguous .period to act as a general Swift/JS/etc-style 'dot' operator (which can be used even when stdlib's `of` operator/command isn't loaded)? (if so, it needs to play nice with parameterized commands, e.g. `foo.item{at:1}.item{named:"bar"}`? or does that run too far counter to "speakable-friendly" syntax? after all, UTI pronounciation is simple enough - e.g. "com dot example dot foo" - but using "dot" when speaking commands is likely to get awkward, especially as it won't play well with lp command syntax). Think we should look at UTI literal syntax in same way as we should look at, say, date and time literals, e.g. `2019-07-12` should be directly extractable using a 'DateTime' LineReader.

            case .operatorName(let operatorClass): // Q. what range to use for operators? 100-999?
                
                // TO DO: where to put precedence info?
                
                fatalError("precedence not available for operator class \(operatorClass)")
                
                // e.g. v1 o1 v2 o2 … -- once v2 is parsed, peek ahead to o2 to determine if v2 is operand to o2 or o1
                //if let a = operatorClass.infix, let b = operatorClass.postfix, a.precedence != b.precedence {
               //     print("warning: mismatched precedences for \(a) vs \(b)")
                    // note that prefix and infix can have different precedences (e.g. `+`/`-`); however, `Form.precedence` is only being used when determining if current operator binds tighter than preceding operator (i.e. the operator cannot be .prefix or .atom) // TO DO: what about .custom? (e.g. if non-numeric comparison operators take an optional `as` clause)
               // }
                //return operatorClass.infix?.precedence ?? operatorClass.postfix?.precedence ?? 0
//            case .error(_): return 0
//            case .invalid: return 0
            case .endOfScript: return -10000
            default: return 0
            }
        }
    }
    
    static let predefinedSymbols: [Character:Form] = [
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
                     (startIndex == self.content.startIndex ? self.whitespaceBefore : nil),
                     self.content[startIndex..<endIndex],
                     (endIndex == self.content.endIndex ? self.whitespaceAfter : nil),
                     position)
    }
    
    func extract(_ form: Form) -> Token {
        return Token(form, self.whitespaceBefore, self.content, self.whitespaceAfter, self.position)
    }
    
    // caution: these only indicate presence/absence of adjoining whitespace; they do not indicate if contiguous tokens are self-delimiting (e.g. `foo123` vs `foo]`; `123.45` vs `123. 45`); only parsers can determine that (this is a problem for e.g. numeric parser, which needs to know start of number match is left-delimited)
    
    var hasLeadingWhitespace: Bool { return self.whitespaceBefore != nil || self.position.isFirst }
    var hasTrailingWhitespace: Bool { return self.whitespaceAfter != nil || self.position.isLast }
    
    var isLeftContiguous: Bool { return !self.hasLeadingWhitespace }
    var isRightContiguous: Bool { return !self.hasTrailingWhitespace }
    
    var isContiguous: Bool { return self.isLeftContiguous && self.isRightContiguous }
    
    var isEndOfSequence: Bool { // TO DO: still needed
        switch self.form {
        case .endList, .endRecord, .endGroup: return true
        case .operatorName(let operatorClass): fatalError("Can't get Token.isEndOfSequence for \(operatorClass)") //return operatorClass.name == .word("done") // kludge
        case .endOfScript: return true
        default: return false
        }
    }
    
    var isName: Bool {
        switch self.form {
        case .letters, .symbols, .underscore, .quotedName(_), .unquotedName(_): return true
        default: return false
        }
    }
    
    var isLeftDelimited: Bool {
        // TO DO: this needs to be set by tokenizer based on preceding token's form and/or isRightContiguous, otherwise name/number/etc readers won't detect start of contiguous letter+digit sequences correctly, e.g. `a0u12` should read as identifier, not as `a` + `0u12`
        return true
    }
    
    // i.e. if operator takes left operand (infix/postfix), it must terminate the preceding expression in order to consume it; OTOH, if operator is prefix/atom, it's up to preceding tokens/parsefunc to know what to do with it (e.g. in `write true`, `true` is an atom that will be consumed as `write` command's argument) // caution: this is only a partial fix, as until the operator expression is fully parsed, we cannot be sure of this when dealing with operators that have >1 definition, while operators that use custom parsefuncs will always be treated as having no left operand even when they do; TO DO: fix this properly once table-driven parser is implemented (unlike parsefuncs, whose matching behaviors are opaque, matching tables can be independently inspected to determine the exact number and positions of their operands)
    var isExpressionTerminator: Bool {
        switch self.form {
        case .semicolon, .colon, .separator(_),
             .endList, .endRecord, .endGroup, .lineBreak, .endOfScript:
            return true
        default:
            return false
        }
    }
    
    var requiresLeftOperand: Bool { if let oc = self.operatorClass { fatalError("Can't get Token.requiresLeftOperand for \(oc)") } else { return false } /*return self.operatorClass?.requiresLeftOperand ?? false*/ }
    
    var operatorClass: OperatorGroup? {
        if case .operatorName(let operatorClass) = self.form { return operatorClass } else { return nil }
    }
    
    // TO DO: these are currently unused
    var isOperatorName: Bool { if case .operatorName(_) = self.form { return true } else { return false } }
    
    var isCommandName: Bool {
        switch self.form {
        case .letters, .symbols, .underscore, .quotedName(_), .unquotedName(_): return true
        default:                                                                return false
        }
    }
    
}

let nullToken = Token(.lineBreak, nil, "", nil, .last) // caution: eol tokens should be treated as opaque placeholders only; they do not capture adjoining whitespace nor indicate their position in original line/script source

let eofToken = Token(.endOfScript, nil, "", nil, .last) // caution: eol tokens should be treated as opaque placeholders only; they do not capture adjoining whitespace nor indicate their position in original line/script source

