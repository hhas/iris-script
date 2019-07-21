//
//  line reader.swift
//  iris-script
//

//  lexing is performed per-line and provides a degree of customization via adapters

//  - the basic LineReader lexer converts a single line of code into the initial token stream; it is solely concerned with distinguishing core punctuation (which has fixed meaning), digits, symbols, words, and whitespace; assigning additional meaning (e.g. identifying numbers and operators) is left to downstream adapters

//  - the NumericReader adapter is a single-task parser that matches contiguous token sequences representing complete numbers and reduces them to atomic .value tokens; e.g. the .symbol `-` followed by .digits `123` followed by .period `.` followed by .digits `45` is reduced to .value `Number(-123.45)`; all other tokens are passed thru unchanged

//  - the OperatorReader adapter extends the basic LineReader lexer, adding the ability to identify library-defined operator names within undifferentiated symbols and word tokens and split them into their own tokens


// be aware that not all lexed tokens will eventually reduce to code: tokens subsequently found to lie within string/annotation literals are ignored and discarded when the code is parsed in full



// TO DO: how to handle +/- symbols? the numeric reader expects them to be categorized as .symbol, but the operator reader wants to recategorize them as lexemes (prefix/infix math operators)


// one advantage of componentizing lexer and parser is that we can create specialized parsers, e.g. a JSON-like pure-data format might use LineReader + NumericReader but omit OperatorReader, feeding into a much simplified document parser that treats all remaining words and symbols as syntax errors


// Q. how does this compare to mutable lexer than can backtrack over previously-built tokens? (i.e. while we don't pay any extra by creating new immutable lexer structs with incremented cursor indexes vs mutating the cursor index in a single class-based lexer object, we do lose the facility to cache tokens created during speculative lookaheads; i.e. backtracking to an earlier lexer state means discarded tokens must be recreated again [although, touch-wood, any backtracking we do in practice will be minimal, rarely discarding more than 1 or 2 tokens]; plus, of course, once an individual line is fully tokenized, those tokens are cached by EditableScript, and it's whole-script parsing where costs become significant)


import Foundation


/* the basic single-line lexer (LineReader) identifies:

- reserved (core) punctuation (expr separators and grouping delimiters)

- contiguous digits (.digits)
 
- contiguous symbols [S* and P*, excluding core punctuation] (.symbols)

- contiguous whitespace [excluding linebreaks] (this is affixed to adjoining tokens; it is not a token itself)
 
- non-whitespace control characters and illegal Unicode (.invalid)

- all other contiguous chars (.letters) (in future this might be inclusive [L*], rather than exclusive [everything but the above], with .invalid as the catchall)
 
 */

// Q. how best to match combinations of alnum and symbol chars, e.g. `-180°C`, `($12.20)`?



// when tokenizing for pretty-printing/code highlighting, how to organize tokens/offsets for different display representations (e.g. basic formatting describes token types - name/operator/string literal/number literal/punctuation/annotation - but other presentations - e.g. hierarchical [literate] outline, where heading annotations and handler definitions are highlighted - should be easily and instantly switchable; similarly, library-defined command and operator names should highlight when a given library import is selected; plus syntax errors, semantic ambiguities, unrecognized names, constraint mismatches, suspect spellings, character spoofing, etc should all be highlightable [spoofing checks will need to look for mixed alphabets within words, although quite how that'll work with languages that naturally mix character sets will need further thought])


// code editor also needs ability to indicate inferred punctuation when user highlights command (e.g. `set x to: y` is shorthand for explicit `set {x, to: y}`) [generating this representation is responsibility of EditableScript + appropriate pretty-printer]

// Q. is NSAttributedString user-extensible? pretty-printers need to attach semantic as well as style info; if not, will need to implement String-like values similar to kiwi's RichText and CompositeText

// Q. should underscore (`_`) be tokenized separately to contiguous digit/alpha chars? (that puts onus on parser to determine underscore's meaning); assmuning underscores [like commas] are treated as separator tokens, how should they be disambiguated? e.g. for long decimal numbers, it would be helpful if commas can be used as thousands separators, though this requires disambiguation from commas used as expr separators (e.g. as determined by presence/absence of other whitespace after comma; non-linebreak whitespace might even be classed as a 'separator', with a partial parser sitting between lexer and full parser responsible for resolving separators and nothing else; this would also make it easier to localize number parsing in general, allowing user scripts to declare, e.g. `number_format #European` to switch numeric parsing from standard UK/US `1,234,567.89` format to `1.234.567,89` without needing special hooks into lexer/parser)


