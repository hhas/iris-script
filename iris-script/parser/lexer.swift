//
//  lexer.swift
//  iris-script
//

import Foundation


// needs to distinguish:

// reserved punctuation

// contiguous alphanumeric (digits, Latin, Cyrillic, Arabic, Han, etc) with interstitial underscores

// linebreaks

// contiguous whitespace

// any other contiguous chars


// Q. how best to match combinations of alnum and symbol chars, e.g. `-180°C`, `($12.20)`?


// when tokenizing for pretty-printing/code highlighting, how to organize tokens/offsets for different display representations (e.g. basic formatting describes token types - name/operator/string literal/number literal/punctuation/annotation - but other presentations - e.g. hierarchical [literate] outline, where heading annotations and handler definitions are highlighted - should be easily and instantly switchable; similarly, library-defined command and operator names should highlight when a given library import is selected; plus syntax errors, semantic ambiguities, unrecognized names, constraint mismatches, suspect spellings, character spoofing, etc should all be highlightable [spoofing checks will need to look for mixed alphabets within words, although quite how that'll work with languages that naturally mix character sets will need further thought])


// code editor also needs ability to indicate inferred punctuation when user highlights command (e.g. `set x to: y` is shorthand for explicit `set {x, to: y}`), though this is probably parser's responsibility

// Q. should underscore (`_`) be tokenized separately to contiguous digit/alpha chars? (that puts onus on parser to determine underscore's meaning); assmuning underscores [like commas] are treated as separator tokens, how should they be disambiguated? e.g. for long decimal numbers, it would be helpful if commas can be used as thousands separators, though this requires disambiguation from commas used as expr separators (e.g. as determined by presence/absence of other whitespace after comma; non-linebreak whitespace might even be classed as a 'separator', with a partial parser sitting between lexer and full parser responsible for resolving separators and nothing else; this would also make it easier to localize number parsing in general, allowing user scripts to declare, e.g. `number_format #European` to switch numeric parsing from standard UK/US `1,234,567.89` format to `1.234.567,89` without needing special hooks into lexer/parser)


// note that simple 'dumb' rules should be applied when parsing punctuation-less commands: the goal is to achieve the simplest, flattest (i.e. most predictable) structure that is syntactically correct; inferring the correct semantic groupings (which may involve reassociating some arguments with different commands [or flagging for user to resolve when ambiguous] once detailed handler interface information for those commands is available), e.g. flattest resolution of `foo bar: 1 baz: fub zub: 2` is `foo {bar: 1, baz: fub, zub: 2}`, whereas tail resolution is `foo {bar: 1, baz: fub {zub: 2}}`; even more matches are possible if all arguments are unlabeled, e.g. `foo 1 bar 2 3` might be `foo {bar, 2, 3}`, `foo {bar {2}, 3}`, or `foo {bar {2, 3}}` (not to mention `foo 1, bar 2 3` is a possible interpretation if we also anticipate users forgetting to type the expr separator [a common novice error in kiwi])


// another reason to keep lexer-parser coupling really loose is when parsing for quoting balancing/indentation only; again, that doesn't require full parser, and shouldn't even care about meanings of words or separator punctuation between them; it should only look for quoting chars - [](){}«»"“”'‘’ - and surrounding whitespace (while not structural, whitespace indentation can be inspected to best-guess where code editor should propose re-balancing unbalanced quotes to user)


// important: when disambiguating +/- and other operators that are both prefix and infix, it is necessary to examine whitespace on both sides of operator, along with preceding symbol [if it's a name], e.g. `foo-2` = `foo - 2` = `foo {} - 2`, whereas `foo -2` = `foo {-2}` and `foo- 2` is flagged as a syntax error (Q. since scripts containing syntax errors can still be run, how should this syntactic construct be represented in AST?)

