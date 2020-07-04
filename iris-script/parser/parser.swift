//
//  parser.swift
//  iris-script
//

import Foundation


typealias ScriptAST = Block



public class Parser {
    
    typealias Form = Token.Form
    
    enum Reduction { // TO DO: get rid of this and just have reducefuncs throw
        case value(Value)
        case error(NativeError)
        
        init(_ value: Value) {
            self = .value(value)
        }
        
        init(_ error: Error) {
            self = .error(error as? NativeError ?? InternalError(error))
        }
    }
    
    typealias ReduceFunc = PatternDefinition.ReduceFunc // (token stack, fully matched pattern, start, end)
    
    // TO DO: also capture source code ranges? (how will these be described in per-line vs whole-script parsing? in per-line, each line needs a unique ID (incrementing UInt64) that is invalidated when that line is edited; that allows source code positions to be referenced with some additional indirection: the stack frame captures first and last line IDs plus character offset from start of line)
    typealias StackItem = (form: Form, matches: [PatternMatch], hasLeadingWhitespace: Bool) // in-progress/completed matches
    
    typealias TokenStack = [StackItem]
    
    
    let operatorRegistry: OperatorRegistry // TO DO: we need to lock OR after we've read any include/exclude annotations at top of script and before we start reading code tokens; any subsequent attempts to add/remove opdefs mid-parse should be an error (we can transform the annotations to .error tokens easily enough)
    
    private(set) var current: BlockReader // current token
    //private var annotations = [Token]() // TO DO: parser needs to bind extracted annotations to AST nodes automatically (this may be easier once TokenInfo includes line numbers)
    
    var stack = TokenStack() // TO DO: should be private or private(set) (currently internal as reduction methods are in separate extension)
    
    enum BlockMatch {
        case conjunction([Symbol: [PatternMatch]]) // may be conjunction (e.g. `then`) or terminator (e.g. `done`)
        case list
        case record
        case group
        case script
        
        func matches(_ form: Parser.BlockMatch) -> Bool {
            switch (self, form) {
            case (.conjunction(_), .conjunction(_)): return true // TO DO: how to compare?
            case (.list, .list):     return true
            case (.record, .record): return true
            case (.group, .group):   return true
            case (.script, .script): return true
            default:                 return false
            }
        }
    }
    
    // TO DO: blockMatchers stack currently assumes that all quoted text has already been reduced to string/annotation atoms so does not track the starts and ends of string or annotation literals; this is true for whole-program parsing (which is what we're limited to for now) but not in the case of malformed programs or per-line parsing; eventually it should be able to track those too (with the additional caveats that string literal delimiters lack unambiguous handedness in addition to all blocks being able to span multiple lines, so per-line parsing requires at least two alternate parses: one that assumes start of line is outside quoted text and one that assumes it is inside, and keep tallies of % of code that is valid reductions vs no. of parse errors produced, as well as any string/annotation delimiters encountered which indicate a transition from one state to another [with a third caveat that annotation literals must also support nesting])
    var blockMatchers: [BlockMatch] = [.script] // add/remove matchers for grouping punctuation and block operators as they’re encountered, along with conjunction matchers (the grouping matchers are added to mask the current conjunction matcher; e.g. given `tell (…to…) to …`, the `tell…to…` matcher should match the second `to`, not the first) // TO DO: should be private or private(set) (currently internal as reduction methods are in separate extension)
    
    
    init(tokenStream: BlockReader, operatorRegistry: OperatorRegistry) {
        self.current = tokenStream
        self.operatorRegistry = operatorRegistry
    }
    
