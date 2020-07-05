//
//  parser.swift
//  iris-script
//

import Foundation


typealias ScriptAST = Block



public class Parser {
    
    typealias Form = Token.Form
    
    enum BlockInfo {
        case conjunction(Conjunctions) // may be conjunction (e.g. `then`) or terminator (e.g. `done`)
        case list
        case record
        case group
        case script
    }
    
    typealias BlockStack = [BlockInfo]

    typealias ReduceFunc = PatternDefinition.ReduceFunc // (token stack, fully matched pattern, start, end)
    
    // TO DO: also capture source code ranges? (how will these be described in per-line vs whole-script parsing? in per-line, each line needs a unique ID (incrementing UInt64) that is invalidated when that line is edited; that allows source code positions to be referenced with some additional indirection: the stack frame captures first and last line IDs plus character offset from start of line)
    
    typealias TokenInfo = (form: Form, matches: [PatternMatch], hasLeadingWhitespace: Bool) // in-progress/completed matches
    typealias TokenStack = [TokenInfo]
    
    // parser state
    
    let operatorRegistry: OperatorRegistry // TO DO: we need to lock OR after we've read any include/exclude annotations at top of script and before we start reading code tokens; any subsequent attempts to add/remove opdefs mid-parse should be an error (we can transform the annotations to .error tokens easily enough)
    
    private(set) var current: DocumentReader // current token
    //private var annotations = [Token]() // TO DO: parser needs to bind extracted annotations to AST nodes automatically (this may be easier once TokenInfo includes line numbers)
    
    var tokenStack = TokenStack() // TO DO: should be private or private(set) (currently internal as reduction methods are in separate extension)
    
