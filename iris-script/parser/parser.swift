//
//  parser.swift
//  iris-script
//

import Foundation


// simplest is to invoke list reduce func on `]` token, and let reduce func pop stack until it finds corresponding `[` (this isn't table-driven pattern-matching, which is what we ultimately want as tables provide introspectable information that can drive auto-suggest/-correct/-complete, and auto-generate user documentation for operator syntax)

// for now, syntax errors are detected late (but this isn't necessarily a problem as we want to parse the entire script, reducing as much as possible, then prompt user to resolve any remaining issues)

typealias ReduceFunc = (Parser) -> Void

typealias ScriptAST = Block



// OperatorDefinition should include pattern; this is probably easiest done as array of enum

// partial matches are struct of OperatorDefinition + index into pattern array

// when a Value is pushed onto stack, pass it to each partial match which checks it against pattern and returns either new partial match (the match index is advanced and returned in a new partial match struct), completed match (don't reduce immediately as there may be a longer match to be made [i.e. SR conflict is resolved by preferring longest patch]), or no match (in which case that matcher isn't carried forward); that implies matches are part of .value case


// TO DO: should all colons be dealt with using pattern matching? (this might only reduce to colon pairs)
let colonPair = OperatorDefinition(pattern: [.expression, .keyword(":"), .expression], precedence: 0, associate: .right)


let listOp = OperatorDefinition(pattern: [.token(.startList), .optional([.expression, .zeroOrMore([.delimiter, .expression])]), .token(.endList)], precedence: 0, associate: .right)

//let listOp = OperatorDefinition(pattern: [.token(.startList), .expression, .token(.endList)], precedence: 0, associate: .right)

func reduceList(parser: Parser) {
    
}

class Parser { // TO DO: initially implement as full-file parser, then convert to per-line (for incremental parsing)
    
    // Q. how to represent partial values? (in per-line parsing, lists, records, blocks can extend over multiple lines)
    
