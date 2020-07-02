//
//  parser.swift
//  iris-script
//

import Foundation


// TO DO: upon reducing .label, can we set up pattern matcher for `LABEL EXPR` where it matches as a prefix operator (of commandPrecedence and .invalid associativity when reading LP commands, or Precedence.min when reading record fields)?



// simplest is to invoke list reduce func on `]` token, and let reduce func pop stack until it finds corresponding `[` (this isn't table-driven pattern-matching, which is what we ultimately want as tables provide introspectable information that can drive auto-suggest/-correct/-complete, and auto-generate user documentation for operator syntax)

// for now, syntax errors are detected late (but this isn't necessarily a problem as we want to parse the entire script, reducing as much as possible, then prompt user to resolve any remaining issues)


// note: if conjunction appears in block, keep parsing block but make note of its position in the event unbalanced-block syntax errors are found

// TO DO: lexer seems to pick up an extra linebreak at end of single-line script


// TO DO: initially implement as full-file parser, then convert to per-line (for incremental parsing) // Q. how to represent partial values? (in per-line parsing, lists, records, blocks can extend over multiple lines)


// delimiter punctuation always triggers reduction of preceding tokens
// TO DO: parser should reject punctuation that appears at (e.g.) start of line
// TO DO: when reduction fails due to syntax error, append Placeholder to stack containing remaining pattern[s]; editor can use this to assist user in correcting/completing code
// TO DO: check that numeric decimal/thousands separators (e.g. `1,000,000.23`) are reduced by numeric reader; we don't want those confused for expr separators; Q. can numeric reader reliably reduce `+`/`-` prefixes on numbers? (that's challenging as it requires numeric reader to know about balanced whitespace and left delimiters)


// OperatorDefinition should include pattern; this is probably easiest done as array of enum

// partial matches are struct of OperatorDefinition + index into pattern array

// when a Value is pushed onto stack, pass it to each partial match which checks it against pattern and returns either new partial match (the match index is advanced and returned in a new partial match struct), completed match (don't reduce immediately as there may be a longer match to be made [i.e. SR conflict is resolved by preferring longest patch]), or no match (in which case that matcher isn't carried forward); that implies matches are part of .value case

// TO DO: reductions need to annotate AST so that PP can reinsert original punctuation when rendering tidied code




// note: resolving operator precedences, e.g. `1 + 2 * 3`, is a form of SR-conflict resolution; presumably we need to look at `2` to see if it is matched by >1 operator (then we need to check those operators are completely matched)

// having encountered an operator-defined keyword, we get all operator definitions that use that keyword
// TO DO: if the opdef has a leading expr before that keyword, check stack's head is an expr; append a new PatternMatcher to head's matches then add the Reduction.token(.operatorName(…) with nextMatch)

// TO DO: if stack's head is not an expr, reduceExpression?

// TO DO: reconcile these patterns with any partially matched patterns at top(?) of stack; note that these patterns could also spawn new partial matches (e.g. `to…` vs `tell…to…`, `repeat…while…` vs `while…repeat…`)


// first challenge: operator keyword can change how preceding Reduction[s] should be reduced, e.g. given, `a - 1` or `a -1`, infix `-` wants to reduce `a` to arg-less command, whereas prefix `-` wants to consume `1` then push `-1` onto stack to be finally reduced as `a{-1}`; we can probably tighten this up with balanced-whitespace/no-trailing-whitespace rules (it might even be wise to enforce balanced whitespace for infix operators at parser level, though we can't enforce no-trailing-whitespace as that won't work for word-based operators such as `NOT`)

// new patterns need backwards-matched as needed (e.g. infix, postfix ops need to match current topmost stack item as LH operand, caveat if that is preceded by another operator requiring precedence/associativity resolution); note that while these patterns are completed upon reducing RH expression, we can't immediately reduce completed patterns as there may be another operator name after the expr; need to wait for delimiter (punctuation or linebreak) to trigger those reductions



