//
//  parser.swift
//  iris-script
//

import Foundation


// TO DO: perform top-level reductions within main parse loop; upon exhausting token stream break out of loop indicating if current code is a full parse or requires additional tokens to complete (provide a separate API for getting complete code as ScriptAST instance); allow a new token stream to be added so parsing can resume (this'll allow REPL to support multi-line input without implementing full per-line parser first); public read-only API for examining block stack (e.g. to determine automatic indentation level for new lines)

// TO DO: parser should keep error tally; in theory script should be [partially] runnable even with [some?] syntax errors, but problematic sections need marked and script should run in debug mode only with extra guards around anything IO (what about unmatched operators? can we infer where an opname is accidentally used where quoted name is needed [i.e. user needs to resolve naming conflict] vs an opname that has incorrect operands [user needs to fix operands]; how do we represent such unresolved syntax errors as Values [again, allowing other code to execute at least in debug mode])


public class Parser {
    
    public typealias Form = Token.Form
    
    public typealias BlockInfo = (start: Int, form: BlockType)
    
    public enum BlockType {
        case conjunction(Conjunctions) // conjunctions with trailing expr (e.g. `then`)
        case block(Conjunctions) // conjunctions with terminating keyword (e.g. `done`)
        case list
        case record
        case group
        case script
    }
    
    typealias BlockStack = [BlockInfo]

    public typealias ReduceFunc = PatternDefinition.ReduceFunc // (token stack, fully matched pattern, start, end)
    
    // TO DO: also capture source code ranges? (how will these be described in per-line vs whole-script parsing? in per-line, each line needs a unique ID (incrementing UInt64) that is invalidated when that line is edited; that allows source code positions to be referenced with some additional indirection: the stack frame captures first and last line IDs plus character offset from start of line)
    
    public typealias TokenInfo = (form: Form, matches: [PatternMatch], hasLeadingWhitespace: Bool) // in-progress/completed matches
    public typealias TokenStack = [TokenInfo]
    
    // parser state
    
    let operatorRegistry: OperatorRegistry // TO DO: we need to lock OR after we've read any include/exclude annotations at top of script and before we start reading code tokens; any subsequent attempts to add/remove opdefs mid-parse should be an error (we can transform the annotations to .error tokens easily enough)
    
    private(set) var current: DocumentReader // current token
    //private var annotations = [Token]() // TO DO: parser needs to bind extracted annotations to AST nodes automatically (this may be easier once TokenInfo includes line numbers)
    
    var tokenStack = TokenStack() // TO DO: should be private or private(set) (currently internal as reduction methods are in separate extension)
    
    // TO DO: blockStack currently assumes that all quoted text has already been reduced to string/annotation atoms so does not track the starts and ends of string or annotation literals; this is true for whole-program parsing (which is what we're limited to for now) but not in the case of malformed programs or per-line parsing; eventually it should be able to track those too (with the additional caveats that string literal delimiters lack unambiguous handedness in addition to all blocks being able to span multiple lines, so per-line parsing requires at least two alternate parses: one that assumes start of line is outside quoted text and one that assumes it is inside, and keep tallies of % of code that is valid reductions vs no. of parse errors produced, as well as any string/annotation delimiters encountered which indicate a transition from one state to another [with a third caveat that annotation literals must also support nesting])
    var blockStack: BlockStack = [(-1, .script)] // add/remove matchers for grouping punctuation and block operators as they’re encountered, along with conjunction matchers (the grouping matchers are added to mask the current conjunction matcher; e.g. given `tell (…to…) to …`, the `tell…to…` matcher should match the second `to`, not the first) // TO DO: should be private or private(set) (currently internal as reduction methods are in separate extension)
        
    public init(tokenStream: DocumentReader, operatorRegistry: OperatorRegistry) {
        self.current = tokenStream
        self.operatorRegistry = operatorRegistry
    }
    
    func peek(ignoringLineBreaks: Bool = false) -> DocumentReader {
        var reader: DocumentReader = self.current.next()
        while true {
            switch reader.token.form {
            case .annotation(_): () // TO DO: how to associate annotations with values? (for now we just discard them)
            case .lineBreak where ignoringLineBreaks: ()
            default: return reader
            }
            reader = reader.next()
        }
    }
    
