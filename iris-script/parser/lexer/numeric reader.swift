//
//  numeric reader.swift
//  iris-script
//

import Foundation


// Q. what about quantities? (this'd include weights and measurements, temperature, currency; what else?) [A. not here; that stuff's for the numeric parser - or an extension to it - to identify, extract, and turn into completed .value tokens plus leftovers]


// see also sylvia-lang's Lexer.readNumber(), although may not want to use that particular implementation

// TO DO: might make sense for Number to accept decomposed (Int64,Int64,Int64); might also be an idea to generalize exponent (2e5 = 2*10^5) so that, say, 2^3 can be represented directly

/*
 
 DIGITS = ( '0' - '9' )+
 HEXA   = ( 'a' - 'f' | 'A' - 'F' )+
 SIGN   = ( '+' | '-' )
 
 // this matches multiple signs so parser can collapse them, e.g. `-+-1` -> `1`; is that what we want? (OTOH, >1 sign after `e` is a failed match, same as in AS [which flags it as a syntax error and rejects the code, whereas we still want to shift-reduce it all the way to an AST that encapsulates syntax errors in BadSyntax values])
 NUMBER = SIGN* (
            ( '0' ( 'x' | 'X' ) ( HEXA | DIGITS )+ ) |
            DIGITS ( '.' DIGITS )? ( ( 'e' | 'E' ) SIGN? DIGITS )?
          )
 
 
 */


struct NumericReader: TokenReader {
    
    let reader: TokenReader
    
    var code: String { return self.reader.code }
    
    init(_ reader: TokenReader) {
        self.reader = reader
    }

    // when a possible numeric token is encountered, attempt to read it and subsequent tokens, otherwise pass thru
    
    // note: because readers are immutable, with each reader representing a fixed location in code, splitting a mixed-content word token into content of interest and other content is a matter of returning a token that captures one part and a reader that encapsulates the other; fully resolved content is returned as .value(Value), content still to be processed is returned as current/new token
    
    
    // for now, we ignore currency prefixes (`$`, `£`, etc) for sake of getting something up and running [and let's not even contemplate accountancy-style `($1.23)` to indicate negative values as that overloads the meaning of `(…)` something awful (expr grouping vs negation)]; we probably can handle [mostly alpha] suffixes that indicate units (`g`, `mm`, `°C`), although it's possible that this should be left to a downstream transform (since these suffixes may appear as a complete .word or as first portion of a mixed-meaning .word where the next portion is an unprocessed operator name, e.g. `/`, that needs split off into its own .lexeme; besides which, quantities are probably better represented as `Quantity(Scalar,Units)` structs than an all-in-one Numeric case [which'd force us to pick a specific representation, e.g. Double, for the numeric part since enum types aren't recursive for obvious reasons])
    
    
    // TO DO: also [+-]?0[xX]DIGITS
    
    // for now, hardcode basic implementation that matches [+-]?DIGITS[.DIGITS]?, ignoring trailing token; for full implementation, with support for hex/sci notation, thousands separators, l10n, and currency/quantity units, we may want to use the same table-driven pattern matching engine as the main multiline parser
    
    
    // TO DO: unsigned
    
    func readNumber(_ token1: Token, _ reader1: TokenReader, sign: Token? = nil) -> (Token, TokenReader)? {
        // read unsigned
        if case .digits = token1.form {
            let startToken = sign ?? token1 // TO DO: fix this; if sign token contains more than a single +/- at end, trim all +/- chars from end, keeping tally of whether or not number is negative (caution: watch out for, e.g. `foo+-1`, which is a legal if ambiguous expr [it could mean `(foo) + (-1)` or `foo {+-1}`, though in practice we rely on contiguous whitespace and any operator definitions to figure it out]; might be safer just to take the last char to determine number literal's sign, and throw the rest back onto the token stream); any chars left after end trim needs to go back on token stream (i.e. nextReader needs to be wrapped in UnpopToken before returning it)
            var (endToken, nextReader) = (token1, reader1)
            let (token2, reader2) = reader1.next()
            if case .period = token2.form, token2.isContiguous { // check for `.DIGITS`
                let (token3, reader3) = reader2.next()
                if case .digits = token3.form {
                    endToken = token3
                    nextReader = reader3
                    // TO DO: also optional exponent
                }
            }
            let content = self.code[startToken.content.startIndex..<endToken.content.endIndex]
            // TO DO: Number should take individual components and construct best representation itself (or we could do that here and pass finished Int/Double/whatever to Number constructor); Q. should currency values automatically use Decimal rather than Double representation? how can we make these choices user-customizable via top-level annotations? (bearing in mind that any such customizations MUST have a known scope of influence; e.g. external libraries should still be parsed according to their own settings, but may adapt runtime behaviors such as numeric coercions when working with values supplied by main script)
            guard let n = try? Number(String(content)) else { fatalError("Couldn't parse number: '\(content)'") }
            return (Token(.value(n), startToken.whitespaceBefore, content, endToken.whitespaceAfter, startToken.position), nextReader)
        }
        return nil
    }
    
    func readSign(_ token: Token, _ reader: TokenReader) -> (Token, TokenReader)? {
        // check for +/- sign
        if case .symbols = token.form, numericSignCharacters.contains(token.content.last!), token.isRightContiguous {
            let (token1, reader1) = reader.next()
            return self.readNumber(token1, reader1, sign: token)
        } else { // read unsigned number
            return self.readNumber(token, reader)
        }
    }
    
    
    func next() -> (Token, TokenReader) {
        let (token, reader) = self.reader.next()
        if token.isPunctuation { // punctuation as expr delimiter
            let (token1, reader1) = reader.next()
            if let (token2, reader2) = self.readSign(token1, reader1) {
                return (token, NumericReader(UnpopToken(token2, reader2))) // put the parsed number back on the token stream
            }
        } else if token.hasLeadingWhitespace { // whitespace as expr delimiter
            if let (token1, reader1) = self.readSign(token, reader) {
                return (token1, NumericReader(reader1))
            }
        }
        return (token, NumericReader(reader)) // important: each reader adapter is responsible for redecorating the next reader with itself; we could push this behind an API, thus ensuring result of next() is automatically redecorated [as opposed to having to redecorate at every `return`, as above], though that adds complexity (particularly if an adapter *doesn't* want to redecorate remaining token stream [really not sure if that's a good idea though, as only reason to switch decorators is when context-sensitive parsing the contents of a code block, which 1. requires multi-line support + 2. the means to reattach the original decorator once end of block is reached; given that composable linereaders' job is to fully tokenize the code, not to parse it (excepting where reducing composite token sequences such as those that comprise number literals to atomic form)])
    }
}