/*
 case .colon: // push onto stack; what about pattern matching? what should `value:value` transform to?
 //self.reduceExpression() // TO DO: is this appropriate? probably not: need to take care not to over-reduce LH (e.g. `foo bar:baz` should not reduce to `foo{bar}:baz`) i.e. is there any situation where LH is *not* a single token ([un]quotedName or symbol/string/number literal) - obvious problem here is that it won't handle string literals that haven't already been reduced to .value (which is something we defer when reading per-line)
 let m: [PatternMatcher]
 if case .value(_) = self.stack.last?.form {
 m = []//patternMatchers(for: colonPair, remaining: [colonPair.pattern[2]])]
 } else {
 m = []
 }
 
 // TO DO: is it worth passing new matchers to shift()? infix operator already adds matcher directly to stack's head (prior to shifting operator onto it); for prefix operator, might be as well to shift then add matcher to head; there is also question of where to instantiate pattern matchers for lists, records
 
 // TO DO: can LP commands be matched with a matcher? needs to know if command is nested (otherwise the inner command will 'steal' the outer command's remaining keyword arguments, which is not what we want; i.e. command matching is context-sensitive)
 
 self.shift(adding: m) // this needs to add colon-pair pattern if top of stack (LH) is EXPR (or anything other than `[`?) (unlike operators, which are library-defined, colon is hardcoded punctuation with special representation); should `[:]` be matched as pattern, or just hardcode into `case .endList`? one reason to prefer patterns is they generate better syntax error messages
 
 print("added", m, self.stack.count)
 
 // in keeping with `name:value` binding syntax, colon is used to bind handler interface to handler action:
 
 // (foo {x as bar} returning baz: do … done) as handler // creates a NativeHandler instance but doesn't bind it
 
 // (foo: do … done) as handler  // note the cast is necessary to prevent binding block's result to name (without the cast, the preceding example would fail)
 
 // (do … done) as handler  // and here is simplest form: an unnamed handler that takes no input and returns unspecified output
 
 // note: colon needs to bind tighter than `as` and `returning`, but looser than `to`:
 
 // To foo x as bar returning baz: do … done.
 
 // one problem with colon for bindings: `a of b: c` is visually confusing and should probably be disallowed, or at least discouraged (use `set a of b to c`; Q. what about `b.a: c`?); also consider colon bindings to be essentially static, i.e. LH operand is fixed at parse time
 
 // still not sure if colon binding in blocks should map to `set`; we could argue that since all behaviors are library-supplied, binding is one of those behaviors
 
 
 // when matching operator keywords such as `to`, `do`, `done`, should pattern specify leftDelimited/rightDelimited/leftDelimited? i.e. we want to 'encourage' `to` to appear at start of line, to minimize it being treated as an operand/argument in more ambiguous contexts (e.g. in `tell foo to bar`, we want to avoid parsing as `tell {foo {to bar}}`)
 */

// TO DO: debugger may want to insert hooks (e.g. step) at line-endings too; as before, to preserve LF-delimited list/record items, this needs to operate on preceding value without changing no. of values on stack; it should probably onalso ignore if LF was also preceded by punctuation

// this may or may not fully reduce preceding tokens (e.g. if list wraps multiple lines); Q. any situation where the last token isn't reduced but can legitimately be reduced later? (versus e.g. a dangling operator, which should probably be treated as syntax error even if remaining operand appears at start of next line); yes, e.g. if last token is `[`; if we use patterns to match, patterns should specify where LFs are allowed - upon reaching lineBreak, any patterns that don't permit LF at that point are discontinued (i.e. they remain partially matched up to last token, but don't carry forward to next line); the alternative is we do allow patterns to carry forward in hopes of completing parse, then have PP render as a single line of code (but that isn't necessarily what user intended, e.g. `foo + LF to bar: baz`)



typealias ScriptAST = Block




extension Array where Element == Parser.BlockMatch {
    
    mutating func start(_ form: Parser.BlockMatch) {
        self.append(form)
    }
    
    mutating func stop(_ form: Parser.BlockMatch) throws {
        if form.matches(self.last!) {
            self.removeLast()
        } else {
            // TO DO: what do do with mismatched last item? leave/discard/speculatively rebalance?
            switch self.last! {
            case .list:           throw BadSyntax.unterminatedList
            case .record:         throw BadSyntax.unterminatedRecord
            case .group:          throw BadSyntax.unterminatedGroup
            case .script:         throw BadSyntax.missingExpression // TO DO: what error?
            case .conjunction(_): throw BadSyntax.missingExpression // TO DO: what error?
            }
        }
    }
}