// note that simple 'dumb' rules should be applied when parsing punctuation-less commands: the goal is to achieve the simplest, flattest (i.e. most predictable) structure that is syntactically correct; inferring the correct semantic groupings (which may involve reassociating some arguments with different commands [or flagging for user to resolve when ambiguous] once detailed handler interface information for those commands is available), e.g. flattest resolution of `foo bar: 1 baz: fub zub: 2` is `foo {bar: 1, baz: fub, zub: 2}`, whereas tail resolution is `foo {bar: 1, baz: fub {zub: 2}}`; even more matches are possible if all arguments are unlabeled, e.g. `foo 1 bar 2 3` might be `foo {bar, 2, 3}`, `foo {bar {2}, 3}`, or `foo {bar {2, 3}}` (not to mention `foo 1, bar 2 3` is a possible interpretation if we also anticipate users forgetting to type the expr separator [a common novice error in kiwi])


// another reason to keep lexer-parser coupling really loose is when parsing for quoting balancing/indentation only; again, that doesn't require full parser, and shouldn't even care about meanings of words or separator punctuation between them; it should only look for quoting chars - [](){}«»"“”'‘’ - and surrounding whitespace (while not structural, whitespace indentation can be inspected to best-guess where code editor should propose re-balancing unbalanced quotes to user)


// important: when disambiguating +/- and other operators that are both prefix and infix, it is necessary to examine whitespace on both sides of operator, along with preceding symbol [if it's a name], e.g. `foo-2` = `foo - 2` = `foo {} - 2`, whereas `foo -2` = `foo {-2}` and `foo- 2` is flagged as a syntax error (Q. since scripts containing syntax errors can still be run, how should this syntactic construct be represented in AST?)

// Q. given that handlers are first-class values, how should an ambiguous syntactic construct such as `foo {1, 2} baz` be treated? it may be user forgot to insert expr separator (e.g. `,`) after record, or it may be that the 'foo' handler returns another handler which is to be invoked with the `baz` expr as its argument; probably best to flag as ambiguous and move on (c.f. a word processor's grammar checker); if the user runs the script unamended then, as with other syntax errors, this AST node should prompt for clarification if/when evaled; e.g. if we define a grammatical convention where parens disambiguate chained calls `(foo…)(baz), - i.e. `(COMMAND1)(ARGUMENT2)`, which is clearly distinct from `COMMAND1, COMMAND2` - then the code editor can substitute the correct representation and continue; caution: also consider `foo 1 2 baz`, which is arguably even more ambiguous - assuming implicit record punctuation, it is read as `foo {1, 2, baz}`; we can avoid this ambiguity if implicit records are limited to an initial field which may be unlabeled followed by zero or more fields which MUST be labeled, e.g. `foo 1 by: 2 baz` gets us back to the initial two interpretations (missing expr separator/chained call) and resolve from there as before (given that SDEF-defined commands already follow this pattern, this is probably a reasonable compromise, plus it encourages use of labeled over unlabeled arguments which is both more robust against future handler interface changes and makes user's code much more self-explanatory)


// Q. should operator-defined names default to command names if code's fixity doesn't match, or should they be treated as syntax error? e.g. `mod` is an infix operator, so what if it appears with one or no operands? [since the operator and command names are the same, it's going to invoke the operator's underlying command in any case]; TBH, this is more a question of multimethods, as the most obvious homonym, `-`, requires two different implementations for prefix vs infix use, but whereas entoli/sylvia defined two different command names, `negate` vs `subtract`, we really want to keep the canonical name as `-` in both cases (although `negate` and `subtract` could still be defined as synonyms [Q. how to control synonyms’ invisible namespace pollution?]) [addendum: `-` can in fact be implemented as a single `subtract` command by making the left operand optional with 0 as default, in which case negation is really `0 - N`]


// when reading low-punctuation commands, should label:value arguments be associated with first (flattest) or last (latest) command name? e.g. given `foo bar baz:1`, should this parse as `foo {bar, baz:1}` or `foo {bar {baz:1}}`? one argument in favor of the latter: a common idiom in AS is `set VAR to COMMAND`, where the 'set' command binds the result of 'COMMAND' to the given variable name; obviously we want [e.g.] `set x to: make new: document with_properties: {name:"test"}` to parse as `set x to: (make new: document with_properties: {name:"test"})`, not `set x to: (make) new: document with_properties: {name:"test"}` (Q. are there any common cases where 'flattest' is the desired form? if not, 'latest' form wins on `set…` alone); in practical use, of course, the code editor can intelligently infer nested commands' argument associations based on handler interface definitions obtained from both local code and imported libraries (as well as generated interface definitions constructed from [e.g.] application SDEFs), and pretty-print the disambiguated code [or prompt the user to disambiguate manually if still unclear]; the default association rule is merely the dumb 'base state' where additional information is not available; either way, a given source code is *always* unambiguous (which is not to say it's functionally correct, only that it will be parsed 100% predictably; it’s for the code editor and the user to figure out the intended interpretation between themselves and insert any additional punctuation where needed)

