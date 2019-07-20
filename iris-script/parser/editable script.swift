//
//  script reader.swift
//  iris-script
//

import Foundation


// TO DO: give some thought to both in-process and out-of-process APIs; a native editor would typically parse and edit a script in-process, serializing it for execution in a sandboxed subprocess



// TO DO: balance counting per line needs to pass forward both counts so that they are picked up from the last line reader (or perhaps store them as `.eol(bringForward:[Form], carryForward:[Form])`) // problem: what about string quotes? think all parens and quotes need to go on these lists - it's up to the rebalancer to count the string quotes and thus decide which parens to ignore as being inside quoted text

// TO DO: making line readers polymorphic for String or Substring may improve parsing times when reading for execution only


class EditableScript: CustomStringConvertible, CustomDebugStringConvertible { // TO DO: also cache parsed lines?
    
    // TO DO: pretty printer should read tokens (Q. what about ability to pretty print only lines that have changed? e.g. this suggests Line should use counter; each time pp is called, it returns reprinted lines plus an opaque counter token; passing token back on next pp call, only lines that have a higher count need be reprinted); note: pp itself needs to be fully customizable, able to generate multiple representations of the same code (e.g. basic pp would highlight keywords and literals; literate pp would highlight heading annotations and handler definitions; structural pp would emphasize nesting; debug pp would highlight commands known to be effectful along with expr sequences ending in `?`/`!` modifiers; visual pp would output GUI form controls [need to look into SwiftUI for this]; pps should also be composable)
    
    var description: String { return self.lines.map{ $0.code }.joined(separator: "\n") }
    
    var debugDescription: String { return self.lines.enumerated().map{ "\(String(format: "%4i", $0+1)). \($1.tokens.map{ "\($0)" }.joined(separator: "\n      "))" }.joined(separator: "\n") }
    
    typealias LineReaderDecorator = (TokenReader) -> TokenReader // input is usually a LineReader struct, but could also be UnpopToken or other adapter (e.g. when autocorrect is attempting to find best-guess solutions)
    
    private var counter: Int = 0
    
    private let decorateLineReader: LineReaderDecorator
    
    // TO DO: how to make each line uniquely identifiable (e.g. include UUID or counter? or make Line a class and compare on object id?) e.g. when determining line no., need to get index of line within lines array each time (since edits may insert/remove lines)
    
    struct Line { // TO DO: Equatable (this might be done by comparing counts; comparing lines for [in]significant text changes is a separate task vs looking up the line no. of an existing line)
        
        let code: String
        let tokens: [Token]
        let count: Int
        
        // TO DO: also need to record carryForward + bringForward, which record the opening/closing/delimiter tokens that preceding and subsequent lines need to correctly balance the opening/closing/delimiter tokens that appear on this line
        
        init(_ code: String, _ tokens: [Token], _ count: Int) {
            self.code = code
            self.tokens = tokens
            self.count = count
        }
    }
    
    
    private(set) var lines: [Line] // TO DO: what API for inserting/deleting/replacing lines? (this may include placeholder lines whose only role is to re-balance parens during edits [i.e. lines before and after will indicate carryForward and bringForward])
    
    var code: String { return self.lines.map{ $0.code }.joined(separator: "\n") }
    
    init(_ code: String, _ decorateLineReader: @escaping LineReaderDecorator = NumericReader.init) {
        self.decorateLineReader = decorateLineReader
        self.counter += 1
        let count = self.counter
        self.lines = code.split(omittingEmptySubsequences: false, whereSeparator: linebreakCharacters.contains).map({
            (line: Substring) -> Line in
            let code = String(line)
            var tokens = [Token]()
            if let lineReader = LineReader(code) {
                var lexer: TokenReader = decorateLineReader(lineReader)
                var token: Token
                repeat {
                    (token, lexer) = lexer.next()
                    
                    // TO DO: how to record carryForward/bringForward? may be simplest with a switch(?) on token.form, a push-only list of unmatched closing tokens, a stack of matchable opening tokens; at eol, the former is stored as carryForward and latter is bringForward; TO DO: probably need to keep two of each, one that assumes the line starts outside of string/annotation literal, the other assuming the line starts inside (obviously we're doing quite a bit of redundant calculating here, on assumption that these will pay off from code editing POV; a run-only script would use a much simpler line-reading loop, eschewing the normal line reader when it knows it's inside a string/annotation literal and only scanning for and balance-counting quote characters, only switching back to the normal reader once it reaches the end of the quoted section; while syntax errors produced by these readers will be coarse and less helpful, more detailed descriptions can always be generated upon demand by re-reading the script using EditableScript [SyntaxError might even expose this via an `explain()` method]); simpler alternative may be to capture a single summary list of parens and quotes only, with no attempt to balance them (part of the problem with opportunistic balancing is we end up with multiple 'possibles' as there's more than one quoting scheme to consider); may be easiest if parser builds this, as it's already tracking balancing anyway (remember, the goal is to provide editor with quick hints as to where imbalances may be occurring, not formal verification; in practice, the parser may want to tag sections of code that it's confident are correct, e.g. complete handler definitions, or other top-level block structures that naturally divide at zero-indentation lines [a simple heuristic being to look for `to` operators at start of lines and check their existing indentations for a best-guess as to where each handler definition should end])
                    
                    tokens.append(token)
                    
                    // TO DO: parse here to avoid iterating tokens twice (caveat what to do when a syntax error is encountered, e.g. insert smallest-possible 'fixer' for the immediate issue and move on [bearing in mind a naive fix may create more syntax problems than it solves];)
                    
                } while !token.isEnd
            }
            return Line(code, tokens, count) // TO DO: also capture next reader?
        })
    }
    
}


