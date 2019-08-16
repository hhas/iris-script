//
//  parser protocols.swift
//  iris-script
//

import Foundation


// 'a3c' = auto-suggest, auto-correct, auto-complete


// extensible lexing/parsing, with emphasis on per-line processing to enable cheap, easy incremental re-parsing when code editing; i.e. we should treat text as text: if the user wants to express syntactically invalid constructs [e.g. pseudocode, plain language remarks] while formulating their scripts, let them do so freely without constant hassling about "syntax errors"; however, this should not prevent partial opportunistic parsing of those sections of script that do resemble valid code; in addition, we want to assist user with parens balancing when writing new code/rearranging existing code, and this includes having the smarts to make best-guesses at where missing opening/closing parens are meant to appear while code is unbalanced (e.g. if initial script is correctly balanced, then user adds/cuts/pastes/deletes some code in the middle that unbalances it, the editor can reasonably assume that the rebalancing should probably be done within or close to the edges of the affected area; i.e. an extra '[' near the start of the script should NOT throw a syntax error indicating a missing ']' at the end of the script; thus `balanced`->EDIT->`balanced unbalanced balanced`->REVIEW->`balanced unbalanced REPORT balanced`, NOT `balanced unbalanced balanced REPORT`) [e.g. in a mixed statement+expression language like Python, an unbalanced `[…]` or `(…)` would be detected at the start of the next statement, which is cheap and easy, but statements are a lousy code construct in every other respect—conceptual and implementation complexity, no composability, no extensibility—compared to expression-only syntax, so we must find other, smarter ways to provide cheap, easy boundary identification]


// note: while multi-step lexing is worse than single-pass O(n) lexing where all tokens are fully delimited and tagged, it shouldn't be drastically worse; i.e. initially undifferentiated words may be re-traversed two or three times as they are progressively broken down and precisely categorized; still, these might only account for 50% of the original code; the biggest hit will be string and annotation literals, as single-line lexing must tokenize their content even though those tokens will eventually be discarded once multi-line parsing correctly identifies the beginning and end of each quoted run; e.g. given `say "Hello, World!"`, there's no way for single-line reader to know sure that `say` is code and `Hello, World!` is quoted; it may be that the actual quoting started on an earlier line, in which case `say` is inside the quotes and `Hello, World!` are code [e.g. postfix `Hello` operator and `World` command], followed by a new string literal; in practice, there are some simple rules by which the relative likelihoods of each interpretation may be calculated; e.g. if there is a known operator named `hello` and a command or operator named `world` then either interpretation looks valid, otherwise it's far more likely that the quoted text is `Hello, World!`, even if an unbalanced `"` delimiter on an earlier line would tell a 'dumb' scanner [e.g. AppleScript's] otherwise


// TO DO: how should we represent the entire script decomposed into lines? there are two ways we could do this: 1. use script.split(omittingEmptySubsequences: false, whereSeparator: linebreakCharacters.contains) to split the script into lines on first pass, with line lexers performing a second pass, or 2. have CoreLexer take the entire script plus starting index, and populate the line array from that; TBH, the extra string copying is probably the least of our startup performance worries when parsing scripts for execution only (bear in mind that downstream readers will tend to re-traverse word tokens' content), while doing one big string split at the start puts us in a solid position for supporting incremental parsing when operating in code editing/REPL modes



protocol LineReader { // common API by which [partial] lexers and parsers can be chained together, in order to generate and consume tokens (and not solely in that order), and so incrementally convert the initial [and, in interactive code editing mode, mutable] source code to a complete AST [or again ,in editing mode, a mixture of completed sub-trees and unresolved tokens]
    
    // think we need a var to get at original code from which token's substrings is being obtained; i.e. if we want to 'concatenate' multiple substrings, not sure if slicing a substring with out-of-bounds indexes gets us back to original code or crash
    
    var code: String { get } // used when getting content substring spanning multiple tokens (caution: this includes raw whitespace between tokens; use e.g. matchedTokens.map{$0.content}.joined(separator:" ") to get whitespace-normalized content)
    
    func next() -> (Token, LineReader) // returns next token plus a reader for the remaining tokens (i.e. each reader represents a fixed point in the token stream, so to backtrack in next() just return the result token along with the tokenreader associated with the last token consumed)
    
    // TO DO: worth adding peek()? (while next() can safely be used for lookahead, it doesn't allow for, say, ignoring linebreaks or annotations)
}