// Q. given that handlers are first-class values, how should an ambiguous syntactic construct such as `foo {1, 2} baz` be treated? it may be user forgot to insert expr separator (e.g. `,`) after record, or it may be that the 'foo' handler returns another handler which is to be invoked with the `baz` expr as its argument; probably best to flag as ambiguous and move on (c.f. a word processor's grammar checker); if the user runs the script unamended then, as with other syntax errors, this AST node should prompt for clarification if/when evaled; e.g. if we define a grammatical convention where parens disambiguate chained calls `(foo…)(baz), - i.e. `(COMMAND1)(ARGUMENT2)`, which is clearly distinct from `COMMAND1, COMMAND2` - then the code editor can substitute the correct representation and continue; caution: also consider `foo 1 2 baz`, which is arguably even more ambiguous - assuming implicit record punctuation, it is read as `foo {1, 2, baz}`; we can avoid this ambiguity if implicit records are limited to an initial field which may be unlabeled followed by zero or more fields which MUST be labeled, e.g. `foo 1 by: 2 baz` gets us back to the initial two interpretations (missing expr separator/chained call) and resolve from there as before (given that SDEF-defined commands already follow this pattern, this is probably a reasonable compromise, plus it encourages use of labeled over unlabeled arguments which is both more robust against future handler interface changes and makes user's code much more self-explanatory)


// Q. should operator-defined names default to command names if code's fixity doesn't match, or should they be treated as syntax error? e.g. `mod` is an infix operator, so what if it appears with one or no operands? [since the operator and command names are the same, it's going to invoke the operator's underlying command in any case]; TBH, this is more a question of multimethods, as the most obvious homonym, `-`, requires two different implementations for prefix vs infix use, but whereas entoli/sylvia defined two different command names, `negate` vs `subtract`, we really want to keep the canonical name as `-` in both cases (although `negate` and `subtract` could still be defined as synonyms [Q. how to control synonyms’ invisible namespace pollution?]) [addendum: `-` can in fact be implemented as a single `subtract` command by making the left operand optional with 0 as default, in which case negation is really `0 - N`]


// when reading low-punctuation commands, should label:value arguments be associated with first (flattest) or last (latest) command name? e.g. given `foo bar baz:1`, should this parse as `foo {bar, baz:1}` or `foo {bar {baz:1}}`? one argument in favor of the latter: a common idiom in AS is `set VAR to COMMAND`, where the 'set' command binds the result of 'COMMAND' to the given variable name; obviously we want [e.g.] `set x to: make new: document with_properties: {name:"test"}` to parse as `set x to: (make new: document with_properties: {name:"test"})`, not `set x to: (make) new: document with_properties: {name:"test"}` (Q. are there any common cases where 'flattest' is the desired form? if not, 'latest' form wins on `set…` alone); in practical use, of course, the code editor can intelligently infer nested commands' argument associations based on handler interface definitions obtained from both local code and imported libraries (as well as generated interface definitions constructed from [e.g.] application SDEFs), and pretty-print the disambiguated code [or prompt the user to disambiguate manually if still unclear]; the default association rule is merely the dumb 'base state' where additional information is not available; either way, a given source code is *always* unambiguous (which is not to say it's functionally correct, only that it will be parsed 100% predictably; it’s for the code editor and the user to figure out the intended interpretation between themselves and insert any additional punctuation where needed)

// Q. should `;` be an operator? (probably not; the 'everything is a command' and 'command pipeline' idioms push for it being part of core punctuation; plus, like other separator punctuation, it probably needs special rules to allow it to appear at end of lines [chances are, operators will disallow interstitial linebreaks entirely, while low-punctuation commands will only allow linebreaks when entire command is parenthesized [with obligatory automatic indentation to ensure clear visual alignment]; lists and records will allow linewrapping after ',' separators, of course])


private let nullToken = Token(form: .eol, content: "", whitespaceBefore: nil, whitespaceAfter: nil) // TO DO: should nullToken include actual whitespace info (i.e. any whitespace at end of line, plus linebreak if more lines follow?)




struct Lexer { // don't think lexer should care if it's at start of line or start of script; that's the parser's problem when reading multiline exprs (e.g. lists/records wrapped over multiple lines); note that trailing `.` after digits at EOL is expr separator; the numeric parser (which is strictly single-line) will detect the incomplete match for [e.g.] `123.` and split off the `.` to yield `.value(123)` and `.periodSeparator` tokens, leaving next [block] parser to deal with trailing period (comma and period separators describe blocks, e.g. `To foo{} do_this, do_that, do_the_other. 123.` should parse as `(to foo{} (do_this, do_that, do_the_other)) (123)`. Longer blocks may be delimited using `do…done` for readability, giving us 3 different syntaxes to write a block.)