    // TO DO: blockStack currently assumes that all quoted text has already been reduced to string/annotation atoms so does not track the starts and ends of string or annotation literals; this is true for whole-program parsing (which is what we're limited to for now) but not in the case of malformed programs or per-line parsing; eventually it should be able to track those too (with the additional caveats that string literal delimiters lack unambiguous handedness in addition to all blocks being able to span multiple lines, so per-line parsing requires at least two alternate parses: one that assumes start of line is outside quoted text and one that assumes it is inside, and keep tallies of % of code that is valid reductions vs no. of parse errors produced, as well as any string/annotation delimiters encountered which indicate a transition from one state to another [with a third caveat that annotation literals must also support nesting])
    var blockStack: BlockStack = [.script] // add/remove matchers for grouping punctuation and block operators as they’re encountered, along with conjunction matchers (the grouping matchers are added to mask the current conjunction matcher; e.g. given `tell (…to…) to …`, the `tell…to…` matcher should match the second `to`, not the first) // TO DO: should be private or private(set) (currently internal as reduction methods are in separate extension)
    
    
    init(tokenStream: DocumentReader, operatorRegistry: OperatorRegistry) {
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
    
    
    func shift(form: Token.Form? = nil, adding newMatches: [PatternMatch] = []) {
    //    print("SHIFTING. current head:", self.tokenStack.last?.form ?? .endOfScript)
     //   print("…", self.tokenStack.last?.matches ?? [])
        // normally the token being shifted is the current token in the parser’s token stream; however, in some special cases parser’s main loop performs an immediate reduction without first shifting, in which case the reduced token form is passed here
        // to initiate one or more new pattern matches on a given token, the parser’s main loop should instantiate those pattern matchers and pass them here
        let form = form ?? self.current.token.form
        var currentMatches = [PatternMatch]()   // new and in-progress matchers that match the current token; these will be pushed onto stack along with token
        var fullMatches = [PatternMatch]() // collects any current matches that complete on this token (these matches may or may not have longer matches available)
        // advance any in-progress matches and match to this token
        if let previousMatches = self.tokenStack.last?.matches {
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
        var newConjunctionMatches = Conjunctions() // newly started matchers that are awaiting a conjunction keyword in order to complete their current EXPR match
        let stopIndex = self.tokenStack.count // after shifting, this is the index at which conjunction matches matched the operator name
        for match in newMatches {
            assert(match.isAtBeginningOfMatch)
            if match.provisionallyMatches(form: form) { // attempt to match first pattern to the current token; this allows new matchers to match atom/prefix operators (the first pattern is a .keyword and the current token is an .operatorName of the same name)
                currentMatches.append(match)
                // if the pattern contains one or more conjunctions (e.g. `then` and `else` keywords in `if…then…else…`) then push those onto blockStack so we can correctly balance nesting
                if match.hasConjunction { newConjunctionMatches.add(match, endingAt: stopIndex) }
            } else if let previous = self.tokenStack.last, match.provisionallyMatches(form: previous.form) { // attempt to match the previous token (expr), followed by current token (opName); this allows new matchers to match infix/postfix operators (match starts on the token before .operatorName)
                let matches = match.next().filter{ $0.fullyMatches(form: form) } // re-match the current token (operator); we have to do this to exclude conjunction keywords
                if !matches.isEmpty {
                    self.tokenStack.append(match: match) // infix/postfix operator starts on preceding (EXPR) token…
                    currentMatches += matches // …matching keyword to current .operatorName token
                    if match.hasConjunction { newConjunctionMatches.add(match, endingAt: stopIndex) }
                }
            } // ignore any unsuccessful matches (e.g. a new infix operator matcher for which there was no left operand, or an .operatorName that’s a conjunction keyword for which there is no match already in progress)
        }
        if !newConjunctionMatches.isEmpty { self.blockStack.begin(.conjunction(newConjunctionMatches)) }
        // push the current token and its matches (if any) onto stack
        self.tokenStack.append((form, currentMatches, self.current.token.hasLeadingWhitespace))
        // print("SHIFT matched", form, "to", currentMatches, "with completions", fullMatches)
        // automatically reduce fully matched atomic operators and list/record/group/block literals (i.e. anything that starts and ends with a static token, not an expr, so is not subject to precedence or association rules)
        if let longestMatch = fullMatches.max(by: { $0.count < $1.count }) {
    //        print("\nAUTO-REDUCE", longestMatch.definition.name.label)
            self.tokenStack.reduce(fullMatch: longestMatch)
            if fullMatches.count > 1 { // TO DO: what if there are 2 completed matches of same length?
                print("WARNING: discarding extra matches in", fullMatches.sorted{ $0.count < $1.count })
            }
        }
   //     print("…SHIFTED. new head:", self.tokenStack.last!)
    }
    
    
    // start and end block-type structures (lists, records, groups) // TO DO: what about keyword blocks, e.g. `do…done`? and what about operators containing conjunctions?
    
    func startBlock(for form: Parser.BlockInfo, adding matchers: [PatternMatch]) {
        self.blockStack.begin(form) // track nested blocks on a secondary stack
        self.shift(adding: matchers) // shift the opening token onto stack, attaching one or more pattern matchers to it
    }
    
    func endBlock(for form: Parser.BlockInfo) throws {
        try self.blockStack.end(block: form) // TO DO: what to do with error? (for now, we propagate it, but we should probably try to encapsulate as .error/BadSyntaxValue)
        self.fullyReduceExpression() // ensure last expr in block is reduced to single .value // TO DO: check this as it's possible for last token in block to be a delimiter (e.g. comma and/or linebreak[s])
        self.shift() // shift the closing token onto stack; shift() will then autoreduce the block literal
    }
    
    
    // main loop
    
    func parseScript() throws -> ScriptAST {
        loop: while true {
            let form = self.current.token.form
            //print("PARSE .\(form)")
            switch form {
            case .endOfScript: break loop // the only time we break out of this loop
            case .annotation(_): () // discard annotations for now
            case .startList:
                self.startBlock(for: .list, adding: orderedListLiteral.newMatches() + keyValueListLiteral.newMatches())
            case .startRecord:
                self.startBlock(for: .record, adding: recordLiteral.newMatches())
            case .startGroup:
                self.startBlock(for: .group, adding: groupLiteral.newMatches() + parenthesizedBlockLiteral.newMatches())
            case .endGroup:
                try self.endBlock(for: .group)
            case .endList:
                try self.endBlock(for: .list)
            case .endRecord:
                try self.endBlock(for: .record)
                self.reduceIfFullPunctuationCommand() // if top of stack is `NAME RECORD` then reduce it
            case .separator(let sep):
                self.fullyReduceExpression() // reduce the preceding EXPR to a single .value
                switch sep { // attach any caller-supplied debug hooks to the reduced value; TO DO: currently the above line may reduce to .value(BadSyntaxValue(…)), .error(…), or leave tokens unreduced; we should probably avoid attaching to anything except a successful .value(…) reduction (which will require fullyReduceExpression to return a success/failure flag)
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
                
            case .lineBreak:
                self.fullyReduceExpression() // reduce the preceding EXPR to a single .value
                self.shift() // shift the linebreak onto stack
                
            case .unquotedName(let name), .quotedName(let name): // command name or record label
                // `NAME COLON` is ALWAYS a label (i.e. is part of core syntax rules), so we can reduce it here to intermediate .label(NAME), which simplifies LP command parsing
                if case .colon = self.current.next().token.form { // this performs +1 lookahead
                    self.shiftLabel(named: name) // this shifts the reduced `.label(NAME)` onto stack
                } else {
                    self.shift() // shift the name onto stack
                }
                
            case .operatorName(let definitions):
                // called by parser's main loop when an .operatorName(…) token is encountered
                let name = Symbol(self.current.token.content)
                if case .colon = self.current.next().token.form { // `NAME COLON` is reduced to .label(NAME) same as above
                    self.shiftLabel(named: name)
                } else if let matches = self.blockStack.conjunctionMatches(for: name) { // conjunction keywords are greedily matched, e.g. given the expression `tell foo to bar`, the `to` keyword is immediately claimed by the in-progress `tell…to…` matcher so a new prefix `to…` matcher is not created
                    // note: this only executes if the keyword is an expected conjunction
                    self.reduceExpressionBeforeConjunction(name, matchedBy: matches) // this also shifts the conjunction onto stack
                } else {
                    self.shift(adding: definitions.newMatches())
                }
                //guard case .operatorName(let n) = form else { fatalError() }; print("\nMatched operator `\(n.name.label)` @ \(self.tokenStack.count-1):\n\(self.tokenStack.dump())\n")
                
            case .semicolon:
                self.fullyReduceExpression() // reduce the EXPR before the semicolon
                self.shift(adding: pipeLiteral.newMatches())
                
            default:
                self.shift()
            }
            self.advance()
        }
        return self.reductionForTopLevelExpressions()
    }
    
    
    
    func reductionForTopLevelExpressions() -> ScriptAST {
        //        print("\nReductions:")
        // finish reducing delimited expression sequence at top-level of script to a single ScriptAST value
        var result = [Value]()
        // TO DO: how to represent unreduced tokens as syntax errors? (e.g. what about runs caused by unbalanced braces? e.g. `[1,2,3 LF foo bar` will treat 1,2,3 as top-level exprs, which isn't intent; otoh, matcher will treat `foo bar` as list item, which probably isn't intended either; can we make reasonable guess as to where missing `]` should appear and re-parse based on that, flagging the proposed reduced list for user attention [i.e. approve or amend] before script can run)
        //print("RESULT:")
        var i = 0
        var wasValue = false
        skipLineBreaks(self.tokenStack, &i)
        while i < self.tokenStack.count {
            // TO DO: token stack captures only Forms, not Tokens, but it would be helpful to include source code ranges for use in error reporting (these would need recalculated after every reduction, but as long as reductions are performed via TokenStack APIs this shouldn't be difficult)
            let (form, _, _) = self.tokenStack[i] // use info from incomplete matches in syntax error messages
            switch form {
            case .value(let value):
                if wasValue {
                    result.append(BadSyntaxValue("Found adjacent values (e.g. missing separator): `\(result.last!)` `\(value)`"))
                }
                result.append(value)
                wasValue = true
            case .separator(let sep):
                if !wasValue {
                    result.append(BadSyntaxValue("Found adjacent punctuation (e.g. duplicate or misplaced): `\(sep)`"))
                }
                wasValue = false
                skipLineBreaks(self.tokenStack, &i)
            case .lineBreak:
                wasValue = false
            default:
                result.append(BadSyntaxValue("Found unreduced token: .\(form)"))
                wasValue = false
            }
            i += 1
        }
        // TO DO: need error tally; in theory script should be [partially] runnable even with [some?] syntax errors, but problematic sections need marked and script should run in debug mode only with extra guards around anything IO (what about unmatched operators? can we infer where an opname is accidentally used where quoted name is needed [i.e. user needs to resolve naming conflict] vs an opname that has incorrect operands [user needs to fix operands]; how do we represent such unresolved syntax errors as Values [again, allowing other code to execute at least in debug mode])
        guard case .script = self.blockStack.last else {
            print("Unremoved block matchers:", self.blockStack)
            return ScriptAST(result)
            //throw BadSyntax.missingExpression
        } // TO DO: add .error to result
        return ScriptAST(result)
    }
}
