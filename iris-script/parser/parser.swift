//
//  parser.swift
//  iris-script
//


// TO DO: need smarter handling of missing colons on command labels (an easy user error), e.g. `set x to y` instead of `set x to: y` (right now it just dumps out of parseExpression with unhelpful error message)

// TO DO: how to read blocks with custom delimiters, e.g. `do…done`? (not worth sweating it for POC implementation; just use custom operator parsefunc)

// TO DO: how to deal with terminator punctuation (`.?!`)? also, what should be syntax rules for using terminator punctuation at end of list/record items? e.g. `(Foo, bar! Baz)` is perfectly legal (being a group of two sentences), but should `[foo, bar! baz]` require explicit parenthesization to avoid any ambiguity on where each list item begins and ends, e.g. `[foo, (bar!), baz]` or `[(foo, bar!), baz]`

// should `tell`, `if`, `while` operators use `tell EXPR to EXPR`, `if EXPR then EXPR`, `while EXPR repeat EXPR` syntax? Q. what word should separate operands in `to`/`when`, e.g. `to perform_action {…} returning TYPE XXXX do … done.`

// one more possibility for `tell`, `if`, etc: define them as prefix operators, and require comma separator between first and second operands; thus: `tell app "TextEdit", make new: #document.`, `if some_condition, do…done.`; this should read more naturally for `to`/`when` operators: `to perform_action {…} returning TYPE, do … done.`; OTOH, it doesn't read as well for `tell` which benefits from the pronouncable `to` preposition.

// TO DO: pass Bool flag to parseOperation to indicate only current sentence should be read? (i.e. `if TEST …` should only read up to first `.?!` or first linebreak not preceded by comma/semicolon, assuming no explicit block delimiters.)

// TO DO: need to watch out for parensed Pairs in records (e.g. when passing lambdas)


import Foundation

// nasty hacky duct-taped temp code (recursive descent Pratt Parser class taken from sylvia-lang, hacked up to support iris syntax); not what we want (which is non-recursive table-driven bottom-up incremental parsing) but will do as stopgap for sake of getting language up and running


// if test: expr -- TO DO: assuming `if` is a command, `test: expr` looks like a labeled argument, rather than an unlabeled pair argument (OTOH, this shouldn't be an issue as long as `if` is an operator, as operands do not have labels)


// TO DO: need to finalize association rules for low-punctuation commands; given that 'variables' (i.e. arg-less commands) may frequently appear as arguments it may be preferable to bind trailing args to the outermost command; e.g. `foo bar baz: fub` -> `foo (bar) baz: fub` = `foo {bar, baz: fub}`, rather than most recent (`foo {bar {baz: fub}}`); the allowLooseArguments flag should produce this result, but needs some real-world usage tests to confirm it's the right choice

// TO DO: also need decision on `foo {…} bar: baz`; while it can be inferred that record is first [direct] arg value, problem here is that treating the record as first arg value is inconsistent with `foo {…}`, so may be cleaner to treat it as syntax error

// TO DO: we also need to nail down singular vs plural use of 'argument[s]' and 'parameter[s]' - while the internal implementation is closer to the traditional name coupled to N-ary tuple, we describe commands as unary prefix operators whose operand is always a record (if omitted, an empty record is inferred)


// commas bind tighter than `if`, `to`, `while`, etc; `if`, `while`, etc binds tighter than `else`; Q. if commas bind tighter than `if`, that makes `if` a unary prefix operator that takes at minimum two comma-separated exprs (the first expr is the test to perform; remaining exprs are the action to perform if the test succeeds); note that when `if` appears inside a comma sequence, it will want to take the rest of the sequence for itself (longest match). Q. can/should we use same binding rule here as in lp commands, where being directly inside a comma-delimited sequence switches the nested `if` to use shortest match? (otoh, if `if` is preceded a by linebreak without a preceding comma [or semicolon], it'll use longest match [i.e. a linebreak without a preceding comma is treated as sentence terminator, same as with `.?!`]; this clearly needs more thought as a small variation in punctuation will produce a large variation in behavior; aka the “eats, shoots, and leaves” dilemma)


enum AllowSequence {
    case no
    case sentence
    case elements
    case yes
    
    
    func isDisallowed(_ token: Token) -> Bool {
        switch self {
        case .no: return [.lineBreak, .comma, .period, .query, .exclamation].contains(token.form)
        case .sentence: return [.lineBreak, .period, .query, .exclamation].contains(token.form) // .comma is allowed in sentence
        case .elements: return [.period, .query, .exclamation].contains(token.form) // .lineBreak, .comma are allowed in lists/records
        case .yes: return false
        }
    }
}


