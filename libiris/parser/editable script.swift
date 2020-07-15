//
//  script reader.swift
//  iris-script
//

import Foundation

// TO DO: give some thought to both in-process and out-of-process APIs; a native editor would typically parse and edit a script in-process, serializing it for execution in a sandboxed subprocess

// TO DO: balance counting per line needs to pass forward both counts so that they are picked up from the last line reader (or perhaps store them as `.lineBreak(bringForward:[Form], carryForward:[Form])`) // problem: what about string quotes? think all parens and quotes need to go on these lists - it's up to the rebalancer to count the string quotes and thus decide which parens to ignore as being inside quoted text

// TO DO: making line readers polymorphic for String or Substring may improve parsing times when reading for execution only


class ImmutableScript {
    
    let lines: [EditableScript.Line]
    let code: String
    
    init(lines: [EditableScript.Line], code: String) {
        self.lines = lines
        self.code = code
    }
}


public class EditableScript: CustomStringConvertible, CustomDebugStringConvertible { // TO DO: also cache parsed lines?
    
    // TO DO: pretty printer should read tokens (Q. what about ability to pretty print only lines that have changed? e.g. this suggests Line should use counter; each time pp is called, it returns reprinted lines plus an opaque counter token; passing token back on next pp call, only lines that have a higher count need be reprinted); note: pp itself needs to be fully customizable, able to generate multiple representations of the same code (e.g. basic pp would highlight keywords and literals; literate pp would highlight heading annotations and handler definitions; structural pp would emphasize nesting; debug pp would highlight commands known to be effectful along with expr sequences ending in `?`/`!` modifiers; visual pp would output GUI form controls [need to look into SwiftUI for this]; pps should also be composable)
    
    public var description: String { return self.lines.map{ $0.code }.joined(separator: "\n") }
    
    public var debugDescription: String { return self.lines.enumerated().map{ "\(String(format: "%4i", $0+1)). \($1.tokens.map{ "\($0)" }.joined(separator: "\n      "))" }.joined(separator: "\n") }
    
    public typealias LineReaderAdapter = (LineReader) -> LineReader // input is usually a BaseLexer struct, but could also be UnpopToken or other adapter (e.g. when autocorrect is attempting to find best-guess solutions)
    
    private var lineIDCount: Int = 0 // every line of code has a unique ID, representing the order in which it was initially read/subsequently inserted; this should allow code editor to modify sections of script while preserving unmodified sections (this'll probably require an API for inserting new lines before[?] a given line no., and replacing/deleting existing lines given a Range of line nos., as well as an array of line nos when performing automatic refactorings (e.g. renamings); these line nos. corresponding to indexes and slices of self.lines, so unlike line IDs are transient; line IDs OTOH allow Lines to be located anywhere within script at any time [assuming they haven't been invalidated by edits], e.g. renaming engine would search all Lines for a given name [with some assistance from EditableScript to distinguish matches within code from matches within quotes], then replace those lines with new lines [which would be constructed from a modified version of the previous line's tokens array, rather than a modified source string])
    
    private let lineReaderAdapter: LineReaderAdapter
    
    public struct Line: Sequence, CustomDebugStringConvertible { // TO DO: Equatable (this might be done by comparing counts; comparing lines for [in]significant text changes is a separate task vs looking up the line no. of an existing line)
        
        // TO DO: for each line, is it worth keeping a quick-access array of its double-quote (and double-angle-quote) indices? i.e. to reduce string literals (which are initially multiple [to-be-discarded] tokens bounded by two .stringDelimiter tokens, possibly with `""` escapes as well), we need to scan the whole program doing a balance count (and when we do that, we want to try to be intelligent about guessing if any DQs are missing, even if the final count is even [i.e. balanced], which we can do by seeing how well each line of 'code' between any two quotes can reduce; actually, we could probably use a simpler heuristic: sequences of three or more non-keyword words that do not contain any colons are not valid LP commands which strongly implies they belong inside a string/annotation literal)
        
        public var debugDescription: String { return self.code.debugDescription } // TO DO: what to show?
        
        public var isEmpty: Bool { return self.tokens.isEmpty }
        
        public typealias Element = Token
        public typealias Iterator = Array<Element>.Iterator
        
        // TO DO: each line wants to know if it starts inside code, string literal, or annotation [including its nesting depth]; this info may change independent of the line itself when preceding lines are modified; in addition, each line probably wants to keep a summary of the code's nesting order+depth within parens/brackets/braces/block keywords, enabling imbalances to be quickly checked for and fixes proposed (bearing in mind that checks only need to be performed outward from newly inserted/deleted lines [i.e. if adjoining lines were correctly balanced before, any fresh imbalances are assumed to lie in or at edges of the edited section, with proposed fixers appearing in or at edges of that section [users can, of course, move those fixers inward or outward to encompass less or more code, with live non-destructive checking of how those moves affect balancing until the user approves/undos the edit]]); this suggests that lines array should contain a semi-mutable struct which encapsulates both the immutable Line and mutable balancing/editing info; alternatively, we might keep the edits in a separate data structure that can express multi-line information, increasing available information while decreasing the number of elements being iterated when analyzing that info (albeit more complex to implement); in theory we might even store all lines within such structures, allowing those structures to extend and divide themselves without having to track their Lines separately; it remains to be seen (a hybrid solution would be to make the lines array polymorphic for single Lines and grouped Chunks of lines, allowing sections of script the editor is confident are correct [either because they are unchanged since the last successful 'full parse' or because heuristics say they are highly consistent with code/non-code content and can pinch them off as 'presumed correct'])
        
        
        let code: String
        let tokens: [Token] // TO DO: var? (parser may need to insert 'fixers' for bad syntax); or just replace line?
        let id: Int // line ID; this is implemented as incrementing counter so no two lines within the same script should ever have the same ID; given a line ID, current line number can be calculated (e.g. when reporting error locations)
        