    func advance(ignoringLineBreaks: Bool = false) {
        self.current = self.peek(ignoringLineBreaks: ignoringLineBreaks)
    }

    
    // callback hooks for inserting debugger commands into AST at parse-time // TO DO: is it appropriate/wise to treat these as stateful (i.e. debugger annotations can add/change/remove handlers at any point in parser), rather than scoped block structures (which would respect nested structures of program, inserting hooks at start of an annotated block and removing them automatically at its end)
    
    typealias PunctuationHandler = (Value) -> Value // optionally insert debugger commands when parsing .comma, .period, .query, and/or .exclamation delimiters
    
    var handlePeriod: PunctuationHandler?
    var handleComma: PunctuationHandler?
    var handleQuery: PunctuationHandler?
    var handleExclamation: PunctuationHandler?
    
    private func attachPunctuationHooks(using handler: PunctuationHandler?) {
        // TO DO: given `A,B,C!`, should `!` modifier apply to `C` only, or to `(A,B,C)!`, or to `A!B!C!`?
        // don't insert debugger command if preceding tokens can't be reduced to Value (i.e. punctuation modifies run-time behavior of the preceding value only, e.g. `Delete my_files!`)
        // TO DO: should lists and records only allow comma and/or LF as expr separators? (i.e. `EXPR?` and `EXPR!` could still be used if required, but they'd need explicitly parenthesized) [A: probably not as it's better to keep all rules consistent across all block structures; it would be better for block structures to emit hook messages that enable debugger to attach/detach/reattach user-defined hooks automatically upon e.g. entering/leaving list/record structures]
        // stack will be empty if punctuation appears at start of code; parser should probably detect and correct/reject obviously misplaced punctuation before it gets to here, but ignore it if it does
        if let fn = handler, case .value(let value) = self.tokenStack.last?.form { // assuming preceding token[s] have already reduced to a value (expr), get that value and pass it to hook function to wrap in a run-time modifier (e.g. a `Breakpoint` value)
            self.tokenStack[self.tokenStack.count-1].form = .value(fn(value))
        } // else if preceding tokens haven't [yet] been reduced, leave the punctuation token for later processing; TO DO: how to avoid double-handling when re-scanning stack (punctuation tokens are left on stack for pattern matching); simplest is to define DebugValue protocol and require callbacks to return that; current stack value can then be tested to see if it's already wrapped
    }
    
    
    // shift moves the current token from lexer to parser's stack and applies any new/in-progress matchers to it
    