typealias ScriptAST = Block


internal class ExpressionSequence: Value { // internal collector for two or more comma- and/or linebreak-separated items
    
    var description: String { return "<\(type(of: self)) \(self.items)>" }
    
    var nominalType: Coercion = asValue // ExpressionSequence is used inside Parser only

    private(set) var items = [Value]()
    private(set) var dictionary = KeyedList.SwiftType()// in keyed list, this must equal items.count; in ordered list this must be zero
    
    // TO DO: also need to record separators (in records and lists, we need to confirm all items are delimited by comma and/or linebreak; in blocks, we need to account for `.?!` as well)
    
    private(set) var labelCount = 0 // in record or block, this must equal count
    private(set) var otherCount = 0 // this should always be zero (but see TODO below about enforcing it as grammar)
    
    init(_ item: Value) {
        self.items.append(item)
    }
    
    func append(_ item: Value) {
        // TO DO: need to keep tally of Pairs; also need to decide how Pair.eval() behaves (since Pairs should only appear in blocks)
        self.items.append(item)
        if let pair = item as? Pair {
            if let key = pair.key as? Symbol { // kludgy as parser encodes record field labels as Symbols
                self.labelCount += 1
                self.dictionary[key.dictionaryKey] = pair.value
            } else if let key = pair.key as? HashableValue {
                self.dictionary[key.dictionaryKey] = pair.value
            } else {
                self.otherCount += 1 // TO DO: this can go away if parser enforces Pair keys as HashableValue (KeyedList keys) or .[un]quotedName (record fields); except we also want Pair keys to be HandlerInterface when used in `to` operator; where else might pairs be used?
            }
        }
    }
    
    func append(_ punctuation: Token.Form) { // .comma, .period, .exclamation, .query, .lineBreak (note that `.comma .lineBreak*` is recorded as `.comma`; not sure if we should record comma+lineBreak[s] as a distinct separator)
        //print("append \(punctuation)")
        // TO DO: how best to annotate? (this is mostly for use in preserving Block punctuation, where `.?!` punctuation may mediate evaluation [e.g. requesting user confirmation/suppressing all warnings on potentially destructive operations, or controlling stepping granularity in debug mode (pause on each expr vs pause at start/end of each sentence)], though we should also confirm that lists and records are properly punctuated [i.e. leery of allowing `.?!` to appear as list item/record field separators])
    }
    
}



class Parser {
    
    let operatorRegistry: OperatorRegistry
    private(set) var current: BlockReader
    private var annotations = [Token]() // TO DO: parser needs to bind extracted annotations to AST nodes automatically (this may be easier once TokenInfo includes line numbers)
    
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
    
    func readList() throws -> Value { // start on '['
        assert(self.current.token.form == .startList)
        let value: Value
        switch self.peek().token.form {
        case .endList:
            self.advance(ignoringLineBreaks: true)
            value = OrderedList()
        case .colon:
            self.advance(ignoringLineBreaks: true)
            self.advance(ignoringLineBreaks: true)
            if self.current.token.form != .endList { throw BadSyntax.missingExpression }
            value = KeyedList()
        default:
            self.advance(ignoringLineBreaks: true) // step over `[`
            // TO DO: parseExpression->parseAtom fails on `.startList … .lineBreak .endList`
            let content = try self._parseExpression(allowLooseSequences: .elements)
            if let content = content as? ExpressionSequence {
                if content.otherCount > 0 { throw UnsupportedCoercionError(value: content, coercion: asList) }
                // TO DO: one problem here is that KeyedList won't preserve key order [unless Swift Dictionary preserves key order], which is a pain for pretty-printing; one option is to capture ordered items as well (though this'll require an extended version of KeyedList struct)
                // TO DO: there are also issues over parenthesized pairs not being treated as items in OrderedList (since parser doesn't currently annotate values with parens); however, we've yet to decide to what extent Pair is used within parser vs exposed as a runtime value
                if content.dictionary.count == 0 {
                    value = OrderedList(content.items)
                } else if content.dictionary.count == content.items.count {
                    value = KeyedList(content.dictionary)
                } else {
                    throw UnsupportedCoercionError(value: content, coercion: asList)
                }
            } else {
                if let pair = content as? Pair {
                    guard let key = pair.key as? HashableValue else {
                        throw UnsupportedCoercionError(value: pair.key, coercion: asHashableValue)
                    }
                    value = KeyedList([key.dictionaryKey: pair.value])
                } else {
                    value = OrderedList([content])
                }
            }
            self.advance(ignoringLineBreaks: true) // step onto `]`
            guard case .endList = self.current.token.form else { throw BadSyntax.unterminatedList } //SyntaxError("Expected expression or end of block but found: \(self.current)") }
        }
        assert(self.current.token.form == .endList)
        return value // end on ']'
    }
    