// Q. should `;` be an operator? (probably not; the 'everything is a command' and 'command pipeline' idioms push for it being part of core punctuation; plus, like other separator punctuation, it probably needs special rules to allow it to appear at end of lines [chances are, operators will disallow interstitial linebreaks entirely, while low-punctuation commands will only allow linebreaks when entire command is parenthesized [with obligatory automatic indentation to ensure clear visual alignment]; lists and records will allow linewrapping after ',' separators, of course])



// TO DO: should next reader be bound to Token? (this'd make token structs a bit fatter, but has the benefit that interactive autosuggest/autocorrect can easily look at a line's unresolved tokens and try different solutions, to see which provides the best outcome; note: given that LineReader is scanning the original string, this might require some jiggery to step over the original, unwanted token[s], using UnpopToken to 'reinsert' our attempted 'fix' tokens, then get the whole thing re-reading as before - which means the unpop needs to be wrapped in the line reader's adapters as well, which means passing it thru EditableScript.reader())


struct LineReader: TokenReader { // don't think lexer should care if it's at start of line or start of script; that's the parser's problem when reading multiline exprs (e.g. lists/records wrapped over multiple lines); note that trailing `.` after digits at EOL is expr separator; the numeric parser (which is strictly single-line) will detect the incomplete match for [e.g.] `123.` and split off the `.` to yield `.value(123)` and `.periodSeparator` tokens, leaving next [block] parser to deal with trailing period (comma and period separators describe blocks, e.g. `To foo{} do_this, do_that, do_the_other. 123.` should parse as `(to foo{} (do_this, do_that, do_the_other)) (123)`. Longer blocks may be delimited using `do…done` for readability, giving us 3 different syntaxes to write a block.)

    let code: String // the entire script // TO DO: should probably be pre-split into single lines; that way, each single-line Lexer instance isn't affected when changes are made to other lines (only the modified lines need new lexers)
    let leadingWhitespace: Substring?
    let offset: String.Index
    let isFirst: Bool
    
    // TO DO: should code also be Substring? (e.g. script.split() returns Array<Substring>); challenge is dealing with editing: every time a line of code is changed, it's probably better to put a new String into script array
    
    internal init(code: String, at offset: String.Index, after whitespace: Substring?, isFirst: Bool = false) {
        self.code = code
        self.offset = offset
        self.leadingWhitespace = whitespace
        self.isFirst = isFirst
    }
    
    init?(_ code: String) { //
        assert(code.firstIndex(where: linebreakCharacters.contains) == nil) // LineLexers process single lines only, so should never receive a string containing linebreak chars
        guard let offset = code.firstIndex(where: nonWhitespaceCharacters.contains) else { return nil } // scan over the line's leading whitespace, returning nil if string is empty/entirely whitespace (i.e. no tokens to read, in which case it's not worth constructing a lexer for it)
        self.init(code: code, at: offset, after: offset == code.startIndex ? nil : code[code.startIndex..<offset], isFirst: true)
    }
    
    // be aware String.endIndex is after last character's index, so s[s.endIndex] is fatalError
    
    
    private func read(characters: CharacterSet) -> (Substring, String.Index) {
        let end: String.Index
        if let endOffset = self.code.suffix(from: self.offset).firstIndex(where: { !digitCharacters.contains($0) }) {
            end = endOffset
        } else {
            end = self.code.endIndex
        }
        return (self.code[self.offset..<end], end)
    }
    
    func advanceOver(_ characters: CharacterSet) -> String.Index { // returns index of first character not in given character set
        if let endOffset = self.code.suffix(from: self.offset).firstIndex(where: { !characters.contains($0) }) {
            assert(endOffset != self.offset) // bug: tokens cannot be zero-length
            return endOffset
        } else {
            return self.code.endIndex
        }
    }
    
    func advanceByOne() -> String.Index {
        return self.code.index(after: self.offset)
    }
    