    // it's all about not recursing; we should never go more than one-parsefunc deep
    /*
    enum Reduction {
        case token(Token) // unreduced tokens are shifted onto stack (these may be part of an incomplete match, or tokens that could not be matched [at all/at this time])
        
        // TO DO: case for `label:value` pairs? may help in parsing record fields (including LP commands); TO DO: problem reading nested commands, reading backwards will associate labeled args with inner command // Q. read commands forward? or set flags indicating LP is/isn't allowed; Q. what about operator pattern-matching, in particular stop-words/conjunctions (e.g. `done`, `then`, and troublesome cases like `to` [which is both infix conjunction and prefix operator]); match operator patterns in fwd direction? Q. what if colon appears at end of line? (prob put token back on stack)
        
        // exprSeq -- comma-separated exprs; constructed without regard to any enclosing braces/blocks (but does need to note presence/absence of trailing comma); thus a reduction becomes `open-brace + close-brace | open-brace + expr + close-brace | open-brace + exprSeq + close-brace`; this should allow expr-seqs to be gathered into array in fwd direction (invalid/unreduced tokens will cause expr-seq to be interrupted, e.g. expr-seq + bad-token + expr-seq); Q. what about `else` operator and sentence blocks?
        
        // semicolon is a transform applied to RH command (if RH operand is not command, it's a syntax error); we could in principle define `;` as an infix operator, except that we want same eol continuation behavior as comma/colon (operators cannot extend over multiple lines) and that requires parser support
        
        // - Q. how to represent invalid items? e.g. wrap [Reduction] array in InvalidValue? insert balancing PlaceholderValue/MissingBraceValue (which guesses where opening/closing brace should be); Q. what are our synchronization points?
        
        // simple operators can usually be reduced on first pass (single-line); operators that take blocks as operands (e.g. `if`, `while`) will be unreduced until full pass
        
        // commands may be reduced on first-pass if short (note: LP commands may have lengthy arguments that wrap over multiple lines; FP commands typically take record as argument so rely on standard record parsing)
        
        // when parser encounters a quoted-/unquoted-name token, it always(?) treats it as a command name; however, if it's immediately followed by a colon then it's a key in colon-pair (but we don't know if it's a property label or a command that returns a dictionary key, or a name-value binding in current scope [syntactic shortcut for assignment]; however, we've already banned commands as keys in KV-list literals [static values only as keys in literals; this is to avoid visual similarity between record and KV-list syntaxes]); therefore, two types of colon pairs: `Symbol:Value` (LP args and record fields) and `KeyConvertibleValue:Value` (kv-list items, where key is number/string/symbol); since Symbol is a KCV, we can store both in Reduction.colonPair(KeyConvertibleValue,Value) and leave reduction funcs for LP commands and records to check that it's Symbol (this shouldn't be too onerous as args and records are relatively short; only kv-list literals can run to large number of items)
        
        // if colon-pair is Value, how to reduce later?
        
        // cmd = name [expr] [colon-pair…]
        // cmd = name record
        // record = '{' '}' | '{' expr-seq '}' -- note: expr-seq may contain colon-pairs where each label is a name
        
        // operator patterns - how to describe operands (normally expr, but some may also be expr-seq)
        
        // per-line can't resolve string literals as it has no way of determining if inside or outside string literal; it needs to capture line String and string indices of double-quote tokens; it will attempt to parse text on both sides of double-quote, which will likely generate more syntax errors on one side than other, providing probability weighting (typographers quotes can also provide weighting, but can't be 100% trusted as users can type them incorrectly)
        
        // Q. how to trigger reduction for prefix/infix operator/punctuation upon pushing trailing Value (EXPR) back onto stack? presumably we push the partially-matched pattern onto stack before parsing EXPR; we resume matching that pattern after EXPR is complete
        
        // TO DO: get rid of colonPair; it may also be worth getting rid of Reduction and just use [Token.Form] for parser stack, which can represent fully reduced values, errors, and not-yet-reduced tokens
        
        case colonPair(Value, Value) // colon pair may be key:value pair in kv-list, label:value in record or LP command, name:value binding in block; anything else? (also, should we restrict where env bindings can appear, e.g. to top-level contexts? if so, how?) // TO DO: have misgivings about this: we can't construct colon pair until we have RH Value, and we can't have that until we've sorted out operators and determined if precedence is greater or less than a command/argument label, e.g. `foo bar: baz of fub` needs to bind `of` tighter than `:`; I suspect we need to leave .token(.colon) on the stack until we're ready to reduce, and let the reducer deal with it (Q. we currently treat `:` as an operator for pattern-matching purposes; if we provide operator definitions with a reduce func, we can presumably tailor the colon 'OpDef's reducefunc to cope with kv-list/record/LP command/binding); most other OpDefs will use a default reducefunc that translates the operation to an annotated Command (another non-standard OpDef is block, which requires a custom reducefunc that reduces to Block; also semicolon which recomposes operands as nested annotated commands)
        
        case value(Value) // reduction function pops one or more tokens off stack and pushes the reduced Value back on
       // case values([Value]) // might be list items, sentence
       // case label(Symbol) // `name:` // problematic, e.g. `to foo a: b: action`
        case error(String) // if reduction fails, add .error to stack then push tokens back on; TO DO: what should syntax errors describe? (in some cases, should be sufficient to suggest missing token, e.g. `[` for `]`)
    }*/
    
    typealias Reduction = Token.Form
    
    // TO DO: expr delimiters (,.?!) should probably be a single Token.Form case
    
    typealias PunctuationHandler = (Value) -> Value // given `,`/`.`/`?`/`!` return debugger command(s) to insert
        
    // callback hooks for inserting debugger commands into AST at parse-time
    var handlePeriod: PunctuationHandler?
    var handleComma: PunctuationHandler?
    var handleQuery: PunctuationHandler?
    var handleExclamation: PunctuationHandler?
    