    func readField(_ content: Value) throws -> Record.Field { // used by readRecord()
        if let pair = content as? Pair {
            guard let key = pair.key as? Command, key.arguments.isEmpty else { throw BadSyntax.missingName } // parser has already reduced field name to Command
            return (key.name, pair.value)
        } else {
            return (nullSymbol, content)
        }
    }
    
    func readRecord() throws -> Record { // start on '{'
        assert(self.current.token.form == .startRecord)
        let value: Record
        self.advance(ignoringLineBreaks: true) // step over `{`
        switch self.current.token.form {
        case .endRecord: // `}`
            value = Record()
        default:
            let fields: [Record.Field]
            let content = try self._parseExpression(allowLooseSequences: .elements)
            if let content = content as? ExpressionSequence {
                fields = try content.items.map(self.readField)
            } else {
                fields = [try self.readField(content)]
            }
            value = try Record(fields)
            self.advance(ignoringLineBreaks: true) // advance onto `}`
        }
        assert(self.current.token.form == .endRecord)
        return value // end on '}'
    }
    
    
    func readLabel() -> Symbol? { // used by readCommand() when reading low-punctuation commands (Q. how hard to tighten `Pair` behavior and get rid of this)
        let name: String
        // TO DO: replace isName with Token.identifier->String?
        if self.current.token.isName && self.current.token.isRightContiguous && self.peek().token.form == .colon {
            switch self.current.token.form {
            case .quotedName(let s):   name = s
            case .unquotedName(let s): name = s
            default:                   name = String(self.current.token.content)
            }
        } else if case .operatorName(_) = self.current.token.form, self.peek().token.form == .colon { // self.current.token.isRightContiguous // TO DO: not sure about contiguous checking; any whitespace before colon can be discarded by PP, but colon's meaning should stay the same, otherwise we're going to get some surprising parsing behavior (alternatively, we straight-up reject `whitespace .colon` as syntax error, but that seems excessive) // TO DO: do we need this? (OperatorReader )
            name = String(self.current.token.content)
        } else {
            return nil
        }
        self.advance() // step over name
        self.advance() // step over colon
        return Symbol(name)
    }
    