        // TO DO: also need to record carryForward + bringForward, which record the opening/closing/delimiter tokens that preceding and subsequent lines need to correctly balance the opening/closing/delimiter tokens that appear on this line
        
        public init(_ code: String, _ tokens: [Token], _ id: Int) {
            self.code = code
            self.tokens = tokens
            self.id = id
        }
        
        public __consuming func makeIterator() -> Iterator {
            return self.tokens.makeIterator()
        }
    }
    
    private(set) var lines: [Line] // TO DO: what API for inserting/deleting/replacing lines? (this may include placeholder lines whose only role is to re-balance parens during edits [i.e. lines before and after will indicate carryForward and bringForward])
    
    public var code: String { return self.lines.map{ $0.code }.joined(separator: "\n") }
    
    // TO DO: not sure how practical it is to fully tokenize all lines on initialization; we might want separate phases for reading top-level annotations (which include information needed to populate operator tables, localize literal value readers, set debug hooks, etc) vs reading code body (which requires the above config work to be completed first); obvious way to do this is to start with an AnnotationReader (if it's a single-line reader it'll need the parser to stitch together multiline annotations; if it's a multi-line reader it'll need applied before the main script reader, to which it supplies the parsed annotations and the offset at which to start reading code tokens; either way, it requires switching parsing modes at some point, although we can maybe limit switching points to a linebreak)
    
    public init(_ code: String, _ lineReaderAdapter: @escaping LineReaderAdapter = NumericReader.init) { // default adapter will eventually be a composite of multiple adapters
        self.lineReaderAdapter = lineReaderAdapter
        // need some fiddling here as swiftc won't allow map closure to capture self[.lineIDCount]
        var lineID = self.lineIDCount
        let lineCounter = { () -> Int in lineID += 1; return lineID }
        // TO DO: how much work to make tokenization lazy? (i.e. split the string, but defer reading it until first use, caching the result when done) [kinda depends on whether `lazy var tokens: Tokens = {…}}()` works with following closure]
        self.lines = code.split(omittingEmptySubsequences: false, whereSeparator: linebreakCharacters.contains).map({
            (line: Substring) -> Line in
            let code = String(line)
            var tokens = [Token]()
            if let lineReader = BaseLexer(code) {
                var lexer: LineReader = lineReaderAdapter(lineReader)
                var token: Token
                repeat {
                    (token, lexer) = lexer.next()
                    
                    // TO DO: how to record carryForward/bringForward? may be simplest with a switch(?) on token.form, a push-only list of unmatched closing tokens, a stack of matchable opening tokens; at eol, the former is stored as carryForward and latter is bringForward; TO DO: probably need to keep two of each, one that assumes the line starts outside of string/annotation literal, the other assuming the line starts inside (obviously we're doing quite a bit of redundant calculating here, on assumption that these will pay off from code editing POV; a run-only script would use a much simpler line-reading loop, eschewing the normal line reader when it knows it's inside a string/annotation literal and only scanning for and balance-counting quote characters, only switching back to the normal reader once it reaches the end of the quoted section; while syntax errors produced by these readers will be coarse and less helpful, more detailed descriptions can always be generated upon demand by re-reading the script using EditableScript [SyntaxError might even expose this via an `explain()` method]); simpler alternative may be to capture a single summary list of parens and quotes only, with no attempt to balance them (part of the problem with opportunistic balancing is we end up with multiple 'possibles' as there's more than one quoting scheme to consider); may be easiest if parser builds this, as it's already tracking balancing anyway (remember, the goal is to provide editor with quick hints as to where imbalances may be occurring, not formal verification; in practice, the parser may want to tag sections of code that it's confident are correct, e.g. complete handler definitions, or other top-level block structures that naturally divide at zero-indentation lines [a simple heuristic being to look for `to` operators at start of lines and check their existing indentations for a best-guess as to where each handler definition should end])
                    
                    tokens.append(token)
                    
                    // TO DO: parse here to avoid iterating tokens twice (caveat what to do when a syntax error is encountered, e.g. insert smallest-possible 'fixer' for the immediate issue and move on [bearing in mind a naive fix may create more syntax problems than it solves];)
                    
                } while token.form != .lineBreak && token.form != .endOfCode
            }
            return Line(code, tokens, lineCounter()) // TO DO: also capture next reader?
        })
        self.lineIDCount = lineID
    }
    
    public func lineNumber(forID lineID: Int) -> Int? {
        return self.lines.firstIndex(where: { $0.id == lineID })
    }
    
}