    private func handlePunctuation(_ token: Token, using handler: PunctuationHandler?) {
        // TO DO: how to annotate AST so that PP can reinsert original punctuation when rendering tidied code?
        // don't insert debugger command if preceding tokens can't be reduced to Value (i.e. punctuation modifies run-time behavior of the preceding value only, e.g. `Delete my_files!`)
        assert(!self.stack.isEmpty) // this could happen if punctuation appears at start of line; parser needs to reject that case before it gets to here
        if case .value(let value) = self.stack[self.stack.count-1].reduction { // assuming preceding token[s] have already reduced to a value (expr), get that value for passing to hook
            if let fn = handler { self.stack[self.stack.count-1] = (.value(fn(value)), []) }
        } else { // if preceding tokens haven't [yet] been reduced, append the punctuation token for later processing
            self.shift(token.form)
        }
    }
    
    let operatorRegistry: OperatorRegistry
    private(set) var current: BlockReader // current token
    private var annotations = [Token]() // TO DO: parser needs to bind extracted annotations to AST nodes automatically (this may be easier once TokenInfo includes line numbers)
    
    
    // TO DO: also capture source code ranges? (how will these be described in per-line vs whole-script parsing? in per-line, each line needs a unique ID (incrementing UInt64) that is invalidated when that line is edited; that allows source code positions to be referenced with some additional indirection: the stack frame captures first and last line IDs plus character offset from start of line)
    typealias StackItem = (reduction: Reduction, matches: [PatternMatcher]) // in-progress/completed matches
            
    private(set) var stack = [StackItem]() // TO DO: what about capturing partially matched patterns? (i.e. build the match while going forward, rather than waiting until reduction and matching backward); Q. how to deal with operator precedence? // one reason to match moving forward is that a complex operator, e.g. `tell EXPR to EXPR`, can install an in-stream detector for its conjunction token (`to`) - in the event that an invalid parse occurs, e.g. `tell (app "foo" to action`, the nearest location[s] of that keyword is known; in a valid parse, the keyword should trigger the reduction of the preceding token, e.g. `tell app "foo" to action` would reduce `app "foo"` when `to` is encountered
    
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
    /*
    func popList() -> Value? { // pop back to .startList
        // TO DO: rework this to match [.startList,EXPR,.token(.colon),EXPR,SEP,…,.endList], and needs to cast LH to KeyConvertible (i.e. literal number/string/symbol)
        var items = [KeyedList.Key: Value]()
        var i = self.stack.count
        while i >= 0 {
            let (last, _) = self.stack[i]
            i -= 1
            switch last {
            case .colon:
                fatalError("TO DO")
               // guard let key = label as? HashableValue else {
                //    print("found invalid key: \(label)")
                //    break
               // }
               // items[key.dictionaryKey] = value
            case .startList: // found start delimiter
                self.stack.removeLast(self.stack.count - i) // remove reduced items from stack
                return items
            default:
                print("found unreduced token: \(last)")
                break
            }
        }
        return nil
    }*/
    
    func popExprSeq(backTo delimiter: Token.Form) -> [Value]? { // TO DO: this assumes all items have already been reduced
        var items = [Value]()
        while let (last, _) = self.stack.popLast() {
            switch last {
            case .value(let item):
                items.insert(item, at: 0)
            case delimiter: // start delimiter
                return items
            default:
                print("found unreduced token: \(last)")
                break
            }
        }
        // reduction failed so roll-back // TO DO: as with popKeyValueSeq, it would probably be easier to leave items on stack until reduction is complete, then remove all
        for item in items { self.stack.append((.value(item), [])) } // TO DO: rather than rolling individual items, push them all onto stack as a single Reduction.valueSeq(items) instead? (Q. if so, is it worth constructing value seqs moving forwards?); what about .valueSeq(…) also capturing beginning/ending token (if found)?
        return nil
    }
    
    //
    
    func shift(_ form: Reduction, _ newMatches: [PatternMatcher] = []) { // newMatches have already matched this token
        // TO DO: who is responsible for back-matching infix/postfix operators? // what API should PatternMatcher provide for this?
        var matches = [PatternMatcher]()
        // advance/discard any in-progress matches
        if let partialMatches = self.stack.last?.matches {
            //print(partialMatches)
            for partialMatch in partialMatches {
                // nil if match was complete on the previous token or has failed to match this token, else a matcher for the next token after this
                matches += partialMatch.match(form)
                    //print("Matched", form, "to", partialMatch, "leaving", thisMatch.remaining)
             //   if partialMatch.isComplete { print("@@@Fully matched", partialMatch.operatorDefinition) }
                
            }
        }
        matches += newMatches
        self.stack.append((form, matches))
    }
    