    func next() -> (Token, TokenReader) {
        if self.offset == self.code.endIndex { return (nullToken, nullReader) } // always return .eol once line reader is exhausted // caution: the EOL token is purely a marker; unlike other tokens it does not capture the line's trailing whitespace or endIndex // note: while we could eliminate .eof by returning `(Token,TokenReader)?`, the current arrangement arguably makes binding the result simpler (less `if let tmp =…` shuffling), and .eol tokens may well be needed anyway when recombining the output of multiple single-line lexers [with partial parsing of numerics and operators] in order to perform the final multi-line parse by which a complete AST (or completed partial sub-trees plus rebalancing 'bad syntax' tokens when the script's syntax is not 100% correct) is assembled
        // read one token (self.offset = first character of new token)
        let form: Token.Form
        let tokenEnd: String.Index
        let firstCharacter = self.code[self.offset]
        if let punctuationForm = Token.corePunctuation[firstCharacter] { // core punctuation character
            if case .nameDelimiter = punctuationForm { // found a single quote
                let start = self.advanceByOne() // step over opening quote
                // find the closing quote (string/annotation/linbreak)
                if let endOffset = self.code.suffix(from: start).firstIndex(where: { !quotedNameCharacters.contains($0) }) {
                    if quotedNameDelimiterCharacters.contains(self.code[endOffset]) { // found closing quote
                        tokenEnd = self.code.index(after: endOffset) // step over closing quote
                        form = .quotedName(String(self.code[start..<endOffset]))
                    } else { // found a character not allowed within single-quoted text (e.g. double quote/annotation delimiter); whether or not this actually is a syntax error depends on whether it's outside or inside a string/annotation literal; either way, we terminate this token on it so that the rest of the line is tokenized as usual
                        tokenEnd = endOffset
                        form = .error(BadSyntax.unterminatedQuotedName)
                    }
                } else { // reached end of line without finding a closing quote; whether or not this actually is a syntax error depends on whether it's outside or inside a string/annotation literal
                    tokenEnd = self.code.endIndex
                    form = .error(BadSyntax.unterminatedQuotedName)
                }
            } else {
                form = punctuationForm
                tokenEnd = self.advanceByOne() // advance one character
            }
        } else {
            // TO DO: should we treat +/- as a special case, given its close relationship to digits? (the question is how that interacts with operator matching; e.g. we could make similar arguments for `e` and `x` given their part in constructing sci and hex notations, but we definitely wouldn't split those out)
            switch firstCharacter {
            case digitCharacters: // contiguous digits
                form = .digits
                tokenEnd = self.advanceOver(digitCharacters)
            case wordCharacters:
                form = .letters
                tokenEnd = self.advanceOver(wordCharacters)
            case symbolCharacters: // non-core punctuation and symbols (some chars might be aliased to core punctuation in future i18n support, some may be library-defined operator names; the rest will be [most likely] flagged as bad syntax and ignored/discarded); caution: this includes +/- characters, which may be prefixed to number literals
                form = .symbols
                tokenEnd = self.advanceOver(symbolCharacters) // decomposing a run of symbol characters is left to downstream readers (while we could return single characters here, it generates more tokens than necessary when reading annotations and string literals; e.g. `«==== WORD ====»` [a Markdown heading] generates 5 tokens, not 11)
            default:
                form = .invalid
                tokenEnd = self.advanceByOne() // this assumes invalid chars are relatively rare; if common, we'd want to match sequences
            }
        }
        let content = self.code[self.offset..<tokenEnd]
        // read any whitespace after this token
        let trailingWhitespace: Substring?
        let nextOffset: String.Index
        if tokenEnd == self.code.endIndex { // have we reached end of line?
            // no whitespace or tokens left
            nextOffset = self.code.endIndex
            trailingWhitespace = nil
        } else { // more whitespace and/or tokens to read
            let start = tokenEnd // tokenEnd = first char after token
            if let end = self.code.suffix(from: start).firstIndex(where: nonWhitespaceCharacters.contains) {
                nextOffset = end // found another token
                trailingWhitespace = end == start ? nil : self.code[start..<end] // get any whitespace before it
            } else {
                nextOffset = self.code.endIndex // no more tokens to read
                trailingWhitespace = self.code.suffix(from: start) // rest of line is whitespace
                // TO DO: should we bother capturing whitespace at end of line, or just discard it?
            }
        }
        let position: Token.Position = self.isFirst ? .first : nextOffset == self.code.endIndex ? .last : .middle
        let result = Token(form, self.leadingWhitespace, content, trailingWhitespace, position)
        let lexer = LineReader(code: self.code, at: nextOffset, after: trailingWhitespace)
        return (result, lexer)
    }
    

}



// note that table-driven parsing allows parser to look up where a found token is expected to appear when unable to reduce it