    let code: String // the entire script // TO DO: should probably be pre-split into single lines; that way, each single-line Lexer instance isn't affected when changes are made to other lines (only the modified lines need new lexers)
    let leadingWhitespace: Substring?
    let offset: String.Index
    
    // TO DO: should code also be Substring? (e.g. script.split() returns Array<Substring>); challenge is dealing with editing: every time a line of code is changed, it's probably better to put a new String into script array
    
    internal init(code: String, at offset: String.Index, after whitespace: Substring?) {
        self.code = code
        self.offset = offset
        self.leadingWhitespace = whitespace
    }
    
    init?(_ code: String) { //
        assert(code.firstIndex(where: linebreakCharacters.contains) == nil) // lexers process single lines only, so should never receive a string containing linebreak chars
        // Q. how do `firstIndex(where:)` vs `while nonWhitespaceCharacters.contains(code[offset]) {offset = code.index(after:offset)}` compare for speed?
        guard let offset = code.firstIndex(where: nonWhitespaceCharacters.contains) else { return nil } // scan over leading whitespace, returning nil if string is empty/entirely whitespace (i.e. no tokens to read); this should be a bit quicker than returning a lexer that immediately returns .eol
        self.init(code: code, at: offset, after: offset == code.startIndex ? nil : code[code.startIndex..<offset])
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
        
    func next() -> (Token, Lexer?) { // TO DO: return `(Token,Lexer)?` avoids need for .eof case
        if self.offset == self.code.endIndex { return (nullToken, nil) } // always return .eol once lexer is exhausted
        // start reading from current offset: this is [presumably] a switch that matches `self.code[self.offset]` against character sets (some cases match single token, others consume sequence of tokens that satisfy condition)
        let form: Token.Form
        let tokenEnd: String.Index
        let c = self.code[self.offset]
        if let punctuation = Token.corePunctuation[c] {
            form = punctuation
            tokenEnd = self.code.index(after: self.offset) // i.e. code[offset..<tokenEnd]
        } else if digitCharacters.contains(c) {
            if let endOffset = self.code.suffix(from: self.offset).firstIndex(where: { !digitCharacters.contains($0) }) {
                tokenEnd = endOffset
            } else {
                tokenEnd = self.code.endIndex
            }
            form = .digits
        } else {
            if let endOffset = self.code.suffix(from: self.offset).firstIndex(where: { !wordCharacters.contains($0) }) {
                tokenEnd = endOffset
                form = illegalCharacters.contains(self.code[endOffset]) ? .illegal : .word
            } else {
                tokenEnd = self.code.endIndex
                form = .word
            }
        }
        let content = self.code[self.offset..<tokenEnd]
        // now read any whitespace after this token
        let trailingWhitespace: Substring?
        let nextLexerOffset: String.Index
        
        if tokenEnd == self.code.endIndex { // have we reached end of line?
            // no whitespace or tokens left
            nextLexerOffset = self.code.endIndex
            trailingWhitespace = nil
        } else { // more whitespace and/or tokens to read
            let start = tokenEnd // tokenEnd = first char after token
            if let nextTokenOffset = self.code.suffix(from: start).firstIndex(where: nonWhitespaceCharacters.contains) {
                nextLexerOffset = nextTokenOffset // found another token
                trailingWhitespace = nextTokenOffset == start ? nil : self.code[start..<nextTokenOffset] // get any whitespace before it
            } else {
                nextLexerOffset = self.code.endIndex // no more tokens to read
                trailingWhitespace = self.code.suffix(from: start) // rest of line is whitespace
            }
        }
        let result = Token(form: form, content: content, whitespaceBefore: self.leadingWhitespace, whitespaceAfter: trailingWhitespace)
        let lexer = Lexer(code: self.code, at: nextLexerOffset, after: trailingWhitespace)
        return (result, lexer) // TO DO: how to represent invalidated Lexer when EOL is reached? (code:…, at: self.code.endIndex, after:…)
    }
    

}



// note that table-driven parsing allows parser to look up where a found token is expected to appear when unable to reduce it