    func readArgumentValue() throws -> Value {
        // TO DO: allowLooseSequences is redundant as `argumentPrecedence` > punctuation
        // note: argumentPrecedence is also higher than colon; how should Pair syntax parse?
        return try self.parseExpression(argumentPrecedence, allowLooseArguments: false, allowLooseSequences: .no)
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
        //print("reading args for command `\(name)`", allowLooseArguments)
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
                    arguments.append((label, try self.readArgumentValue()))
                } else {
                    arguments.append((nullSymbol, try self.readArgumentValue()))
                }
                //print("read first arg:", arguments)
                while !self.peek().token.isRightDelimiter {
                    //if case .operatorName(_) = self.peek().token.form { break }
                    self.advance()
                    guard let label = self.readLabel() else {
                        print("expected label in \(name) command but found", self.current.token); throw BadSyntax.missingName }
                    arguments.append((label, try self.readArgumentValue()))
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
        case .startRecord:    // `{…}`
            value = try self.readRecord()
        case .startGroup:     // `(…)`
            self.advance(ignoringLineBreaks: true) // step over '('
            value = try self.parseExpression() // this allows any punctuation // TO DO: annotate value to preserve elective parens when pretty printing (there's also the question of how to treat `[(1:2)]` - as OrderedList of Pairs or as syntax error? currently the parens are ignored and a KeyedList is built)
            
            self.advance(ignoringLineBreaks: true) // step onto ')'
            guard case .endGroup = self.current.token.form else { throw BadSyntax.unterminatedGroup } //SyntaxError("Expected end of precedence group, “)”, but found: \(self.this)") }
        
        case .letters, .symbols, .quotedName(_), .unquotedName(_): // found `NAME`/`'NAME'`
            // TO DO: reading reverse domain names with optional `@` prefix, e.g. `com.example.foo`, is probably best done by a LineReader adapter; question is whether we should generalize this to allow commands with arguments within/at end
            value = try self.readCommand(allowLooseArguments)
        case .operatorName(let operatorClass) where !operatorClass.hasLeftOperand: // atom/prefix operator
            if let definition = operatorClass.custom, case .custom(let parseFunc) = definition.form {
                value = try parseFunc(self, definition, nil, allowLooseArguments) // , allowLooseSequences: allowLooseSequences?
            } else if self.peek().token.isRightDelimiter {
                guard let definition = operatorClass.atom else { throw BadSyntax.missingExpression } // TO DO: if right-contiguous and next token is colon, then value should be label
                value = Command(definition)
            } else {
                guard let definition = operatorClass.prefix else {
                    print("parseAtom bad operator:", operatorClass);
                    throw BadSyntax.unterminatedExpression }
                self.advance() // step over operator name to read right-hand operand
                value = Command(definition, right: try self.parseExpression(definition.precedence, allowLooseArguments: allowLooseArguments, allowLooseSequences: .no)) // comma, period, etc marks end of argument fields
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
            // TO DO: should `@` bind to a single quoted/unquoted name, or to a complete URI
            throw NotYetImplementedError()
        case .endOfScript:
            print("Expected an expression but found end of code instead.")
            throw BadSyntax.missingExpression //SyntaxError("Expected an expression but found end of code instead.")
        default:
            print("parseAtom Expected an expression but found \(token)")
            throw BadSyntax.missingExpression //SyntaxError("Expected an expression but found \(token)")
        }
        //value.annotations[codeAnnotation] = CodeRange(start: tokenInfo.start, end: self.current.end)
        //print("ENDED parseAtom", value)
        return value
    } // important: this should always leave cursor on last token of expression
    
    
    // propagate allowLooseArguments through operators too (e.g. `duplicate document at 1 of documents to: end of documents`); only parens/brackets/braces should discard this flag
    private func parseOperation(_ leftExpr: Value, allowLooseArguments: Bool = true, allowLooseSequences: AllowSequence = .yes) throws -> Value {
        let tokenInfo = self.current
//        print("BEGIN parseOperation", tokenInfo)
        let token = tokenInfo.token
        let value: Value
        switch token.form {
        case .operatorName(let operatorClass) where operatorClass.hasLeftOperand: // TO DO: what errors if operator not found?
            let nextToken = self.peek().token
            if let definition = operatorClass.custom, case .custom(let parseFunc) = definition.form {
                value = try parseFunc(self, definition, leftExpr, allowLooseArguments)
            } else if nextToken.isRightDelimiter { // no right operand, so current token needs to be a postfix operator
                assert(!(nextToken.form == .colon)) // OperatorReader should never match a name followed by a colon as an operator name
                guard let definition = operatorClass.postfix else {
                    print("expected right-hand operand for:", operatorClass, "but found", nextToken.form) // TO DO: fix error message
                    throw BadSyntax.unterminatedExpression
                }
                value = Command(definition, left: leftExpr)
            } else { // infix operator
                guard let definition = operatorClass.infix else {
                    print("expected delimiter after:", operatorClass, "but found", nextToken.form) // TO DO: fix error message
                    throw BadSyntax.unterminatedExpression
                }
                self.advance() // step over operator name to read right-hand operand
                let precedence = definition.associativity == .right ? definition.precedence - 1 : definition.precedence
                value = Command(definition, left: leftExpr, right: try self.parseExpression(precedence, allowLooseArguments: allowLooseArguments, allowLooseSequences: .no))
            }
        case .colon:
            self.advance(ignoringLineBreaks: true) // skip over ":"
            // if right-side of pair can be a comma-delimited sequence, we need to reduce the colon's precedence below comma's
            let precedence = [.yes, .sentence].contains(allowLooseSequences) ? Token.Form.comma.precedence - 10 : token.form.precedence - 1
            value = Pair(leftExpr, try self.parseExpression(precedence, allowLooseArguments: true, allowLooseSequences: allowLooseSequences)) // TO DO: where can Pair occur? keyed list, block (assignment shorthand) // TO DO: what should allowLooseSequences be? (.no?)
        case .semicolon:
            let precedence = token.form.precedence
            self.advance(ignoringLineBreaks: true) // skip over ";"
            let rightExpr = try self.parseExpression(precedence, allowLooseSequences: .no) // TO DO: allowLooseSequences?
            guard let command = rightExpr as? Command else {
                print(leftExpr, rightExpr)
                throw UnsupportedCoercionError(value: rightExpr, coercion: asCommand)
            } // TO DO: what error?
            value = Command(command.name, [(nullSymbol, leftExpr)] + command.arguments)
            // TO DO: annotate command for pp; i.e. `B {A, C}` should print as `A; B {C}`
            
        case .comma, .lineBreak, .period, .exclamation, .query:
            let form = self.current.token.form
            let builder = (leftExpr as? ExpressionSequence) ?? ExpressionSequence(leftExpr) // this is only place ExprSeq is instantiated; Q. if parseDoBlock was to create its own ExprSeq-like collector that halts on receiving `done`?
            builder.append(form)
            if self.peek(ignoringLineBreaks: true).token.isEndOfSequence { return leftExpr }
            self.advance(ignoringLineBreaks: true)
            builder.append(try self.parseExpression(form.precedence, allowLooseSequences: allowLooseSequences))
            value = builder
            //print("parseOperation got sequence:", builder)
            // TO DO: `if [.yes, .sentence].contains(allowLooseSequences)` we need to convert ExprSeq to Block; problem is we can't do it until recursive parseExpression has finished unspooling
        case .endOfScript:
            print("Expected an operand after the following code but found end of code instead: \(leftExpr)")
            throw BadSyntax.missingExpression //SyntaxError("Expected an operand after the following code but found end of code instead: \(leftExpr)")
        default:
            print("Invalid token after leftExpr `\(leftExpr)`: \(token)")
            throw BadSyntax.missingExpression//SyntaxError("Invalid token after \(leftExpr): \(token)")
        }
        //print("ENDED parseOperation", value)
        return value
    } // important: this should always leave cursor on last token of expression
    
    
    