    func reduceNow() { // called on encountering a right-hand delimiter (punctuation, linebreak, operator keyword); TO DO: reduce any fully matched patterns
        guard let item = self.stack.last else { return } // this'll only occur if a separator appears at start of script
        print("reduceNow:", item)
        
        for m in item.matches where m.isComplete {
           // print("  found edge of fully matched ‘\(m.operatorDefinition.name.label)’ operation")
           // print("  ", self.stack[m.start]) // check start of match for contention, e.g. in `1 + 2 * 3` there is an SR conflict on `2` which requires comparing operator precedences to determine which operation to reduce first
            // in addition, if an EXPR operand match is not a fully-reduced .value(_) then that reduction needs to be performed first
        }
        
        // Q. how to deal with unreduced/incomplete operands; how to deal with operator precedence/associativity?
        
        // TO DO: how to reduce commands? (both `name record` and LP syntax, with added caveat about nested LP syntax)
    }
    
    // note: if conjunction appears in block, keep parsing block but make note of its position in the event unbalanced-block syntax errors are found
    
    // TO DO: lexer seems to pick up an extra linebreak at end of single-line script
    
    func parseScript() throws -> ScriptAST {
        
        // TO DO: how many cases are actually needed if we use pattern matching? (note that pattern matching requires all tokens shifted onto stack); note that some cases (delimiters, end-braces) are required to trigger reduction of preceding tokens (i.e. LP commands have no explicit terminator so are relying on other tokens to implicitly right-terminate them)
        
        loop: while true {
            print("PARSE .\(self.current.token.form)")
            switch self.current.token.form {
            case .endOfScript: break loop // the only time we break out of this loop
            case .annotation(_): () // discard annotations for now
            case .startList:
                let m = PatternMatcher(for: listOp, start: self.stack.count)
                self.shift(self.current.token.form, [m])
            case .endList:
                
                // TO DO: can pattern matchers handle lists and records?
                
                self.reduceNow() // ensure last item is reduced
                // TO DO: need to distinguish `key:value` pairs from values; might need a separate pop func depending on how colon pairs are represented
                // TO DO: how to represent empty KV list? `[:]` (Swift-style syntax) is visually cryptic but avoids any ambiguity; explicit `[] as kv_list` would work but pushes work onto runtime and will be problematic if LH operand is non-empty list
                /*
                if case .colonPair(let key, let value) = self.stack.last?.reduction {
                    print("reduce KV list", key, value)
                    if let items = self.popKeyValueSeq() {
                        self.shift(.value(KeyedList(items)))
                    } else {
                        self.shift(self.current.token.form) // TO DO: what about capturing partial result?
                        print("couldn't reduce kv-list at this time")
                    }
                }
                */
                /*
                if let items = self.popExprSeq(backTo: .startList) {
                    self.shift(.value(OrderedList(items)))
                } else {
                    self.shift(self.current.token.form) // TO DO: what about capturing partial result?
                    print("couldn't reduce list at this time")
                }*/
         //       print("end of list")
                
                self.shift(self.current.token.form)
                
                
            case .endRecord:
                ()
            case .endGroup:
                self.reduceNow()
                if let items = self.popExprSeq(backTo: .startList) {
                    self.shift(.value(Block(items)))
                } else {
                    self.shift(self.current.token.form)
                    print("couldn't reduce group at this time")
                }
            
                // delimiter punctuation always triggers reduction of preceding tokens
                // TO DO: parser should reject punctuation that appears at (e.g.) start of line
                // TO DO: when reduction fails due to syntax error, append Placeholder to stack containing remaining pattern[s]; editor can use this to assist user in correcting/completing code
                // TO DO: check that numeric decimal/thousands separators (e.g. `1,000,000.23`) are reduced by numeric reader; we don't want those confused for expr separators; Q. can numeric reader reliably reduce `+`/`-` prefixes on numbers? (that's challenging as it requires numeric reader to know about balanced whitespace and left delimiters)
            case .separator(let sep):
                self.reduceNow()
                switch sep {
                case .comma:
                    self.handlePunctuation(self.current.token, using: self.handleComma)
                case .period:
                    self.handlePunctuation(self.current.token, using: self.handlePeriod)
                case .query:
                    self.handlePunctuation(self.current.token, using: self.handleQuery)
                case .exclamation:
                    self.handlePunctuation(self.current.token, using: self.handleExclamation)
                }
                self.shift(self.current.token.form)
                
            case .lineBreak:
                self.reduceNow()
                
                
                self.shift(self.current.token.form)
                
                // TO DO: debugger may want to insert hooks (e.g. step) at line-endings too; as before, to preserve LF-delimited list/record items, this needs to operate on preceding value without changing no. of values on stack; it should probably onalso ignore if LF was also preceded by punctuation
                
                // this may or may not fully reduce preceding tokens (e.g. if list wraps multiple lines); Q. any situation where the last token isn't reduced but can legitimately be reduced later? (versus e.g. a dangling operator, which should probably be treated as syntax error even if remaining operand appears at start of next line); yes, e.g. if last token is `[`; if we use patterns to match, patterns should specify where LFs are allowed - upon reaching lineBreak, any patterns that don't permit LF at that point are discontinued (i.e. they remain partially matched up to last token, but don't carry forward to next line); the alternative is we do allow patterns to carry forward in hopes of completing parse, then have PP render as a single line of code (but that isn't necessarily what user intended, e.g. `foo + LF to bar: baz`)
                
                
                
                // TO DO: .colon, .semicolon are probably easiest implemented as patterns which are pushed onto stack when those tokens are encountered
                
            case .operatorName(let operatorClass):
                
                // note: resolving operator precedences, e.g. `1 + 2 * 3`, is a form of SR-conflict resolution; presumably we need to look at `2` to see if it is matched by >1 operator (then we need to check those operators are completely matched)
                
                // having encountered an operator-defined keyword, we get all operator definitions that use that keyword
                // TO DO: if the opdef has a leading expr before that keyword, check stack's head is an expr; append a new PatternMatcher to head's matches then add the Reduction.token(.operatorName(…) with nextMatch)
                
                // TO DO: if stack's head is not an expr, reduceNow?
                
                // TO DO: reconcile these patterns with any partially matched patterns at top(?) of stack; note that these patterns could also spawn new partial matches (e.g. `to…` vs `tell…to…`, `repeat…while…` vs `while…repeat…`)
                
             //   print("FOUND OP", operatorClass.name)
                
                
                var m = [PatternMatcher]()
                
                // TO DO: should this be moved to shift()? (it would mean shift's 2nd parameter becomes [OpDef] instead of [PatternMatcher])
                for definition in operatorClass.definitions {
                    // TO DO: is there any situation where neither first nor second pattern is a keyword?
                    //print("back-matching:", definition)
                    // temporary kludge
                    if case .keyword(let k) = definition.pattern[0], k.matches(operatorClass.name) { // prefix operator
                        let newMatch = PatternMatcher(for: definition, start: self.stack.count, remaining: [Pattern](definition.pattern.dropFirst()))
                        print("  adding matcher for ‘\(operatorClass.name.label)’:", newMatch)
                        m.append(newMatch)
                       // print("matched prefix op", newMatch)
                    } else if definition.pattern.count > 1, case .expression = definition.pattern[0], case .keyword(let k) = definition.pattern[1], k.matches(operatorClass.name) { // infix/postfix operator
                        if let last = self.stack.last {
                           // print("checking last", last.reduction)
                            if case .value(_) = last.reduction { // TO DO: this needs work as .value is not the only valid Reduction: stack's head can also be an unreduced command or LP argument, but we don't know if we should reduce that command now or later (we have to finish matching the operator in order to know the operator's precedence, at which point we can determine which to reduce first: command (into an operand) or operator (into an argument)); Q. do we actually need to know if EXPR is a valid expression to proceed with the match? if it looks like it *could* be reduced later on (i.e. it's not a linebreak or punctuation), that might be enough to proceed with match for now
                                let newMatch = PatternMatcher(for: definition, start: self.stack.count-1, remaining: [Pattern](definition.pattern.dropFirst()))
                                print("  adding matcher for ‘\(operatorClass.name.label)’:", newMatch)
                                self.stack[self.stack.count-1].matches.append(newMatch) // add matcher to head of stack, before operator name is shifted onto it
                                // shift() will carry this forward from head of stack
                                //print("matched infix/postfix op", newMatch)
                            }
                        }
                    } else {
                        // check head's existing matches: if name is conjunction in one of those then do nothing
                        if let last = self.stack.last {
                            for partialMatch in last.matches {
                                if !partialMatch.isComplete, case .keyword(let k) = partialMatch.remaining[0], k.matches(operatorClass.name) {
                                    print(operatorClass.name, "is part of existing match")
                                }
                            }
                        }
                        //print("TO DO: back-matching complex operators: \(definition.pattern)")
                    }
                    // first challenge: operator keyword can change how preceding Reduction[s] should be reduced, e.g. given, `a - 1` or `a -1`, infix `-` wants to reduce `a` to arg-less command, whereas prefix `-` wants to consume `1` then push `-1` onto stack to be finally reduced as `a{-1}`; we can probably tighten this up with balanced-whitespace/no-trailing-whitespace rules (it might even be wise to enforce balanced whitespace for infix operators at parser level, though we can't enforce no-trailing-whitespace as that won't work for word-based operators such as `NOT`)
                    
                }
                
                self.shift(self.current.token.form, m)
                
                // TO DO: new patterns need backwards-matched as needed (e.g. infix, postfix ops need to match current topmost stack item as LH operand, caveat if that is preceded by another operator requiring precedence/associativity resolution); note that while these patterns are completed upon reducing RH expression, we can't immediately reduce completed patterns as there may be another operator name after the expr; need to wait for delimiter (punctuation or linebreak) to trigger those reductions
                
                
            case .colon: // push onto stack; what about pattern matching? what should `value:value` transform to?
                //self.reduceNow() // TO DO: is this appropriate? probably not: need to take care not to over-reduce LH (e.g. `foo bar:baz` should not reduce to `foo{bar}:baz`) i.e. is there any situation where LH is *not* a single token ([un]quotedName or symbol/string/number literal) - obvious problem here is that it won't handle string literals that haven't already been reduced to .value (which is something we defer when reading per-line)
                let m: [PatternMatcher]
                if case .value(_) = self.stack.last?.reduction {
                    m = [PatternMatcher(for: colonPair, start: self.stack.count-1, remaining: [colonPair.pattern[2]])]
                } else {
                    m = []
                }
                
                // TO DO: is it worth passing new matchers to shift()? infix operator already adds matcher directly to stack's head (prior to shifting operator onto it); for prefix operator, might be as well to shift then add matcher to head; there is also question of where to instantiate pattern matchers for lists, records
                
                // TO DO: can LP commands be matched with a matcher? needs to know if command is nested (otherwise the inner command will 'steal' the outer command's remaining keyword arguments, which is not what we want; i.e. command matching is context-sensitive)
                
                self.shift(self.current.token.form, m) // this needs to add colon-pair pattern if top of stack (LH) is EXPR (or anything other than `[`?) (unlike operators, which are library-defined, colon is hardcoded punctuation with special representation); should `[:]` be matched as pattern, or just hardcode into `case .endList`? one reason to prefer patterns is they generate better syntax error messages
                
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
                
                
                // .quotedName, .unquotedName // command or label; push onto stack
                
            case .value(let value):
                self.shift(.value(value))
            default:
                self.shift(self.current.token.form)
            }
            self.advance()
        }
        print("\nReductions:")
        var result = [Value]()
        for (reduction, matches) in self.stack {
            if case .value(let value) = reduction {
                result.append(value)
            } else {
                //print("Found non-value: \(reduction)")
            }
//            .filter{$0.isComplete}
            print("  .\(reduction)", matches.map{"\n    - \($0)"}.joined(separator: ""))
            print()
        }
        print()
        return ScriptAST(result)
    }
}
