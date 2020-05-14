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


func reduceList(parser: Parser) {
    
}

class Parser { // TO DO: initially implement as full-file parser, then convert to per-line (for incremental parsing)
    
    // Q. how to represent partial values? (in per-line parsing, lists, records, blocks can extend over multiple lines)
    
    // it's all about not recursing; we should never go more than one-parsefunc deep
    
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
        
        case colon(Value, Value) // colon pair may be key:value pair in kv-list, label:value in record or LP command, name:value binding in block; anything else? (also, should we restrict where env bindings can appear, e.g. to top-level contexts? if so, how?)
        
        case value(Value) // reduction function pops one or more tokens off stack and pushes the reduced Value back on
       // case values([Value]) // might be list items, sentence
       // case label(Symbol) // `name:` // problematic, e.g. `to foo a: b: action`
        case error(String) // if reduction fails, add .error to stack then push tokens back on; TO DO: what should syntax errors describe? (in some cases, should be sufficient to suggest missing token, e.g. `[` for `]`)
    }
    
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
            self.stack.append((.token(token), []))
        }
    }
    
    let operatorRegistry: OperatorRegistry
    private(set) var current: BlockReader // current token
    private var annotations = [Token]() // TO DO: parser needs to bind extracted annotations to AST nodes automatically (this may be easier once TokenInfo includes line numbers)
            
    private(set) var stack = [(reduction: Reduction, partialMatches: [PartialMatch])]() // TO DO: what about capturing partially matched patterns? (i.e. build the match while going forward, rather than waiting until reduction and matching backward); Q. how to deal with operator precedence? // one reason to match moving forward is that a complex operator, e.g. `tell EXPR to EXPR`, can install an in-stream detector for its conjunction token (`to`) - in the event that an invalid parse occurs, e.g. `tell (app "foo" to action`, the nearest location[s] of that keyword is known; in a valid parse, the keyword should trigger the reduction of the preceding token, e.g. `tell app "foo" to action` would reduce `app "foo"` when `to` is encountered
    
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
    
    // parsing sentence block operands is problematic: requires changing parsing behavior on trailing operand so that commas do not terminate (but still needs to break at period/eol/`else` operator) - that won't combine well with reductions, which work backwards from terminator (i.e. not context-sensitive)
    
    func popKeyValueSeq() -> [KeyedList.Key: Value]? { // pop back to .startList
        
        return [:]
    }
    
    func popExprSeq(backTo delimiter: Token.Form) -> [Value]? {
        var items = [Value]()
        while let (last, _) = self.stack.popLast() {
            switch last {
            case .value(let item):
                items.insert(item, at: 0)
            case .token(let token) where token.form == delimiter: // start delimiter
                return items
            default:
                print("found unreduced token: \(last)")
                break
            }
        }
        for item in items { self.stack.append((.value(item), [])) } // TO DO: rather than rolling back entirely, add .values(items) instead? could argue for constructing values seq forwards; what about .values(…) also capturing beginning/ending token (if found)?
        return nil
    }
    
    func reduceNow() { // called on encountering a right-hand delimiter (punctuation, linebreak, operator keyword); TO DO: reduce any fully matched patterns
        if let item = self.stack.last { print("reduceNow:", item) }
        
        // TO DO: how to reduce commands? (both `name record` and LP syntax, with added caveat about nested LP syntax)
    }
    
    // note: if conjunction appears in block, keep parsing block but make note of its position in the event unbalanced-block syntax errors are found
    
    
    func parseScript() throws -> ScriptAST {
        loop: while true {
            print(self.current.token.form)
            switch self.current.token.form {
            case .endOfScript: break loop
            case .annotation(_): () // discard annotations for now
            case .endList:
                self.reduceNow() // ensure last item is reduced
                // TO DO: need to distinguish `key:value` pairs from values; might need a separate pop func depending on how colon pairs are represented
                // TO DO: how to represent empty KV list? `[:]` (Swift-style syntax) is visually cryptic but avoids any ambiguity; explicit `[] as kv_list` would work but pushes work onto runtime and will be problematic if LH operand is non-empty list
                if case .colon(let key, let value) = self.stack.last?.reduction {
                    print("reduce KV list", key, value)
                    if let items = self.popKeyValueSeq() {
                        self.stack.append((.value(KeyedList(items)), []))
                    } else {
                        self.stack.append((.token(self.current.token), [])) // TO DO: what about capturing partial result?
                        print("couldn't reduce kv-list at this time")
                    }
                }
                if let items = self.popExprSeq(backTo: .startList) {
                    self.stack.append((.value(OrderedList(items)), []))
                } else {
                    self.stack.append((.token(self.current.token), [])) // TO DO: what about capturing partial result?
                    print("couldn't reduce list at this time")
                }
            case .endRecord:
                ()
            case .endGroup:
                self.reduceNow()
                if let items = self.popExprSeq(backTo: .startList) {
                    self.stack.append((.value(Block(items)), []))
                } else {
                    self.stack.append((.token(self.current.token), []))
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
            case .lineBreak:
                self.reduceNow()
                // TO DO: debugger may want to insert hooks (e.g. step) at line-endings too; as before, to preserve LF-delimited list/record items, this needs to operate on preceding value without changing no. of values on stack; it should probably onalso ignore if LF was also preceded by punctuation
                
                // this may or may not fully reduce preceding tokens (e.g. if list wraps multiple lines); Q. any situation where the last token isn't reduced but can legitimately be reduced later? (versus e.g. a dangling operator, which should probably be treated as syntax error even if remaining operand appears at start of next line); yes, e.g. if last token is `[`; if we use patterns to match, patterns should specify where LFs are allowed - upon reaching lineBreak, any patterns that don't permit LF at that point are discontinued (i.e. they remain partially matched up to last token, but don't carry forward to next line); the alternative is we do allow patterns to carry forward in hopes of completing parse, then have PP render as a single line of code (but that isn't necessarily what user intended, e.g. `foo + LF to bar: baz`)
                
                
                
                // TO DO: .colon, .semicolon are probably easiest implemented as patterns which are pushed onto stack when those tokens are encountered
                
            case .operatorName(let operatorDefinitions):
                
                // TO DO: reconcile these patterns with any partially matched patterns at top(?) of stack; note that these patterns could also spawn new partial matches (e.g. `to…` vs `tell…to…`, `repeat…while…` vs `while…repeat…`)
                
                print("Operator", operatorDefinitions)
                
                // TO DO: new patterns need backwards-matched as needed (e.g. infix, postfix ops need to match current topmost stack item as LH operand, caveat if that is preceded by another operator requiring precedence/associativity resolution); note that while these patterns are completed upon reducing RH expression, we can't immediately reduce completed patterns as there may be another operator name after the expr; need to wait for delimiter (punctuation or linebreak) to trigger those reductions
                
                
            case .colon: // push onto stack; what about pattern matching? what should `value:value` transform to?
                //self.reduceNow() // TO DO: is this appropriate? probably not: need to take care not to over-reduce LH (e.g. `foo bar:baz` should not reduce to `foo{bar}:baz`) i.e. is there any situation where LH is *not* a single token ([un]quotedName or symbol/string/number literal) - obvious problem here is that it won't handle string literals that haven't already been reduced to .value (which is something we defer when reading per-line)
                self.stack.append((.token(self.current.token), [])) // this needs to add colon-pair pattern if top of stack (LH) is EXPR (or anything other than `[`?) (unlike operators, which are library-defined, colon is hardcoded punctuation with special representation); should `[:]` be matched as pattern, or just hardcode into `case .endList`? one reason to prefer patterns is they generate better syntax error messages
                
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
            default:
                self.stack.append((.token(self.current.token), []))
            }
            self.advance()
        }
        return ScriptAST([])
    }
}
