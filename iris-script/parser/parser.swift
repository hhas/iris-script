//
//  parser.swift
//  iris-script
//

// TO DO: need to formalize delimiter rules (punctuation/linebreaks/operator names/quotes)

// TO DO: how to read multi-sentence blocks? (it might be easiest to read as flat array, with punctuation [modifiers] attached to each element/kept in parallel array; we need to give some more thought as to how `?` and `!` modify evaluation process, e.g. by creating a thin subscope with the appropriate behavioral hooks; however, all this really ties into how we describe accessor vs mutator operations, and access to external resources, as handler characteristics)
// TO DO: how to read blocks with custom delimiters, e.g. `do…done`?
// TO DO: how to deal with terminator punctuation (`.?!`)? also, what should be syntax rules for using terminator punctuation at end of list/record items? e.g. `(Foo, bar! Baz)` is perfectly legal (being a group of two sentences), but should `[foo, bar! baz]` require explicit parenthesization to avoid any ambiguity on where each list item begins and ends, e.g. `[foo, (bar!), baz]` or `[(foo, bar!), baz]`

// should `tell`, `if`, `while` operators use `tell EXPR to EXPR`, `if EXPR then EXPR`, `while EXPR repeat EXPR` syntax? Q. what word should separate operands in `to`/`when`, e.g. `to perform_action {…} returning TYPE XXXX do … done.`

// one more possibility for `tell`, `if`, etc: define them as prefix operators, and require comma separator between first and second operands; thus: `tell app "TextEdit", make new: #document.`, `if some_condition, do…done.`; this should read more naturally for `to`/`when` operators: `to perform_action {…} returning TYPE, do … done.`; OTOH, it doesn't read as well for `tell` which benefits from the pronouncable `to` preposition.

// in case of to/when, the


import Foundation

// nasty hacky duct-taped temp code (recursive descent Pratt Parser class taken from sylvia-lang, hacked up to support iris syntax); not what we want (which is non-recursive table-driven bottom-up incremental parsing) but will do as stopgap for sake of getting language up and running


// if test: expr -- TO DO: assuming `if` is a command, `test: expr` looks like a labeled argument, rather than an unlabeled pair argument (OTOH, this shouldn't be an issue as long as `if` is an operator, as operands do not have labels)

let argumentPrecedence: Precedence = 200 // TO DO: what, if any, precedence? e.g. given low-punctuation command: `foo 1 + 2 by: bar of baz` -- should the `by` argument be `bar of baz` or `bar`?

// TO DO: need to finalize association rules for low-punctuation commands; given that 'variables' (i.e. arg-less commands) may frequently appear as arguments it may be preferable to bind trailing args to the outermost command; e.g. `foo bar baz: fub` -> `foo (bar) baz: fub` = `foo {bar, baz: fub}`, rather than most recent (`foo {bar {baz: fub}}`); the allowLooseArguments flag should produce this result, but needs some real-world usage tests to confirm it's the right choice

// TO DO: also need decision on `foo {…} bar: baz`; while it can be inferred that record is first [direct] arg value, problem here is that treating the record as first arg value is inconsistent with `foo {…}`, so may be cleaner to treat it as syntax error

// TO DO: we also need to nail down singular vs plural use of 'argument[s]' and 'parameter[s]' - while the internal implementation is closer to the traditional name coupled to N-ary tuple, we describe commands as unary prefix operators whose operand is always a record (if omitted, an empty record is inferred)

class Parser {
    
    private let operatorRegistry: OperatorRegistry
    private var current: BlockReader
    private var annotations = [Token]() // TO DO: parser needs to bind extracted annotations to AST nodes automatically (this may be easier once TokenInfo includes line numbers)
    
    init(tokenStream: BlockReader, operatorRegistry: OperatorRegistry) {
        self.current = tokenStream
        self.operatorRegistry = operatorRegistry
    }
    
