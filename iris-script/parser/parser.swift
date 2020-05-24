//
//  parser.swift
//  iris-script
//

import Foundation


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
    if case .value(_) = self.stack.last?.reduction {
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



class Parser {

    typealias Form = Token.Form
    
    enum Reduction {
        case value(Value)
        case error(NativeError)
        
        init(_ value: Value) {
            self = .value(value)
        }
        
        init(_ error: Error) {
            self = .error(error as? NativeError ?? InternalError(error))
        }
    }
    
    typealias ReduceFunc = (Stack, OperatorDefinition, Int, Int) -> Reduction // (token stack, operator definition, start, end)

    
    // TO DO: also capture source code ranges? (how will these be described in per-line vs whole-script parsing? in per-line, each line needs a unique ID (incrementing UInt64) that is invalidated when that line is edited; that allows source code positions to be referenced with some additional indirection: the stack frame captures first and last line IDs plus character offset from start of line)
    typealias StackItem = (reduction: Form, matches: [PatternMatcher], hasLeadingWhitespace: Bool) // in-progress/completed matches

    typealias Stack = [StackItem]
    
    typealias PunctuationHandler = (Value) -> Value // optionally insert debugger commands when parsing .comma, .period, .query, and/or .exclamation delimiters
        
    
    let operatorRegistry: OperatorRegistry
    
    private(set) var current: BlockReader // current token
    //private var annotations = [Token]() // TO DO: parser needs to bind extracted annotations to AST nodes automatically (this may be easier once TokenInfo includes line numbers)
                
    private(set) var stack = Stack()
    
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
    
    // match prefix/infix operator definitions to current/previous+current tokens
    //
    // this method back-matches by up to 1 token in the event the operator pattern starts with an EXPR followed by the operator itself
    //
    // it will not match conjunctions (as those should be at least two tokens ahead of the primary operator name)
    
    private func match(operatorDefinitions: [OperatorDefinition]) -> (previousTokenMatches: [PatternMatcher], currentTokenMatches: [PatternMatcher]) {
        let form = self.current.token.form
        var previousMatches = [PatternMatcher]()
        var currentMatches = [PatternMatcher]()
        for definition in operatorDefinitions {
            for matcher in definition.patternMatchers() {
                // note: first pattern in matcher is reified, so it's tempting to test if it's a keyword (atom/prefix) and toggle on that; however, that won't work if it's .test (e.g. when matching argument label) so it's safest just to apply the first matcher twice: once to current token and, if that fails, to previous token
                
                // move this section onto matcher? (presumably pass stack.last as `previous:` arg)
                
                if matcher.match(form, allowingPartialMatch: true) { // apply to current token; this matches prefix operators
                    currentMatches.append(matcher)
                } else if let previous = self.stack.last, matcher.match(previous.reduction, allowingPartialMatch: true) { // apply to previous token (expr) and current token (opName); this matches infix operators // TO DO: this has disadvantage that it fails if first token is an unreduced expression, in which case the matcher is not attached to the infix operator - thus to re-match the operator later on we have to re-run this entire method; alternative is for matcher to special-case a leading EXPR pattern, but not sure how that'd work (e.g. might set requiresBackMatch flag on matcher when attaching it to current [operatorName] token)
                    
                    let matches = matcher.next().filter{ $0.match(form) } // TO DO: apply this even when previous match fails(?); as long as it succeeds, put matcher in current token's stack frame, marking it as requiring backmatch
                    if !matches.isEmpty { // check opname was 2nd pattern (i.e. primary keyword, not a conjunction); kludgy
                        //currentMatches += matches
                        previousMatches.append(matcher) // for now, put left expr matcher in previous frame; it'll advance back onto .operatorName when next shift(); caution: this works only inasmuch as previous token can be matched as EXPR, otherwise matcher is not attached and is lost from stack
                    }
                }
            }
        }
        print("PREV", previousMatches, "CURR", currentMatches)
        return (previousMatches, currentMatches)
    }
    
    //
    
    // one might argue for Pratt parsing EXPR
    
    // shift moves the current token from lexer to parser's stack and applies any in-progress matchers to it
    //
    // note: if shift completes a list/record/group literal, it is immediately reduced to a value (see OperatorDefinition.autoReduce; i.e. any pattern which has explicit start and end delimiters can be safely auto-reduced as precedence and associativity rules only apply to operators that start and/or end with an EXPR)
    // anything else is left on the stack until an explicit reduceExpression() phase is triggered
    func shift(adding newMatchers: [PatternMatcher] = []) { // newMatchers have (presumably) already matched this token, but we match them again to be sure
        let form = self.current.token.form
        print("\nCURRENT:", form)
        let matchers: [PatternMatcher]
        if let previousMatches = self.stack.last?.matches { // advance any in-progress matches
            print("PREV:", previousMatches, "\nNEW:", newMatchers)
            matchers = previousMatches.flatMap{$0.next()} + newMatchers
        } else {
            print("NEW:", newMatchers)
            matchers = newMatchers
        }
        // apply in-progress and newly-started matchers to current token, noting any that end on this token
        var continuingMatches = [PatternMatcher]()
        var completedMatches = [PatternMatcher]()
        for matcher in matchers {
            if matcher.match(form, allowingPartialMatch: true) { // match succeeded for this token
                continuingMatches.append(matcher)
                if matcher.isAFullMatch { completedMatches.append(matcher) }
            }
        }
        print("SHIFT matched", form, "to", continuingMatches, "with completions", completedMatches)
        self.stack.append((form, continuingMatches, self.current.token.hasLeadingWhitespace))
        // TO DO: if >1 complete match, we can only reduce one of them (i.e. need to resolve any reduce conflicts *before* reducing, otherwise 2nd will get wrong stack items to operate on; alternative would be to fork multiple parsers and have each try a different strategy, which might be helpful during editing)
        // TO DO: what if there are still in-progress matches running? (can't start reducing ops till those are done as we want longest match and precedence needs resolved anyway, but ops shouldn't auto-reduce anyway [at least not unless they start AND end with keyword])
 //       if !completedMatches.isEmpty { print("SHIFT fully matched", completedMatches) }

        
        
        // automatically reduce atomic operators and list/record/group/block literals (i.e. anything that starts and ends with a static token, not an expr, so is not subject to precedence or association rules)
        // TO DO: not sure if reasoning is correct here; if we limit auto-reduction to builtins (which we control) then it's safe to say there will be max 1 match, but do…done blocks should also auto-reduce and those are library-defined; leave it for now as it solves the immediate need (reducing literal values as soon as they're complete so operator patterns can match them as operands)
        if let longestMatch = completedMatches.max(by: { $0.count < $1.count }), longestMatch.definition.autoReduce {
            //           print("\nAUTO-REDUCE", longestMatch.definition.name.label)
            reduce(completedMatch: longestMatch, endingAt: self.stack.count)
            if completedMatches.count > 1 {
                // TO DO: what if there are 2 completed matches of same length?
                print("discarding extra matches in", completedMatches.sorted{ $0.count < $1.count })
            }
        }
//        print(self.stack.last!)
    }
    
    
    
    func reduce(completedMatch: PatternMatcher, endingAt endIndex: Int) {
        let startIndex = endIndex - completedMatch.count // check math (endIndex is inclusive)
        let reduction: StackItem
        let hasLeadingWhitespace = stack[startIndex].hasLeadingWhitespace
        switch completedMatch.definition.reduce(self.stack, completedMatch.definition, startIndex, endIndex) {
        case .value(let v):
            
            var updatedMatchers = [PatternMatcher]()
            
            if startIndex > 0 { // reapply the preceding stack frame's matchers to newly reduced value
                for match in stack[startIndex - 1].matches {
                    if match.match(.value(v)) {
                        updatedMatchers += match.next()
                        
                        // TO DO: what if match is completed?
                    }
                }
                print("updated matchers:", updatedMatchers)
            }
            
            reduction = (Form.value(v), updatedMatchers, hasLeadingWhitespace)
        case .error(let e):
            reduction = (Form.error(e), [], hasLeadingWhitespace)
        }
        print("reduce()", completedMatch, "->", reduction)
        self.stack.replaceSubrange((startIndex..<endIndex), with: [reduction])
        //show(self.stack, 0, self.stack.count, "after reduction")
        
    }

    
    func reduceExpression() { // called on encountering a right-hand delimiter (punctuation, linebreak, operator keyword); TO DO: reduce any fully matched patterns

        //print("REDUCE NOW")
        
        iris_script.reduceExpression(self)
        
        // Q. how to deal with unreduced/incomplete operands; how to deal with operator precedence/associativity?
        
        // TO DO: how to reduce commands? (both `name record` and LP syntax, with added caveat about nested LP syntax)
    }
    
    //
    
    private func handlePunctuation(using handler: PunctuationHandler?) {
        // don't insert debugger command if preceding tokens can't be reduced to Value (i.e. punctuation modifies run-time behavior of the preceding value only, e.g. `Delete my_files!`)
        if self.stack.isEmpty { return } // this could happen if punctuation appears at start of line; parser should reject that case before it gets to here
        if case .value(let value) = self.stack[self.stack.count-1].reduction { // assuming preceding token[s] have already reduced to a value (expr), get that value for passing to hook
            if let fn = handler { self.stack[self.stack.count-1].reduction = .value(fn(value)) }
        } // else if preceding tokens haven't [yet] been reduced, leave the punctuation token for later processing; TO DO: how to avoid double-handling when re-scanning stack (punctuation tokens are left on stack for pattern matching); simplest is to define DebugValue protocol and require callbacks to return that; current stack value can then be tested to see if it's already wrapped
    }
    
    func parseScript() throws -> ScriptAST {
        loop: while true {
            //print("PARSE .\(self.current.token.form)")
            let form = self.current.token.form
            switch form {
            case .endOfScript: break loop // the only time we break out of this loop
            case .annotation(_): () // discard annotations for now
            case .unquotedName(_), .quotedName(_): // command name or record label
                self.shift(adding: commandLiteral.patternMatchers())
            case .startList:
                self.shift(adding: orderedListLiteral.patternMatchers() + keyValueListLiteral.patternMatchers())
            case .startRecord:
                self.shift(adding: recordLiteral.patternMatchers())
            case .startGroup:
                self.shift(adding: groupLiteral.patternMatchers() + parenthesizedBlockLiteral.patternMatchers())
            case .endList, .endRecord, .endGroup:
                self.reduceExpression() // ensure last item is reduced
                self.shift() // shift the closing token onto stack; shift() will autoreduce list/record/group literal
            case .separator(let sep):
                self.reduceExpression() // [attempt to] reduce the preceding value
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
                self.reduceExpression()
                self.shift()
                
            case .operatorName(let operatorDefinitions):
                
                for def in operatorDefinitions.definitions {
                    print(def.name, def.hasLeadingExpression, def.hasTrailingExpression)
                }
                // one could argue the only matches worth starting here are the ones that can auto-reduce
                
                //   print("FOUND OP", definitions.name)
                let (previousMatches, currentMatches) = self.match(operatorDefinitions: operatorDefinitions.definitions)//.filter{$0.autoReduce}) // TO DO: `do done` should probably be rejected as syntax error, but this would match it (twice; once starting at `do`, then backmatching from `done`)
                if !previousMatches.isEmpty { stack[stack.count-1].matches += previousMatches }
                self.shift(adding: currentMatches)
                
            case .colon:
                //self.reduceExpression() // TO DO: not sure about this; in kv-lists key should already be .value(HASHABLEVALUE) else it's a syntax error; in records, we want to match unreduced [c]name/opname token; in `to INTERFACE:ACTION` or
                //self.shift()
                let (previousMatches, currentMatches) = self.match(operatorDefinitions: [pairLiteral])
                //print(definitions.name.label, backMatches, newMatches)
                if !previousMatches.isEmpty { stack[stack.count-1].matches += previousMatches }
                self.shift(adding: currentMatches)
                
            case .semicolon:
                self.reduceExpression() // TO DO: confirm this is correct (i.e. punctuation should always have lowest precedence so that operators on either side always bind first)
                let (previousMatches, currentMatches) = self.match(operatorDefinitions: [pipeLiteral])
                //print(definitions.name.label, backMatches, newMatches)
                if !previousMatches.isEmpty { stack[stack.count-1].matches += previousMatches }
                self.shift(adding: currentMatches)

            default:
                self.shift()
            }
            self.advance()
        }
        
        
        
//        print("\nReductions:")
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
                print(" `\(value)` \(matches.map{"\n    - \($0)"}.joined(separator: ""))") // .filter{$0.isAFullMatch}
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
//                print("Syntax error (unreduced token): \(reduction)\n")
                wasValue = false
            }
            i += 1
        }
        print()
        // TO DO: need error tally; in theory script should be [partially] runnable even with [some?] syntax errors, but problematic sections need marked and script should run in debug mode only with extra guards around anything IO (what about unmatched operators? can we infer where an opname is accidentally used where quoted name is needed [i.e. user needs to resolve naming conflict] vs an opname that has incorrect operands [user needs to fix operands]; how do we represent such unresolved syntax errors as Values [again, allowing other code to execute at least in debug mode])
        return ScriptAST(result)
    }
}