    func shiftLabel(named name: Symbol) { // called by parser's main loop on encountering `NAME COLON` sequence (caution: caller should not shift NAME or COLON onto stack; instead NAME should be passed here as argument)
        self.shift(form: .label(name))
        self.advance() // perform a second advance() as this consumes 2 tokens (`NAME COLON`) instead of usual 1
    }
    
    
    func shift(form: Token.Form? = nil, adding newMatches: [PatternMatch] = [], from startIndex: Int = 0) {
        // startIndex provides left boundary for auto-reduction matches (e.g. given `[[]]`, the first `]` token should complete the second `[` match only and be ignored by the first)
        //print("SHIFTING .\(self.current.token.form) onto stack; start: \(startIndex), current head:", self.tokenStack.last?.form ?? .endOfCode)
     //   print("…", self.tokenStack.last?.matches ?? [])
        // normally the token being shifted is the current token in the parser’s token stream; however, in some special cases parser’s main loop performs an immediate reduction without first shifting, in which case the reduced token form is passed here
        // to initiate one or more new pattern matches on a given token, the parser’s main loop should instantiate those pattern matchers and pass them here
        let form = form ?? self.current.token.form
        var currentMatches = [PatternMatch]()   // new and in-progress matchers that match the current token; these will be pushed onto stack along with token
        var fullMatches = [PatternMatch]() // collects any current matches that complete on this token (these matches may or may not have longer matches available)
       // print("\n\nSHIFTING…")
       // self.tokenStack.show()
       // print()
        
        // advance any in-progress matches and match to this token
        if let previousMatches = self.tokenStack.last?.matches {
//            if form == .endGroup {
//                print("advancing previousMatches from token \(self.tokenStack.count-1):")
//                for m in previousMatches {print("- ", m)}
//                self.tokenStack.show()
//                print()
//            }
            for previousMatch in previousMatches {
                for match in previousMatch.next() {
                    if match.provisionallyMatches(form: form) {
                        // TO DO: what about conjunctions? we should be looking for those here
                        currentMatches.append(match)
                        // TO DO: this isn't quite right: there could be other, longer matches still in progress spawned from other operator definitions
                        if match.isLongestFullMatch && match.autoReduce { fullMatches.append(match) }
                    } else {
                        //print("%%% at \(self.tokenStack.count-1) did not provisionally match .\(form):", match)
                    }
                }
            }
        }
        // match new prefix/infix operator definitions to current or previous+current tokens; this back-matches by up to 1 token in the event the operator pattern starts with an EXPR followed by the operator itself (note: this does not match conjunctions as those should be at least two tokens ahead of the primary operator name)
        // important: this only handles the first conjunction in a pattern; subsequent conjunctions in the same pattern will be handled by reduceExpressionBeforeConjunction()
        var newConjunctionMatches = [PatternMatch]() // newly started matchers that are awaiting a conjunction keyword in order to complete their current EXPR match
        let stopIndex = self.tokenStack.count // after shifting, this is the index at which conjunction matches matched the operator name
        
        for match in newMatches {
            assert(match.isAtBeginningOfMatch)
            if match.provisionallyMatches(form: form) { // attempt to match first pattern to the current token; this allows new matchers to match atom/prefix operators (the first pattern is a .keyword and the current token is an .operatorName of the same name)
                currentMatches.append(match)
                // if the pattern contains one or more conjunctions (e.g. `then` and `else` keywords in `if…then…else…`) then push those onto blockStack so we can correctly balance nesting
                if match.hasConjunction { newConjunctionMatches.append(match) }
            } else if let previous = self.tokenStack.last, match.provisionallyMatches(form: previous.form) { // attempt to match the previous token (expr), followed by current token (opName); this allows new matchers to match infix/postfix operators (match starts on the token before .operatorName)
                let matches = match.next().filter{ $0.fullyMatches(form: form) } // re-match the current token (.operatorName); we have to do this to exclude conjunction keywords
                if !matches.isEmpty {
                    self.tokenStack[self.tokenStack.count - 1].matches.append(match) // preceding .expression
                    currentMatches += matches // current .keyword
                    if match.hasConjunction { newConjunctionMatches.append(match) }
                }
            } // ignore any unsuccessful matches (e.g. a new infix operator matcher for which there was no left operand, or an .operatorName that’s a conjunction keyword for which there is no match already in progress)
            // allow atomic operators to auto-reduce
            if match.isAFullMatch {
                fullMatches.append(match)
            }
        }
        // when auto-reducing blocks, we don’t want to overshoot, e.g. given `[[…]]`, both list literal patterns will match the first `]` but only the second should be allowed (requiring a full, not provisional, match would also exclude the first, but this is simpler)
        fullMatches.removeAll{ $0.startIndex(from: stopIndex) < startIndex }
        if !newConjunctionMatches.isEmpty {
            //print("newConjunctionMatches =", newConjunctionMatches)
            self.blockStack.beginConjunction(for: newConjunctionMatches, at: stopIndex)
        }
        // push the current token and its matches (if any) onto stack
        self.tokenStack.append((form, currentMatches, self.current.token.hasLeadingWhitespace))
        //print("SHIFT matched", form, "to", currentMatches, "with completions", fullMatches)
                
       // automatically reduce fully matched atomic operators and list/record/group/block literals (i.e. anything that starts and ends with a static token, not an expr, so is not subject to precedence or association rules)
        if let longestMatch = fullMatches.max(by: { $0.count < $1.count }) {
  //          print("\nAUTO-REDUCE:", longestMatch.definition.name.label)
 //           print(fullMatches)
            if self.tokenStack.reduce(match: longestMatch) {
                if case .operatorName(let d) = form, self.blockStack.blockMatches(for: d.name) != nil { // kludgy
                    self.blockStack.endConjunction(at: d.name)
                }
            } else {
                print("WARNING: failed to auto-reduce at head of stack:", longestMatch) // not sure if part of normal behavior, syntax error, and/or bug
            }
            if fullMatches.count > 1 { // TO DO: what if there are 2 completed matches of same length? (there shouldn't be if patterns are well designed and don't conflict, but it's not enforced)
                print("WARNING: discarding \(fullMatches.count-1) extra match[es] in shift():", fullMatches.sorted{ $0.count < $1.count })
            }
        }
//        print("…SHIFTED. new head:", self.tokenStack.last!)
 //       self.tokenStack.show()
    }
    
    
    // start and end block-type structures (lists, records, groups) // TO DO: what about keyword blocks, e.g. `do…done`? and what about operators containing conjunctions?
    
    var currentIndex: Int { return self.tokenStack.count - 1 }
    
