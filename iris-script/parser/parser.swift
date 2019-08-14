//
//  parser.swift
//  iris-script
//

// TO DO: need to formalize delimiter rules (punctuation/linebreaks/operator names/quotes)


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
                    guard let pair = item as? Pair else { throw UnsupportedCoercionError(value: item, coercion: asPair) }
                    guard let key = (pair.key as? HashableValue)?.hashKey else {
                        throw UnsupportedCoercionError(value: pair.key, coercion: asHashableValue)
                    }
                    dict[key] = pair.value
                case .undetermined:
                    if let pair = item as? Pair {
                        guard let key = (pair.key as? HashableValue)?.hashKey else {
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
            let item = try self.parseExpression()
            guard let pair = item as? Pair else { return (nullSymbol, item) }
            guard let key = pair.key as? Symbol else { throw UnsupportedCoercionError(value: pair.key, coercion: asSymbol) }
            return (key, pair.value)
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
            throw BadSyntax.unterminatedList //("Unexpected token after item \(items.count) of list: \(self.current)")
        }
        return items // finish on ')'/']'
    }
    
    func readLabel() -> Symbol? {
        if self.current.token.isName && self.current.token.isRightContiguous && self.peek().token.form == .colon {
            let name: String
            switch self.current.token.form {
            case .quotedName(let s): name = s
            default:                 name = String(self.current.token.content)
            }
            self.advance() // step over name
            self.advance() // step over colon
            return Symbol(name)
        } else {
            return nil
        }
    }
    
    func readCommand(_ allowLooseArguments: Bool) throws -> Command { // cursor is on first token on command (i.e. its name)
        // peek ahead: if next token is `{`, read arguments record; if next token is expr sep punctuation/linebreak/eof or infix/postfix op, command has no args; otherwise read low-punctuation arg[s] as exprs - first arg may be Pair or Value; subsequent args must be Pairs with label keys
        let name: String
        var arguments: [Command.Argument]
        if case .quotedName(let s) = self.current.token.form {
            name = s
        } else {
            name = String(self.current.token.content)
        }
        let next = self.peek().token
        if next.isRightDelimiter { // no argument
            arguments = []
        } else if case .startRecord = next.form { // explicit record argument; this always binds to command name
            self.advance()
            arguments = try self.readRecord().fields
        } else if allowLooseArguments { // low-punctuation command; first field may be unlabeled, subsequent fields must be labeled
            arguments = [Command.Argument]()
            self.advance()
            if let label = self.readLabel() {
                arguments.append((label, try self.parseExpression(argumentPrecedence, allowLooseArguments: false))) // TO DO: precedence?
            } else {
                arguments.append((nullSymbol, try self.parseExpression(argumentPrecedence, allowLooseArguments: false)))
            }
            //print("read first arg:", arguments)
            while !self.peek().token.isRightDelimiter {
                self.advance()
                guard let label = self.readLabel() else { throw BadSyntax.missingName }
                arguments.append((label, try self.parseExpression(argumentPrecedence, allowLooseArguments: false)))
                //print("read labeled arg:", arguments)
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
            self.advance(ignoringLineBreaks: true) // step over '('
            value = try self.parseExpression()
            // TO DO: need to annotate value in order to preserve elective parens when pretty printing; also to determine if a list literal represents a table or a list of arbitrary pairs (e.g. ["foo":1] = Record, [("foo":1)] = List)
            self.advance(ignoringLineBreaks: true) // step over ')'
            guard case .endGroup = self.current.token.form else { throw BadSyntax.unterminatedGroup } //SyntaxError("Expected end of precedence group, “)”, but found: \(self.this)") }
        case .letters, .symbols, .quotedName(_): // found `NAME`/`'NAME'`
            // TO DO: reading reverse domain names with optional `@` prefix, e.g. `com.example.foo`, is probably best done by a LineReader adapter; question is whether we should generalize this to allow commands with arguments within/at end
            value = try self.readCommand(allowLooseArguments)
        case .operatorName(let operatorClass) where !operatorClass.hasLeftOperand: // atom/prefix operator
            if self.peek().token.isRightDelimiter {
                guard let definition = operatorClass.atom else { throw BadSyntax.missingExpression }
                value = Command(definition)
            } else {
                guard let definition = operatorClass.prefix else { throw BadSyntax.unterminatedExpression }
                self.advance() // step over operator name to read right-hand operand
                value = Command(definition, right: try self.parseExpression(definition.precedence))
            }
        case .hash:
            if self.current.token.hasTrailingWhitespace { throw BadSyntax.missingName }
            self.advance(ignoringLineBreaks: true) // step over '#'
            switch self.current.token.form {
            case .letters, .symbols:    value = Symbol(String(self.current.token.content))
            case .quotedName(let name): value = Symbol(name)
            default:                    throw BadSyntax.missingName
            }
            throw NotYetImplementedError()
        case .at:
            if self.current.token.hasTrailingWhitespace { throw BadSyntax.missingName }
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
    
    private func parseOperation(_ leftExpr: Value) throws -> Value {
        let tokenInfo = self.current
        //print("BEGIN parseOperation", tokenInfo)
        let token = tokenInfo.token
        let value: Value
        switch token.form {
        case .operatorName(let operatorClass) where operatorClass.hasLeftOperand: // TO DO: what errors if operator not found?
            if self.peek().token.isRightDelimiter { // postfix operator
                guard let definition = operatorClass.postfix else { throw BadSyntax.unterminatedExpression }
                value = Command(definition, left: leftExpr)
            } else { // infix operator
                guard let definition = operatorClass.infix else { throw BadSyntax.unterminatedExpression }
                self.advance() // step over operator name to read right-hand operand
                value = Command(definition, left: leftExpr, right: try self.parseExpression(definition.precedence))
            }
        case .colon:
            self.advance(ignoringLineBreaks: true) // skip over ":"
            value = Pair(leftExpr, try self.parseExpression(token.form.precedence - 1)) // pairs are right-associative
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
            print("Invalid token after \(leftExpr): \(token)")
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
            left = try self.parseOperation(left)
        }
        //print("ENDED expr =", left, "now on token", self.current)
        return left
    } // important: this should always leave cursor on last token of expression
    
    // main
    
    typealias ScriptAST = Block
    
    func parseScript() throws -> ScriptAST { // ASTDocument? (see above notes about defining standard ASTNode protocols); also provide public API for parsing a single data structure (c.f. JSON deserialization)
        var result = [Value]() // TO DO: read as array of Blocks (.sentence)
        do {
            while self.current.token.form != .endOfScript { // skip if no expressions found (i.e. whitespace and/or annotations only)
                //while self.current.token.form != .endOfScript {
                result.append(try self.parseExpression())
                print("parseScript read expr:", result.last!, "now on", self.current.token)
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
            return ScriptAST(result) // TBH, should swap this around so ScriptAST initializer takes code as argument and lexes and parses it
        } catch { // TO DO: delete once syntax errors provide decent debugging info
            print("[DEBUG] Partially parsed script:", result.map{$0.description}.joined(separator: " "))
            throw error
        }
    }
    
}