extension Array where Element == Parser.StackItem {
    // we could do with method that tests whether an item has precedence contention (e.g. `2` in `1 + 2 * 3`); the problem is that the operand must be fully reduced in order to be fully matched (part of the problem is that infix/postfix ops are only attached to end token; as always, commands are trouble due to interactions between arguments and operators)
}


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
    
    typealias ReduceFunc = (Stack, OperatorDefinition, Int, Int) throws -> Value // (token stack, operator definition, start, end)
    
    
    // TO DO: also capture source code ranges? (how will these be described in per-line vs whole-script parsing? in per-line, each line needs a unique ID (incrementing UInt64) that is invalidated when that line is edited; that allows source code positions to be referenced with some additional indirection: the stack frame captures first and last line IDs plus character offset from start of line)
    typealias StackItem = (form: Form, matches: [PatternMatcher], hasLeadingWhitespace: Bool) // in-progress/completed matches
    
    typealias Stack = [StackItem]
    
    typealias PunctuationHandler = (Value) -> Value // optionally insert debugger commands when parsing .comma, .period, .query, and/or .exclamation delimiters
    
    
    let operatorRegistry: OperatorRegistry // TO DO: we need to lock OR after we've read any include/exclude annotations at top of script and before we start reading code tokens; any subsequent attempts to add/remove opdefs mid-parse should be an error (we can transform the annotations to .error tokens easily enough)
    
    private(set) var current: BlockReader // current token
    //private var annotations = [Token]() // TO DO: parser needs to bind extracted annotations to AST nodes automatically (this may be easier once TokenInfo includes line numbers)
    
    var stack = Stack() // TO DO: should be private or private(set) (currently internal as reduction methods are in separate extension)
    
    enum BlockMatch {
        case conjunction([Symbol: [PatternMatcher]]) // may be conjunction (e.g. `then`) or terminator (e.g. `done`)
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
    
    // TO DO: this assumes all quoted text is already reduced to string/annotation literals
    var blockMatchers: [BlockMatch] = [.script] // add/remove matchers for grouping punctuation and block operators as they’re encountered, along with conjunction matchers (the grouping matchers are added to mask the current conjunction matcher; e.g. given `tell (…to…) to …`, the `tell…to…` matcher should match the second `to`, not the first) // TO DO: should be private or private(set) (currently internal as reduction methods are in separate extension)
    
    
    // callback hooks for inserting debugger commands into AST at parse-time
    var handlePeriod: PunctuationHandler?
    var handleComma: PunctuationHandler?
    var handleQuery: PunctuationHandler?
    var handleExclamation: PunctuationHandler?
    
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
    
    //
    
    
    private func handlePunctuation(using handler: PunctuationHandler?) {
        // TO DO: given `A,B,C!`, should `!` modifier apply to `C` only, or to `(A,B,C)!`, or to `A!B!C!`?
        // don't insert debugger command if preceding tokens can't be reduced to Value (i.e. punctuation modifies run-time behavior of the preceding value only, e.g. `Delete my_files!`)
        // TO DO: should lists and records only allow comma and/or LF as expr separators? (i.e. `EXPR?` and `EXPR!` could still be used if required, but they'd need explicitly parenthesized)
        // stack will be empty if punctuation appears at start of code; parser should probably detect and correct/reject obviously misplaced punctuation before it gets to here, but ignore it if it does
        if let fn = handler, case .value(let value) = self.stack.last?.form { // assuming preceding token[s] have already reduced to a value (expr), get that value and pass it to hook function to wrap in a run-time modifier (e.g. a `Breakpoint` value)
            self.stack[self.stack.count-1].form = .value(fn(value))
        } // else if preceding tokens haven't [yet] been reduced, leave the punctuation token for later processing; TO DO: how to avoid double-handling when re-scanning stack (punctuation tokens are left on stack for pattern matching); simplest is to define DebugValue protocol and require callbacks to return that; current stack value can then be tested to see if it's already wrapped
    }
    
    //
    
    // match prefix/infix operator definitions to current/previous+current tokens
    //
    // this method back-matches by up to 1 token in the event the operator pattern starts with an EXPR followed by the operator itself (note: this does not match conjunctions as those should be at least two tokens ahead of the primary operator name)
    
    private func match(patterns: [PatternMatcher]) -> (previousTokenMatches: [PatternMatcher], currentTokenMatches: [PatternMatcher], conjunctionTokenMatches: [PatternMatcher]) {
        // TO DO: precedence applies to leading/trailing operands; what about middle operands (e.g. the test expr between `if` and `then`) - if an operator with lower precedence appears there, how do we avoid breaking out?
        let form = self.current.token.form
        var previousMatches = [PatternMatcher]()
        var currentMatches = [PatternMatcher]()
        var conjunctionMatchers = [PatternMatcher]()
        for matcher in patterns { // TO DO: this isn't giving us right ID
            
            
            // note: first pattern in matcher is reified, so it's tempting to test if it's a keyword (atom/prefix) and toggle on that; however, that won't work if it's .test (e.g. when matching argument label) so it's safest just to apply the first matcher twice: once to current token and, if that fails, to previous token (note: if keyword is a conjunction, not primary, it's never going to match here; is it worth spawning matchers for conjunctions at all? if not, how do we tighten that up?)
            if matcher.match(form, allowingPartialMatch: true) { // apply to current token; this matches prefix operators
                currentMatches.append(matcher)
                if matcher.hasConjunction { conjunctionMatchers.append(matcher) }
            } else if let previous = self.stack.last, matcher.match(previous.form, allowingPartialMatch: true) { // apply to previous token (expr) and current token (opName); this matches infix operators
                // confirm opname was 2nd pattern (i.e. primary keyword, not a conjunction); kludgy
                let matches = matcher.next().filter{ $0.match(form) } // caution: since opdefs currently include conjunctions, we need to rematch operatorName here; this'll match infix/postfix ops and discard conjunctions // TO DO: apply this match even when previous match fails and, if it succeeds, put matcher in current token's stack frame, marking it as requiring backmatch?
                if !matches.isEmpty {
                    //currentMatches += matches
                    previousMatches.append(matcher) // for now, put left expr matcher in previous frame; it'll advance back onto .operatorName when next shift(); caution: this works only inasmuch as previous token can be matched as EXPR, otherwise matcher is not attached and is lost from stack (we should be okay as we're only doing partial match of leading expr)
                    if matcher.hasConjunction { conjunctionMatchers.append(matcher) }
                }
            }
        }
        //     print("PREV", previousMatches, "CURR", currentMatches)
        return (previousMatches, currentMatches, conjunctionMatchers)
    }
    
    //
    
    // one might argue for Pratt parsing EXPR
    
    // shift moves the current token from lexer to parser's stack and applies any in-progress matchers to it
    //
    // note: if shift completes a list/record/group literal, it is immediately reduced to a value (see OperatorDefinition.autoReduce; i.e. any pattern which has explicit start and end delimiters can be safely auto-reduced as precedence and associativity rules only apply to operators that start and/or end with an EXPR)
    // anything else is left on the stack until an explicit reduceExpression() phase is triggered
    func shift(form: Token.Form? = nil, adding newMatchers: [PatternMatcher] = []) { // newMatchers have (presumably) already matched this token, but we match them again to be sure
        let form = form ?? self.current.token.form
        //      print("\nCURRENT:", form)
        let matchers: [PatternMatcher]
        if let previousMatches = self.stack.last?.matches { // advance any in-progress matches
            //print("PREV:", previousMatches, "\nNEW:", newMatchers)
            matchers = previousMatches.flatMap{$0.next()} + newMatchers
        } else {
            //print("NEW:", newMatchers)
            matchers = newMatchers
        }
        // apply in-progress and newly-started matchers to current token, noting any that end on this token
        var continuingMatches = [PatternMatcher](), fullMatches = [PatternMatcher]()
        for matcher in matchers {
            if matcher.match(form, allowingPartialMatch: true) { // match succeeded for this token
                continuingMatches.append(matcher)
                if matcher.isAFullMatch { fullMatches.append(matcher) }
            }
        }
        //print("SHIFT matched", form, "to", continuingMatches, "with completions", completedMatches)
        self.stack.append((form, continuingMatches, self.current.token.hasLeadingWhitespace))
        // TO DO: if >1 complete match, we can only reduce one of them (i.e. need to resolve any reduce conflicts *before* reducing, otherwise 2nd will get wrong stack items to operate on; alternative would be to fork multiple parsers and have each try a different strategy, which might be helpful during editing)
        // TO DO: what if there are still in-progress matches running? (can't start reducing ops till those are done as we want longest match and precedence needs resolved anyway, but ops shouldn't auto-reduce anyway [at least not unless they start AND end with keyword])
        //       if !completedMatches.isEmpty { print("SHIFT fully matched", completedMatches) }
        
        //   print("SHIFT \(self.stack.count - 1): .\(form)")
        
        // automatically reduce atomic operators and list/record/group/block literals (i.e. anything that starts and ends with a static token, not an expr, so is not subject to precedence or association rules)
        // TO DO: not sure if reasoning is correct here; if we limit auto-reduction to builtins (which we control) then it's safe to say there will be max 1 match, but do…done blocks should also auto-reduce and those are library-defined; leave it for now as it solves the immediate need (reducing literal values as soon as they're complete so operator patterns can match them as operands)
        if let longestMatch = fullMatches.max(by: { $0.count < $1.count }), longestMatch.definition.autoReduce {
            //           print("\nAUTO-REDUCE", longestMatch.definition.name.label)
            self.stack.reduce(fullMatch: longestMatch)
            if fullMatches.count > 1 {
                // TO DO: what if there are 2 completed matches of same length?
                print("discarding extra matches in", fullMatches.sorted{ $0.count < $1.count })
            }
        }
        //      print("SHIFTED STACK:", self.stack.dump()); print()
    }
    
    // start and end block-type structures (lists, records, groups) // TO DO: what about keyword blocks, e.g. `do…done`? and what about operators containing conjunctions?
    
    func startBlock(_ form: Parser.BlockMatch, matching matchers: [PatternMatcher]) {
        self.blockMatchers.start(form) // track nested blocks on a secondary stack
        self.shift(adding: matchers) // shift the opening token onto stack, attaching one or more pattern matchers to it
    }
    
    func endBlock(_ form: Parser.BlockMatch) throws {
        try self.blockMatchers.stop(form) // TO DO: what to do with error? (for now, we propagate it, but we should probably try to encapsulate as .error/BadSyntaxValue)
        self.fullyReduceExpression() // ensure last expr in block is reduced to single .value // TO DO: check this as it's possible for last token in block to be a delimiter (e.g. comma and/or linebreak[s])
        self.shift() // shift the closing token onto stack; shift() will then autoreduce the block literal
    }
    
    //
    
    func conjunctionMatchers(for name: Symbol) -> [PatternMatcher]? {
        // print("check for", name, "in", self.blockMatchers.last!)
        if case .conjunction(let conjunctions) = self.blockMatchers.last! {
            return conjunctions[name]
        } else {
            return nil
        }
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
                self.blockMatchers.start(.list)
                self.shift(adding: orderedListLiteral.patternMatchers() + keyValueListLiteral.patternMatchers())
            case .startRecord:
                self.blockMatchers.start(.record)
                self.shift(adding: recordLiteral.patternMatchers())
            case .startGroup:
                self.blockMatchers.start(.group)
                self.shift(adding: groupLiteral.patternMatchers() + parenthesizedBlockLiteral.patternMatchers())
            case .endGroup:
                try self.endBlock(.group)
            case .endList:
                try self.endBlock(.list)
            case .endRecord:
                try self.endBlock(.record)
                self.reduceIfFullPunctuationCommand() // if top of stack is full-punctuation command (`NAME RECORD`), reduce it
            case .separator(let sep):
                // TO DO: this should only reduce expr up to the preceeding expr delimiter, but currently goes all the way back to start of stack; how do we determine the correct boundary? (ditto for other fullyReduceExpression calls too); is it safe to set a Parser-wide var with last boundary token's index? answer: no (reductions will invalidate it)
                self.fullyReduceExpression() // [attempt to] reduce the preceding value to single .value
                switch sep { // attach any caller-supplied debug hooks
                case .comma:
                    self.handlePunctuation(using: self.handleComma)
                case .period:
                    self.handlePunctuation(using: self.handlePeriod)
                case .query:
                    self.handlePunctuation(using: self.handleQuery)
                case .exclamation:
                    self.handlePunctuation(using: self.handleExclamation)
                }
                self.shift()
                
            case .lineBreak:
                self.fullyReduceExpression() // confirm this
                self.shift()
                
            case .unquotedName(let name), .quotedName(let name): // command name or record label
                // if we assume `NAME COLON` is ALWAYS a label, we can reduce it here to intermediate .label(NAME), which hopefully simplifies LP command parsing
                if case .colon = self.current.next().token.form {
                    self.reduceLabel(name)
                } else {
                    self.shift()
                }
                
            case .operatorName(let operatorDefinitions):
                if case .colon = self.current.next().token.form {
                    // assuming `NAME COLON` is ALWAYS a label (i.e. is part of core syntax rules), we can reduce it here to intermediate .label(NAME), which hopefully simplifies LP command parsing
                    self.reduceLabel(Symbol(self.current.token.content))
                } else if let matchers = self.conjunctionMatchers(for: operatorDefinitions.name) {
                        // first check if keyword is an expected conjunction (e.g. `then` in `if…then…`); if so, fully reduce the preceding EXPR (for this, we need to backsearch the shift stack for that matcher by matchID; once we find it, we know the range of tokens to reduce; e.g. given `if…then…` we want to reduce everything between the `if` and the `then` keywords to a single .value, but we don't want to risk reducing the `if EXPR` as well in the event that `if` is overloaded as a prefix operator as well; i.e. we can't make assumptions about library-defined operators)
                        // TO DO: given an overloaded conjunction, e.g. `to` is both a conjunction after `tell` and a prefix operator in its own right, how to ensure it is always matched as conjunction and other interpretations are ignored? (currently, after matching `to` token as a conjunction, we proceed to standard operator matching which will want to start matching it as a `to` operator; there are also questions on how to deal with bad expr seqs such as `EXPR prefixOp EXPR`, and longest-match vs best-match rules)
                        // one reason for keeping "unmatchable" matchers (i.e. where keyword is conjunction rather than prefix/infix operator) is that those matchers may be used to generate error messages when a stray conjunction is found, e.g. "found stray `then` keyword outside of `if…then…` expression"
                        
                        self.reduceExpressionBeforeConjunction(matchedBy: matchers)
                }
                
                //
                
                //   print("FOUND OP", definitions.name)
                // previous matchers = infix operators; these will be re-matched to current operator token upon shift()
                // current matchers = prefix operators
                // conjunction matchers = matches already in progress (strictly speaking we only need their matchIDs)
                let (previousMatches, currentMatches, conjunctionMatches) = self.match(patterns: operatorDefinitions.patternMatchers()) // TO DO: `do done` should probably be rejected as syntax error, but this would match it (twice; once starting at `do`, then backmatching from `done` [nope, shouldn't: as long as pattern requires at least one delimiter between the two keywords, the `done` won't backmatch; will need to check pattern for this])
                
                //  print("CM",currentMatches)
                
                if !previousMatches.isEmpty { stack[stack.count-1].matches += previousMatches }
                if !conjunctionMatches.isEmpty {
                    
                    // TO DO: these are new matchers; we need them advanced to match conjunction keyword (can't do that: they may have >1 pattern, e.g. `do…done` yields 2 matchers, one that takes delimiter and `done` and the other takes delimiter followed by zero or more expr+delim then `done`)
                    var conjunctions = [Symbol: [PatternMatcher]]()
                    for m in conjunctionMatches {
                        for n in m.conjunctions {
                            if conjunctions[n] == nil {
                                conjunctions[n] = [m]
                            } else {
                                conjunctions[n]!.append(m)
                            }
                        }
                    }
                    //print("Found \(operatorDefinitions.name); will look for conjunction:", conjunctions.map{$0.key})
                    self.blockMatchers.start(.conjunction(conjunctions))
                } // TO DO: confirm this is appropriate
                //  print("ADDING MATCHERS:", currentMatches)
                self.shift(adding: currentMatches)
                
            case .semicolon:
                self.fullyReduceExpression() // TO DO: confirm this is correct (i.e. punctuation should always have lowest precedence so that operators on either side always bind first)
                let (previousMatches, currentMatches, _) = self.match(patterns: pipeLiteral.patternMatchers()) // TO DO: currently ignores conjunctionMatchers
                //print(definitions.name.label, backMatches, newMatches)
                if !previousMatches.isEmpty { stack[stack.count-1].matches += previousMatches }
                self.shift(adding: currentMatches)
                
            default:
                self.shift()
            }
            self.advance()
        }
        
        
        
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
            return ScriptAST([]) //result)
            //throw BadSyntax.missingExpression
        } // TO DO: add .error to result
        return ScriptAST([]) //result)
    }
}