    func startBlock(for form: Parser.BlockType, adding matchers: [PatternMatch]) {
        self.blockStack.beginBlock(for: form, at: self.currentIndex + 1) // track nested blocks on a secondary stack
        self.shift(adding: matchers) // shift the opening token onto stack, attaching one or more pattern matchers to it
    }
    
    func endBlock(for form: Parser.BlockType) throws {
        self.foundRightExpressionDelimiter() // ensure last expr in block is reduced to single .value // TO DO: check this as it's possible for last token in block to be a delimiter (e.g. comma and/or linebreak[s])
        let startIndex = try self.blockStack.endBlock(for: form, at: self.currentIndex).start // TO DO: what to do with error? (for now, we propagate it, but we should probably try to encapsulate as .error/SyntaxErrorDescription)
        self.shift(from: startIndex) // shift the closing token onto stack; shift() will then autoreduce the block literal
    }
    
    
    // main loop
    
    public func parseScript() {
        loop: while true { // loop exits below on .endOfCode
            let form = self.current.token.form
           // print("READ", form)
            switch form {
            case .endOfCode: break loop
            case .annotation(_): () // discard annotations for now
                
            case .startList:
                self.startBlock(for: .list, adding: orderedListLiteral.newMatches() + keyValueListLiteral.newMatches())
            case .startRecord:
                self.startBlock(for: .record, adding: recordLiteral.newMatches())
            case .startGroup:
                self.startBlock(for: .group, adding: groupLiteral.newMatches())
            case .endGroup:
                do {
                    try self.endBlock(for: .group)
                } catch {
                    print(error)
                }
            case .endList:
                do {
                    try self.endBlock(for: .list)
                } catch {
                    print(error)
                }
            case .endRecord:
                do {
                    try self.endBlock(for: .record)
                    self.reduceIfFullPunctuationCommand() // if top of stack is `NAME RECORD` then reduce it
                } catch {
                    print(error)
                }
                
            case .operatorName(let definitions):
                //print("READOP", definitions.name);  print(self.blockStack)
                // called by parser's main loop when an .operatorName(…) token is encountered
                let name = Symbol(self.current.token.content)
              //  print(".OP", definitions.name); self.blockStack.show()
                if let matches = self.blockStack.conjunctionMatches(for: name) { // conjunction keywords are greedily matched, e.g. given the expression `tell foo to bar`, the `to` keyword is immediately claimed by the in-progress `tell…to…` matcher so a new prefix `to…` matcher is not created
                    // note: this only executes if the keyword is an expected conjunction
                    self.reduceExpressionBeforeConjunction(name, matchedBy: matches) // this also shifts the conjunction onto stack
                } else {
                    self.shift(adding: definitions.newMatches())
                }
                //guard case .operatorName(let n) = form else { fatalError() }; print("\nMatched operator `\(n.name.label)` @ \(self.tokenStack.count-1):\n\(self.tokenStack.dump())\n")
                
            case .semicolon: // pipe operator
                self.reduceExpression() // reduce the EXPR before the semicolon
                self.shift(adding: pipeLiteral.newMatches())
                
            case .separator(let sep): // expression terminator
                self.foundRightExpressionDelimiter() // reduce the preceding EXPR to a single .value
                switch sep { // attach any caller-supplied debug hooks to the reduced value; TO DO: currently the above line may reduce to .value(SyntaxErrorDescription(…)), .error(…), or leave tokens unreduced; we should probably avoid attaching to anything except a successful .value(…) reduction (which will require reduceExpression to return a success/failure flag)
                case .comma:
                    self.attachPunctuationHooks(using: self.handleComma)
                case .period:
                    self.attachPunctuationHooks(using: self.handlePeriod)
                case .query:
                    self.attachPunctuationHooks(using: self.handleQuery)
                case .exclamation:
                    self.attachPunctuationHooks(using: self.handleExclamation)
                }
                self.shift() // shift the punctuation onto stack
            case .lineBreak: // expression terminator
               // print("LF REDUCE, stack size =", self.tokenStack.count)
                self.foundRightExpressionDelimiter() // reduce the preceding EXPR to a single .value
               // print("LF SHIFT")
                self.shift() // shift the linebreak onto stack
                
            default:
                self.shift()
            }
            self.advance()
        }
        //self.tokenStack.show()
        self.foundRightExpressionDelimiter()
        self.reductionForTopLevelExpressions() // top-level is basically a block without delimiters
    }
    
    
    public func replaceReader(_ tokenStream: DocumentReader) throws {
        guard case .endOfCode = self.current.token.form else {
            throw InternalError(description: "Can’t replace current reader as it has not been fully consumed.")
        }
        self.current = tokenStream
    }
    