    func peek(ignoringLineBreaks: Bool = false) -> BlockReader {
        var reader: BlockReader = self.current.next()
        while true {
            switch reader.token.form {
            case .annotation(_): () // TO DO: how to associate annotations with values?
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
    
    func readList() throws -> Value { // start on '['
        let value: Value
        self.advance(ignoringLineBreaks: true)
        switch self.current.token.form {
        case .colon: // accept `[:]` as literal notation for empty record (key-value list)
            self.advance(ignoringLineBreaks: true)
            guard case .endList = self.current.token.form else {
                throw BadSyntax.unterminatedList //("Expected end of empty record, “]”, but found: \(self.current)")
            }
            value = KeyedList()
        case .endList: // found `[]` (empty list)
            value = OrderedList()
        default: // found non-empty ordered/keyed list, so need to start parsing it to determine which it is
            enum Form {
                case ordered
                case keyed
                case undetermined
            }
            // TO DO: this is a bit wasteful
            var dict = [KeyedList.Key:Value]()
            var form = Form.undetermined
            let items = try self.readItems(until: { $0 == .endList}) { () throws -> Value in
                let item = try self.parseExpression()
                //print("read list item", item, "now on", self.current)
                switch form {
                case .ordered:
                    if item is Pair { throw NotYetImplementedError() }
                case .keyed:
                    // TO DO: what if key is Command or other non-constant? (i.e. should dict literals require literal keys, or is there any use-cases where keys would be evaled on the fly?)
                    guard let pair = item as? Pair else { throw UnsupportedCoercionError(value: item, coercion: asPair) }
                    guard let key = (pair.key as? HashableValue)?.hashKey else { // TO DO: see below
                        throw UnsupportedCoercionError(value: pair.key, coercion: asHashableValue)
                    }
                    dict[key] = pair.value
                case .undetermined:
                    if let pair = item as? Pair {
                        guard let key = (pair.key as? HashableValue)?.hashKey else { // TO DO: we want to restrict literal dictionary keys to literal values only (numbers, strings, symbols, etc); anything else - e.g. commands, operators, and other non-const exprs - should be explicitly rejected (these can still be used in `set item named EXPR of DICT to …`); this restriction should ensure that OperatorReader's `where` clauses can reliably escape record labels as context-free `NAME:`
                            throw UnsupportedCoercionError(value: pair.key, coercion: asHashableValue)
                        }
                        dict[key] = pair.value
                        form = .keyed
                    } else {
                        form = .ordered
                    }
                }
                //print("got list item", item, "ended on", self.current)
                return item
            }
            if dict.count == 0 { // no items are unparenthesized Pairs, so it's a List
                value = OrderedList(items)
            } else if dict.count == items.count { // all items are Pairs with literal keys, so create a key-value list with internal `[Key:Value]` storage
                value = KeyedList(dict)
            } else {
                throw BadSyntax.unterminatedList //SyntaxError("Not a valid record (\(items.count - dict.count) missing/duplicate key[s]): \(items)")
            }
        }
        //print("list ended on", self.current)
        return value // end on ']'
    }
    
    func readRecord() throws -> Record { // start on '{'
        assert(self.current.token.form == .startRecord)
        self.advance(ignoringLineBreaks: true) // step over '{' to first expression // TO DO: could do with knowing if linebreaks were skipped so that value can be annotated with formatting hints for pretty-printer
        let items = try self.readItems(until: { $0 == .endRecord}) { () throws -> Record.Field in
            let key = self.readLabel() ?? nullSymbol
            let value = try self.parseExpression()
            if value is Pair { print("TO DO: record field contains a Pair value") } // TO DO: check pair values is wrapped in parens to disambiguate, otherwise throw a syntax error
            return (key, value)
        }
        // make sure block has closing '}'
        guard case .endRecord = self.current.token.form else { throw BadSyntax.unterminatedRecord } //SyntaxError("Expected expression or end of block but found: \(self.current)") }
        return try Record(items) // end on '}'
    }
    
    // TO DO: also allow linebreaks as list/record item separators? (code blocks already allow comma and/or linebreak); should be okay as long as commands/operators can't be wrapped over multiple lines (this doesn't preclude code editor soft-wrapping for display); bear in mind that parens can be used to delimit expr seqs, so hard-wrapping commands/operators over multiple lines isn't an option (caveat commands written with explicit record punctuation, which should be fine to wrap as long as opening '{' is immediately after command name)
    
    func readItems<T>(until isEndToken: ((Token.Form) -> Bool), using parseItem: (() throws -> T)) throws -> [T] { // e.g. `[EXPR,EXPR,EXPR]`
        // upon calling readItems, cursor must be positioned on first token of first item (or on end token if no items found); upon return, cursor will be positioned on end token
        var items = [T]()
        loop: while !isEndToken(self.current.token.form) { // check for ')'/']'
            //print("read item")
            do {
                items.append(try parseItem()) // this starts on first token of expression and ends on last
            } catch { // TO DO: get rid of this once parser reports error locations
                print(items)
                print("Failed to read item \(items.count+1):", error) // DEBUGGING
                throw error
            }
            //print("appended", items.last!, "now on", self.current.token) // FIX: why is this on comma, not end of expr?
            self.advance() // next token should be .comma and/or .lineBreak, or end token
            //print("appended", items.last!, self.current.token)
            switch self.current.token.form {
            case .comma, .lineBreak: // if it's a comma/linebreak then advance to next item
                self.advance(ignoringLineBreaks: true) // step over ','
            default: // TO DO: what about other expr seq terminators: `.?!`? (for expr sequences, these will be treated as end tokens; what if they appear after list/record items? e.g. `[ LF A? LF B! LF ]`); Q. what about semicolons? (semicolons should be matched in parseOperation)
                break loop
            }
        }
        // make sure there's a closing ')'/']'
        if !isEndToken(self.current.token.form) {
            // TO DO: need to format items as partial list; right now it displays badly
            print("Unexpected token after item \(items.count) of sequence: \(self.current.token)")
            throw BadSyntax.unterminatedList //
        }
        return items // finish on ')'/']'
    }
    
    func readLabel() -> Symbol? {
        let name: String
        // TO DO: replace isName with Token.identifier->String?
        if self.current.token.isName && self.current.token.isRightContiguous && self.peek().token.form == .colon {
            switch self.current.token.form {
            case .quotedName(let s):   name = s
            case .unquotedName(let s): name = s
            default:                   name = String(self.current.token.content)
            }
        } else if case .operatorName(_) = self.current.token.form, self.current.token.isRightContiguous && self.peek().token.form == .colon {
            name = String(self.current.token.content)
        } else {
            return nil
        }
        self.advance() // step over name
        self.advance() // step over colon
        return Symbol(name)
    }
    
    func readCommand(_ allowLooseArguments: Bool) throws -> Command { // cursor is on first token on command (i.e. its name)
        // peek ahead: if next token is `{`, read arguments record; if next token is expr sep punctuation/linebreak/eof or infix/postfix op, command has no args; otherwise read low-punctuation arg[s] as exprs - first arg may be Pair or Value; subsequent args must be Pairs with label keys
        let name: String
        var arguments: [Command.Argument]
        switch self.current.token.form {
        case .quotedName(let s):
            name = s
        case .unquotedName(let s):
            name = s
        default:
            name = String(self.current.token.content)
        }
        print("reading args for command `\(name)`", allowLooseArguments)
        let next = self.peek().token
        if next.isRightDelimiter { // no argument
            arguments = []
        } else if case .startRecord = next.form { // explicit record argument; this always binds to command name
            self.advance()
            arguments = try self.readRecord().fields
        } else if allowLooseArguments { // low-punctuation command; first field may be unlabeled, subsequent fields must be labeled
            arguments = [Command.Argument]()
            self.advance()
            if !self.current.token.isRightDelimiter {
                if let label = self.readLabel() {
                    arguments.append((label, try self.parseExpression(argumentPrecedence, allowLooseArguments: false))) // TO DO: precedence?
                } else {
                    arguments.append((nullSymbol, try self.parseExpression(argumentPrecedence, allowLooseArguments: false)))
                }
                //print("read first arg:", arguments)
                while !self.peek().token.isRightDelimiter {
                    self.advance()
                    guard let label = self.readLabel() else {
                        print("expected label in \(name) command but found", self.current.token); throw BadSyntax.missingName }
                    arguments.append((label, try self.parseExpression(argumentPrecedence, allowLooseArguments: false)))
                    //print("read labeled arg:", arguments)
                }
            }
        } else {
            arguments = []
        }
        //print("completed command:", Command(Symbol(name), arguments), "ended on", self.current.token)
        return Command(Symbol(name), arguments) // leaves cursor on last token of command
    }
    
    // token matching
    
    private func parseAtom(_ allowLooseArguments: Bool = true) throws -> Value {
        let tokenInfo = self.current
        //print("parseAtom", tokenInfo)
        let token = tokenInfo.token
        let value: Value
        switch token.form {
        case .value(let v):
            value = v
        case .startList:      // `[…]` - an ordered collection (array) or key-value collection (dictionary)
            value = try self.readList()
        case .startRecord:     // `{…}`
            value = try self.readRecord()
        case .startGroup:     // `(…)`
            // TO DO: fix this: parens may enclose expr seqs
            self.advance(ignoringLineBreaks: true) // step over '('
            value = try self.parseExpression()
            // TO DO: need to annotate value in order to preserve elective parens when pretty printing; also to determine if a list literal represents a table or a list of arbitrary pairs (e.g. ["foo":1] = Record, [("foo":1)] = List)
            self.advance(ignoringLineBreaks: true) // step over ')'
            guard case .endGroup = self.current.token.form else { throw BadSyntax.unterminatedGroup } //SyntaxError("Expected end of precedence group, “)”, but found: \(self.this)") }
        case .letters, .symbols, .quotedName(_), .unquotedName(_): // found `NAME`/`'NAME'`
            // TO DO: reading reverse domain names with optional `@` prefix, e.g. `com.example.foo`, is probably best done by a LineReader adapter; question is whether we should generalize this to allow commands with arguments within/at end
            value = try self.readCommand(allowLooseArguments)
        case .operatorName(let operatorClass) where !operatorClass.hasLeftOperand: // atom/prefix operator
            if self.peek().token.isRightDelimiter {
                guard let definition = operatorClass.atom else { throw BadSyntax.missingExpression } // TO DO: if right-contiguous and next token is colon, then value should be label
                value = Command(definition)
            } else {
                guard let definition = operatorClass.prefix else {
                    print("parseAtom bad operator:", operatorClass);
                    throw BadSyntax.unterminatedExpression }
                self.advance() // step over operator name to read right-hand operand
                value = Command(definition, right: try self.parseExpression(definition.precedence, allowLooseArguments: true))
            }
        case .hashtag:
            if self.current.token.hasTrailingWhitespace {
                print("found space after `#`")
                throw BadSyntax.missingName }
            self.advance(ignoringLineBreaks: true) // step over '#'
            switch self.current.token.form {
            case .letters, .symbols:    value = Symbol(String(self.current.token.content))
            case .quotedName(let name): value = Symbol(name)
            case .unquotedName(let name): value = Symbol(name)
            default:                    print("expected name after `#` but found", self.current.token);throw BadSyntax.missingName
            }
        case .mentions:
            //if self.current.token.hasTrailingWhitespace { throw BadSyntax.missingName }
            //
            throw NotYetImplementedError()
        case .endOfScript:
            print("Expected an expression but found end of code instead.")
            throw BadSyntax.missingExpression //SyntaxError("Expected an expression but found end of code instead.")
        default:
            print("Expected an expression but found \(token)")
            throw BadSyntax.missingExpression //SyntaxError("Expected an expression but found \(token)")
        }
        //value.annotations[codeAnnotation] = CodeRange(start: tokenInfo.start, end: self.current.end)
        //print("ENDED parseAtom", value)
        return value
    } // important: this should always leave cursor on last token of expression
    
    
    // propagate allowLooseArguments through operators too (e.g. `duplicate document at 1 of documents to: end of documents`); only parens/brackets/braces should discard this flag
    private func parseOperation(_ leftExpr: Value, allowLooseArguments: Bool = true) throws -> Value {
        let tokenInfo = self.current
        //print("BEGIN parseOperation", tokenInfo)
        let token = tokenInfo.token
        let value: Value
        switch token.form {
            
            // TO DO: include cases for comma separator and `.?!` terminators, where leftExpr is either an existing Block upon which to append the right-hand expr (if any), or a new block is started with leftExpr as its first element; this should allow us to read sentences without any special logic needed (currently parseScript() vomits on sentence punctuation, as it wants to read to end of script); need to give this a little more thought, but it should work (e.g. how best to encode multiple sentences - as a block of sentence blocks, or as a flat block with reverse-order `,.?!` evaluation modifier annotations [Q. how deep should modifiers apply? e.g. to all lexical exprs in a conditional? what about all exprs in invoked handlers' bodies?])
            
        case .operatorName(let operatorClass) where operatorClass.hasLeftOperand: // TO DO: what errors if operator not found?
            // TO DO: how to disambiguate `command expr postfixOpName: expr`, where an argument label is lexed as an operator name? note that lexer can't do label check itself, as `[expr postfixOpName:…]` is a valid construct (`expr postfixOpName` being a left-hand expression); if we forbid exprs in literal dict keys, is there anywhere else that `opName:` could be anything other than a label? (depends on where else Pairs might appear; the defining restriction for a pair seems to be that the left side is either a hashable value literal or an unquoted/quoted name or .symbol; if we impose that restriction, and possibly encode it in Pair, e.g. as Key enum, then pairs should be sufficiently context-free to allow 'dumb' line reader to detect and convert them to .value(Pair), or maybe .label(_), although we would still need to watch out when parsing [hence .label is safer than .value, as it won't be sucked up into an expression by accident]; also might be worth cleanly distinguishing Pair from Label: the former for use in dict literals, the latter for use in records and possibly blocks [if we use NAME:VALUE as shorthand for assignment/name binding, which is something we'll want for handler glues])
            
            let nextToken = self.peek().token
            if nextToken.isRightDelimiter { // no right operand, so current token needs to be a postfix operator
                if token.isRightContiguous && nextToken.form == .colon {
                    // problem: having got here, e.g. due to `at:` label in lp command, we can't trivially rewrite token stream (changing .operatorName to .unquotedName) and backtrack (we can't just return leftExpr as that loses the `at` token); problem is that as long as `at` appears to be an operator, it wants to bind to preceding argument value; solution is to transform `operatorName colon` to `unquotedName colon`, or maybe even `label`; this BlockReader will also need to balance braces/brackets/parens and have some knowledge of commands
                    
                    print("ambiguous operator/label name `\(token.content)` after", leftExpr)
                    throw BadSyntax.unterminatedExpression
                }
                guard let definition = operatorClass.postfix else {
                    print("parseOperation bad operator:", operatorClass);
                    throw BadSyntax.unterminatedExpression
                }
                value = Command(definition, left: leftExpr)
            } else { // infix operator
                guard let definition = operatorClass.infix else { throw BadSyntax.unterminatedExpression }
                self.advance() // step over operator name to read right-hand operand
                let precedence = definition.associativity == .right ? definition.precedence - 1 : definition.precedence
                value = Command(definition, left: leftExpr, right: try self.parseExpression(precedence, allowLooseArguments: allowLooseArguments))
            }
        case .colon:
            self.advance(ignoringLineBreaks: true) // skip over ":"
            value = Pair(leftExpr, try self.parseExpression(token.form.precedence - 1, allowLooseArguments: false)) // pairs are right-associative
        case .semicolon:
            self.advance(ignoringLineBreaks: true) // skip over ";"
            let rightExpr = try self.parseExpression()
            guard let command = rightExpr as? Command else { throw UnsupportedCoercionError(value: rightExpr, coercion: asCommand) } // TO DO: what error?
            value = Command(command.name, [(nullSymbol, rightExpr)] + command.arguments)
            // TO DO: annotate command for pp; i.e. `B {A, C}` should print as `A; B {C}`
        case .endOfScript:
            print("Expected an operand after the following code but found end of code instead: \(leftExpr)")
            throw BadSyntax.missingExpression //SyntaxError("Expected an operand after the following code but found end of code instead: \(leftExpr)")
        default:
            print("Invalid token after leftExpr `\(leftExpr)`: \(token)")
            throw BadSyntax.missingExpression//SyntaxError("Invalid token after \(leftExpr): \(token)")
        }
//        value.annotations[codeAnnotation] = CodeRange(start: tokenInfo.start, end: self.current.end)
        //print("ENDED parseOperation", value)
        return value
    } // important: this should always leave cursor on last token of expression
    
    
    func parseExpression(_ precedence: Precedence = 0, allowLooseArguments: Bool = true) throws -> Value { // TO DO: should this method be responsible for binding extracted annotations to adjacent Values?
        //print("BEGIN expr")
        var left = try self.parseAtom(allowLooseArguments)
        // this loop should always break on separator punctuation (this should happen automatically as punctuation uses -ve precedence, putting it lower than everything else)
        //print("parseExpression", self.peek().token, (precedence, self.peek().token.form.precedence))
        while precedence < self.peek().token.form.precedence { // note: this disallows line breaks between operands and operator
            self.advance()
            left = try self.parseOperation(left, allowLooseArguments: allowLooseArguments)
        }
        //print("ENDED expr =", left, "now on token", self.current)
        return left
    } // important: this should always leave cursor on last token of expression
    
    // main
    
    typealias ScriptAST = Block
    
    func parseScript() throws -> ScriptAST { // ASTDocument? (see above notes about defining standard ASTNode protocols); also provide public API for parsing a single data structure (c.f. JSON deserialization)
        var result = [Value]() // TO DO: read as array of Blocks (.sentence)
        do {
            // TO DO: this is insufficient; need to handle .period/.query/.exclamation/.lineBreak terminators (maybe add a readBlock/readSentence[s] method for this)
            result += try self.readItems(until: { $0 == .endOfScript }, using: { try self.parseExpression() })
            /*
            while self.current.token.form != .endOfScript { // skip if no expressions found (i.e. whitespace and/or annotations only)
                //while self.current.token.form != .endOfScript {
                result.append(try self.parseExpression())
                //print("parseScript read expr:", result.last!, "now on", self.current.token)
                self.advance() // move to first token after expression
                switch self.current.token.form {
                case .comma: // TO DO: continue reading current sentence
                    self.advance(ignoringLineBreaks: true)
                case .period: // TO DO: `!` and `?` need associated with preceding block; `;` may also appear at end of line
                    self.advance(ignoringLineBreaks: true) // skip over period terminator and any line break
                    // TO DO: end of current sentence, so start a new one
                case .lineBreak:
                    self.advance(ignoringLineBreaks: true)
                    // end of line without punctuation is treated as end of sentence
                default:
                    print("Expected punctuation/end of line but found: \(self.current)")
                    throw BadSyntax.unterminatedExpression //SyntaxError("Expected end of line but found: \(self.current)")
                }
                //}
            }
             */
            return ScriptAST(result) // TBH, should swap this around so ScriptAST initializer takes code as argument and lexes and parses it
        } catch { // TO DO: delete once syntax errors provide decent debugging info
            print("[DEBUG] Partially parsed script:", result.map{$0.description}.joined(separator: " "))
            throw error
        }
    }
    
}

