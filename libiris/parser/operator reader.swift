//
//  operator reader.swift
//  iris-script
//

import Foundation


// TO DO: given undifferentiated .symbols token, decompose into one or more .symbols and/or .operator(PatternDefinition) tokens and unpop back onto token stream


// - word-based operators (e.g. `mod`) are whole-token match against .letters, caveat where word has contiguous `:` suffix indicating it's a record field/argument label


// - symbol-based operators (e.g. `≠`) require both whole-token matching and longest-substring-match of .symbol content (note that: whole-token matching of .symbol is just an opportunistic shortcut for a longest match that consumes all chars; it may or may not be worth the effort in practice, though seeing as it's one quick Dictionary lookup it hardly increases implementation complexity or performance overhead)


// Q. should we disallow digits within operator names? (probably: it'll keep operator matching much simpler; contiguous sequences of digits [and words] after a non-operator word can then unambiguously be reduced to single Name lexeme)

// note: 'longest match' cannot resolve ambiguous combinations where a .symbols content can be matched as either a long operator + unknown symbol or a shorter operator + longer operator; however, inclined to keep it that way as it makes grammar rules simple for user to memorize ("for alternate interpretation, stick a space in")


// Q. what about currency and measurement prefixes/suffixes? should they have their own single-task reader, or be provided as part of operator reader? (given that units attach directly to literal numbers and aren't meant to be parameterizable with arbitrary exprs [cf prefix/postfix operators], it's probably best to make them their own reader that adjoins the numeric reader)


// Q. when is a word not an operator? A. when it's a argument/field label; Addendum: also [probably] when it's part of a reverse domain name-style reference, e.g. `com.example.mod` should not treat `mod` as modulus operator or it's going to get messy [note: if user writes same reference using `of` operator, they will need to single-quote 'mod' to disambiguate]. Main gotcha here is that a postfix operator followed by a period looks awfully similar (however, if period is an expr delimiter it should have whitespace after it to disambiguate)


// Q. should `use` annotation automatically import syntax? (if so, how to ensure reliable syntax versioning?) also be aware that when importing syntax from >1 library [including stdlib], conflicting operator definitions will need to be resolved (this may be a reason to make `.syntax[.version]` mandatory: a library that starts out without operators but adds them later defeats the versioning)

// Q. if library A defines `*` and `**`, and library B defines `***`, how do we disambiguate? they won't report as a conflict when added to operator matching tables [since they don't terminate at the same node], and checking for all possible combination-based clashes is not scalable


// Q. how should e.g. `mod123` be parsed - as word operator + digits, or as [command] name?


// TO DO: need to rethink reader chaining as unwrapping/rewrapping of readers within next() is a giant PITA to get right; (from outside, we want something like monadic bind that pipelines output of one reader as input to next without the composing code having to worry about connection details)


public struct OperatorReader: LineReader {
    
    let reader: LineReader
    let operators: OperatorRegistry
    
    public var code: String { return self.reader.code }
    
    public init(_ reader: LineReader, for operators: OperatorRegistry) {
        self.reader = reader
        self.operators = operators
    }
    
    // TO DO: what about .unquotedName? (NameReader needs to apply first to concatenate underscore-separated .letters; however, trailing digits are also concatenated with or without underscores, e.g. `ISO_8601` but also `int64`, so we need a policy on if/where OperatorReader should be allowed to split unquotedName into .operatorName and .digits; note that this gets a lot hairier if NameReader also gets to concat symbols with digits, so we probably want to forbid that; only NumericReader should be concating .symbols when reading currencies/quantities, e.g. `32°C`, `$21.40`, `5€`)
    
    public func next() -> (Token, LineReader) {
        var (token, reader) = self.reader.next()
        reader = OperatorReader(reader, for: self.operators)
        switch token.form {
            // `where` filter is problematic as letters/symbols followed by colon may be record or dict keys; we can get around this by restricting dictionary keys to scalar literals, allowing context-free matching of `NAME ':'` pattern
        // TO DO: should OperatorReader require .letters to be already be reduced to .unquotedName?
        case .letters where reader.next().0.form != .colon, .unquotedName(_) where reader.next().0.form != .colon: // ignore if it's a field/argument `label:` // TO DO: this does not account for annotations appearing between label and colon (however, that's probably best considered a syntax error)
            if let definition = self.operators.matchWord(token.content) {
                token = token.extract(.operatorName(definition))
            }
        // TO DO [cont.]: if so, should .symbols also have a reduced form? (simplest would be to use modified version of PatternDefinition.Name enum in .unquotedName(_))
        case .symbols where reader.next().0.form != .colon:
            let matches = self.operators.matchSymbols(token.content)
            // TO DO: this'd be simpler if matchSymbols built and returned the new token stream (only issue is that matches are made first to last whereas unpopping tokens needs to be done from last match to first; i.e. use recursion rather than loop)
            if matches.count > 0 {
                var idx = token.content.endIndex
                for (substr, definition) in matches.reversed() {
                    if substr.endIndex != idx { // if operator is followed by non-operator symbols, put those back on token stream firt
                        reader = UnpopToken(token.extract(.symbols, from: substr.endIndex, to: idx), reader)
                    }
                    // put operator back on token stream
                    reader = UnpopToken(token.extract(.operatorName(definition), from: substr.startIndex, to: substr.endIndex), reader)
                    idx = substr.startIndex
                }
                
                if idx != token.content.startIndex { // return non-operator .symbols that appears before first operator
                    token = token.extract(.symbols, from: token.content.startIndex, to: idx)
                } else { // return first operator
                    (token, reader) = reader.next()
                }
            }
        default: ()
        }
        return (token, reader) // TO DO: it is awfully easy to forget to rewrap chained readers, and even easier to rewrap the wrong reader
    }
    
}



public func newOperatorReader(for operators: OperatorRegistry) -> EditableScript.LineReaderAdapter {
    return { (reader: LineReader) -> LineReader in return OperatorReader(reader, for: operators) }
}