    private func reductionForTopLevelExpressions() {
        //        print("\nReductions:")
        // finish reducing delimited expression sequence at top-level of script to a single ScriptAST value
        var result = [Value]()
        // TO DO: how to represent unreduced tokens as syntax errors? (e.g. what about runs caused by unbalanced braces? e.g. `[1,2,3 LF foo bar` will treat 1,2,3 as top-level exprs, which isn't intent; otoh, matcher will treat `foo bar` as list item, which probably isn't intended either; can we make reasonable guess as to where missing `]` should appear and re-parse based on that, flagging the proposed reduced list for user attention [i.e. approve or amend] before script can run)
        //print("RESULT:")
        var i = 0
        var wasValue = false
        self.tokenStack.skipLineBreaks(&i)
        while i < self.tokenStack.count {
            // TO DO: token stack captures only Forms, not Tokens, but it would be helpful to include source code ranges for use in error reporting (these would need recalculated after every reduction, but as long as reductions are performed via TokenStack APIs this shouldn't be difficult)
            let (form, _, _) = self.tokenStack[i] // use info from incomplete matches in syntax error messages
            switch form {
            case .value(_):
                if wasValue {
                    var tokens = [self.tokenStack[i - 1]]
                    while case .value(_) = self.tokenStack[i].form {
                        tokens.append(self.tokenStack[i])
                        self.tokenStack.remove(at: i)
                    }
                    // TO DO: SyntaxErrorDescription needs to capture tokens
                    self.tokenStack[i].form = .value(SyntaxErrorDescription("Found adjacent values (e.g. missing separator): \(tokens)"))
                }
                wasValue = true
            case .separator(let sep):
                if !wasValue {
                    print("Discarded duplicate punctuation: `\(sep)`")
                }
                wasValue = false
                self.tokenStack.skipLineBreaks(&i)
            case .lineBreak:
                wasValue = false
            default:
                result.append(SyntaxErrorDescription("Found unreduced token: .\(form)"))
                wasValue = false
            }
            i += 1
        }
    }
    
    //
    
    public func ast() -> AbstractSyntaxTree? {
        var result = [Value]()
        var i = 0
        self.tokenStack.skipLineBreaks(&i)
        while i < self.tokenStack.count {
            switch self.tokenStack[i].form {
            case .value(let v):
                result.append(v)
            case .endOfCode:
                break
            default:
                return nil
            }
            i += 1
            self.tokenStack.skipSeparator(&i)
            self.tokenStack.skipLineBreaks(&i)
        }
        guard case .script = self.blockStack.last?.form else {
            print("BUG: Unremoved block matchers:", self.blockStack)
            return nil
        }
        return AbstractSyntaxTree(result)
    }
    
    public func errors() -> [NativeError] { // TO DO: this returns top-level errors only; how best to get errors nested within block structures? (that's easiest if parser caches all shift+reduce errors as they’re thrown; this may also assist IDE in making [some] in-place corrections)
        var result = [NativeError]()
        for (form, _, _) in self.tokenStack {
            switch form {
            case .error(let e):
                result.append(e)
            case .value(let v):
                if let e = v as? NativeError { result.append(e) }
            default: ()
            }
        }
        return result
    }
    
    public func incompleteBlocks() -> [(startIndex: Int, startBlock: String, stopBlock: String)] {
        // TO DO: return a more limited enum that contains only info relevant to closing incomplete block structures? (i.e. .list/.record/.group/.block(startKeyword,endKeyword) and their start indexes) Q. is there any value in returning info on pending conjunction clauses here? or is that more appropriate in general command/operation auto-completion?
        assert(!self.blockStack.isEmpty, "Empty block stack.")
        return self.blockStack.filter {
            switch $0.form {
            case .conjunction(_), .script: return false
            default: return true
            }
        }.map {
            switch $0.form {
            case .list:     return ($0.start, "[", "]")
            case .record:   return ($0.start, "{", "}")
            case .group:    return ($0.start, "(", ")")
            case .block(let conjunctions):
                let match = conjunctions.values.first![0].match
                guard let (start, end) = match.blockKeywords() else { fatalError("TODO: unsupported block pattern") }
                return ($0.start, start.label, end.label)
            default: fatalError("This should never occur.")
            }
        }
    }
}