    func _parseExpression(_ precedence: Precedence = 0, allowLooseArguments: Bool = true, allowLooseSequences: AllowSequence = .yes) throws -> Value {
//        print("BEGIN expr", self.current.token, precedence)
        if self.current.token.form == .endOfScript { print("parseExpression started on .endScript"); return nullValue } // TO DO: can this still happen?
        var left = try self.parseAtom(allowLooseArguments)
//        print("LEFT", left, precedence, self.peek().token)
        //print("parseExpression", self.peek().token, (precedence, self.peek().token.form.precedence))
        while precedence < self.peek().token.form.precedence && !allowLooseSequences.isDisallowed(self.peek().token) { // note: this disallows line breaks between operands and operator (Q. do we need to change this there's when adjoining punctuation?)
            self.advance()
            left = try self.parseOperation(left, allowLooseArguments: allowLooseArguments, allowLooseSequences: allowLooseSequences)
        }
//        print("ENDED expr", self.current.token, "result =", left, (precedence, self.peek().token.form.precedence))
        return left
    } // important: this should always leave cursor on last token of expression
    
    func parseExpression(_ precedence: Precedence = 0, allowLooseArguments: Bool = true, allowLooseSequences: AllowSequence = .yes) throws -> Value {
        let expr = try self._parseExpression(precedence, allowLooseArguments: allowLooseArguments, allowLooseSequences: allowLooseSequences)
        if let seq = expr as? ExpressionSequence {
            return Block(seq.items) //, style: .sentence(terminator: Token(.period, nil, ".", " ", .last)))
        }
        return expr
    }
    
    // main
    
    func parseScript() throws -> ScriptAST { // ASTDocument? (see above notes about defining standard ASTNode protocols); also provide public API for parsing a single data structure (c.f. JSON deserialization)
        var result: Value = nullValue
        do {
            result = try self._parseExpression()
            if case .lineBreak = self.current.token.form { self.advance(ignoringLineBreaks: true) }
            assert(self.current.token.form == .endOfScript, "Expected end of script but found \(self.current.token) then \(self.peek().token)")
            let exprSeq: [Value]
            if let builder = result as? ExpressionSequence {
                exprSeq = builder.items
            } else {
                exprSeq = [result]
            }
            return ScriptAST(exprSeq) // TBH, should swap this around so ScriptAST initializer takes code as argument and lexes and parses it
        } catch { // TO DO: delete once syntax errors provide decent debugging info
            print("[DEBUG] Partially parsed script:", result)
            throw error
        }
    }
    
}