    func peek(ignoringLineBreaks: Bool = false) -> BlockReader {
        var reader: BlockReader = self.current.next()
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
        if let fn = handler, case .value(let value) = self.stack.last?.form { // assuming preceding token[s] have already reduced to a value (expr), get that value and pass it to hook function to wrap in a run-time modifier (e.g. a `Breakpoint` value)
            self.stack[self.stack.count-1].form = .value(fn(value))
        } // else if preceding tokens haven't [yet] been reduced, leave the punctuation token for later processing; TO DO: how to avoid double-handling when re-scanning stack (punctuation tokens are left on stack for pattern matching); simplest is to define DebugValue protocol and require callbacks to return that; current stack value can then be tested to see if it's already wrapped
    }
    
    
    // start and end block-type structures (lists, records, groups) // TO DO: what about keyword blocks, e.g. `do…done`? and what about operators containing conjunctions?
    
    func startBlock(for form: Parser.BlockMatch, adding matchers: [PatternMatch]) {
        self.blockMatchers.start(form) // track nested blocks on a secondary stack
        self.shift(adding: matchers) // shift the opening token onto stack, attaching one or more pattern matchers to it
    }
    
    func endBlock(for form: Parser.BlockMatch) throws {
        try self.blockMatchers.stop(form) // TO DO: what to do with error? (for now, we propagate it, but we should probably try to encapsulate as .error/BadSyntaxValue)
        self.fullyReduceExpression() // ensure last expr in block is reduced to single .value // TO DO: check this as it's possible for last token in block to be a delimiter (e.g. comma and/or linebreak[s])
        self.shift() // shift the closing token onto stack; shift() will then autoreduce the block literal
    }
    
    //
    
    
    func parseScript() throws -> ScriptAST {
        loop: while true {
            //print("PARSE .\(self.current.token.form)")
            let form = self.current.token.form
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
                self.reduceIfFullPunctuationCommand() // if top of stack is full-punctuation command (`NAME RECORD`), reduce it
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
                if case .colon = self.current.next().token.form {
                    self.shiftLabel(named: name)
                } else {
                    self.shift() // shift the name onto stack
                }
                
            case .operatorName(let operatorDefinitions):
                self.matchOperator(operatorDefinitions)
                
            case .semicolon:
                self.fullyReduceExpression() // reduce the EXPR before the semicolon
                let (previousMatches, currentMatches, _) = self.match(pipeLiteral.newMatches()) // TO DO: currently ignores conjunctionMatches; why?
                if !previousMatches.isEmpty { stack.append(matches: previousMatches) }
                self.shift(adding: currentMatches)
                
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
        print("RESULT:")
        var i = 0
        var wasValue = false
        skipLineBreaks(self.stack, &i)
        while i < self.stack.count {
            let (reduction, matches, _) = self.stack[i]
            switch reduction {
            case .value(let value):
                print(value); let _ = matches
                //print(" `\(value)` \(matches.map{"\n  \($0)"}.joined(separator: ""))") // .filter{$0.isAFullMatch}
                //                print()
                if wasValue { print("Syntax error (adjacent values): `\(result.last!)` `\(value)`\n") }
                result.append(value)
                wasValue = true
            case .separator(let sep):
                if !wasValue {
                    print("Syntax error (stray punctuation): `\(sep)`\n")
                }
                wasValue = false
                skipLineBreaks(self.stack, &i)
            case .lineBreak:
                wasValue = false
            default:
                print("Unreduced .\(reduction)")
                wasValue = false
            }
            i += 1
        }
        print()
        // TO DO: need error tally; in theory script should be [partially] runnable even with [some?] syntax errors, but problematic sections need marked and script should run in debug mode only with extra guards around anything IO (what about unmatched operators? can we infer where an opname is accidentally used where quoted name is needed [i.e. user needs to resolve naming conflict] vs an opname that has incorrect operands [user needs to fix operands]; how do we represent such unresolved syntax errors as Values [again, allowing other code to execute at least in debug mode])
        guard case .script = self.blockMatchers.last else {
            print("Unremoved block matchers:", self.blockMatchers)
            return ScriptAST(result)
            //throw BadSyntax.missingExpression
        } // TO DO: add .error to result
        return ScriptAST(result)
    }
}
