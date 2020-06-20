//
//  expression reader.swift
//  iris-script
//


// TO DO: currently unused


import Foundation


/*
private func match(operatorDefinitions: [OperatorDefinition], to currentForm: Token.Form, precededBy previousForm: Token.Form? = nil) -> (previousTokenMatches: [PatternMatcher], currentTokenMatches: [PatternMatcher]) {
    var previousMatches = [PatternMatcher]()
    var currentMatches = [PatternMatcher]()
    for definition in operatorDefinitions {
        for matcher in definition.patternMatchers {
            // note: first pattern in matcher is reified, so it's tempting to test if it's a keyword (atom/prefix) and toggle on that; however, that won't work if it's .test (e.g. when matching argument label) so it's safest just to apply the first matcher twice: once to current token and, if that fails, to previous token (note: if keyword is a conjunction, not primary, it's never going to match here; is it worth spawning matchers for conjunctions at all? if not, how do we tighten that up?)
            
            // move this section onto matcher? (presumably pass stack.last as `previous:` arg)
            
            if matcher.match(currentForm, allowingPartialMatch: true) { // apply to current token; this matches prefix operators
                currentMatches.append(matcher)
            } else if let previous = previousForm, matcher.match(previous, allowingPartialMatch: true) { // apply to previous token (expr) and current token (opName); this matches infix operators // TO DO: this has disadvantage that it fails if first token is an unreduced expression, in which case the matcher is not attached to the infix operator - thus to re-match the operator later on we have to re-run this entire method; alternative is for matcher to special-case a leading EXPR pattern, but not sure how that'd work (e.g. might set requiresBackMatch flag on matcher when attaching it to current [operatorName] token)
                
                let matches = matcher.next().filter{ $0.match(currentForm) } // TO DO: apply this even when previous match fails(?); as long as it succeeds, put matcher in current token's stack frame, marking it as requiring backmatch
                if !matches.isEmpty { // check opname was 2nd pattern (i.e. primary keyword, not a conjunction); kludgy
                    //currentMatches += matches
                    previousMatches.append(matcher) // for now, put left expr matcher in previous frame; it'll advance back onto .operatorName when next shift(); caution: this works only inasmuch as previous token can be matched as EXPR, otherwise matcher is not attached and is lost from stack
                }
            }
        }
    }
   // print("PREV", previousMatches, "CURR", currentMatches)
    return (previousMatches, currentMatches)
}


struct StackReader: CustomStringConvertible { // rename ExpressionReader?
    
    var description: String {
        return "<#\(self.index) of \(self.stack.map{$0.token}))>"
    }
    
    let stack: ArraySlice<Parser.StackItem>
    
    let index: Int
    
    var token: Token { return self.stack[self.index].token }

    var argumentLabel: Symbol? {
        let label: Symbol?
        switch self.token.form {
        case .unquotedName(let name), .quotedName(let name):
            label = name
        case .operatorName(let defs):
            label = defs.name
        default:
            label = nil
        }
        if let name = label, case .colon = self.next().token.form {
            return name
        } else {
            return nil
        }
    }
    
    func next() -> StackReader {
        return StackReader(stack: self.stack, index: self.index + 1)
    }
}

// TO DO: fix: blockreader's no good; we need the parser's own stack as that has already-reduced values; take an ArraySlice of stack, wrap it in reader struct (or just use dropFirst?)

func skipAnnotations(_ reader: inout StackReader) {
    while case .annotation(_) = reader.token.form { reader = reader.next() }
}

// move these functions onto reader struct?


func readLabeledArguments(_ reader: StackReader, for commandName: Symbol, into arguments: [Command.Argument]) throws -> (Command, StackReader) {
    var reader = reader
    var arguments = arguments
    while let label = reader.argumentLabel {
        let (value, reader_) = try readExpr(reader.next().next(), allowLowPunctuationCommand: false)
        reader = reader_
        arguments.append((label, value))
    }
    return (Command(commandName, arguments), reader)
}

func readCommand(_ reader: StackReader, for name: Symbol, allowLowPunctuationCommand: Bool) throws -> (Value, StackReader) {
    
    let reader = reader.next() // step over command name
    print("RC", reader)
    if reader.token.isExpressionTerminator { // no argument
        return (Command(name), reader)
    } else if let label = reader.argumentLabel { // named argument
        print("  …found arg label", label)
        if allowLowPunctuationCommand {
            return try readLabeledArguments(reader.next().next(), for: name, into: [])
        } else {
            return (Command(name), reader) // inner command
        } // label terminates a nested command expr (only `CNAME` and `CNAME VALUE` are allowed as nested commands); TO DO: caller needs to associate the subsequent label with the outer command
    }
    switch reader.token.form { // direct argument
    case .value(let value):
        if let record = value as? Record { // record literal as argument // this ignores precedence and always binds record to command; any infix/postfix operators after record will receive command as LH operand
            print("readCommand found arg record:", record)
            return (Command(name, record), reader)
        } else if allowLowPunctuationCommand { // LP command allows operators within arguments, and reads argument as expr up to next label/terminator
            let (directArg, reader_) = try readExpr(reader.next(), allowLowPunctuationCommand: false) // TO DO: precedence?l
            print("readCommand found LP direct arg:", directArg)
            return try readLabeledArguments(reader_, for: name, into: [(nullSymbol, directArg)])
        } else { // nested commands require explicit punctuation for arguments
            throw BadSyntax.missingExpression // nested commands must be argument-less or use record literal for argument
        }
    case .unquotedName(let nestedName), .quotedName(let nestedName): // nested command
        let (arg, reader_) = try readCommand(reader, for: nestedName, allowLowPunctuationCommand: false)
        return (Command(name, [(nullSymbol, arg)]), reader_)
    case .operatorName(let defs):
        print("readCommand found operator:", defs.name)
        // if it's an operator name, we need to determine if op applies to argument or to command
        // we need to see if op's definition[s] start with keyword and/or expr
        // if both (e.g. `+`, `-`), we need to look at its leading and trailing whitespace to disambiguate: if both are same, use infix (i.e. command has no arg; it's left operand to operator); if it has leading ws only, use prefix (command takes prefix operation as its operand)
        // if there is no ambiguity, prefix ops apply to argument and infix/postfix ops apply to command [name]
        var prefixDefs = [OperatorDefinition](), infixDefs = [OperatorDefinition]()
        for def in defs {
            if def.hasLeadingExpression {
                infixDefs.append(def)
            } else {
                prefixDefs.append(def)
            }
        }
        // if operator is both prefix and infix/postfix (e.g. `-`), use whitespace to disambiguate (TO DO: what about atom ops? is there any practical use case where they could be infix/postfix as well? also note that keyword-based ops will tend to require whitespace on both sides; in practice, this whitespace rule is primarily to disambiguate +/- operators, and defaulting to infix is preferable as disambiguating prefix op argument is simply a matter of wrapping it in `{…}`, e.g. `foo bar baz` [infix] vs `foo {bar baz}` [prefix])
        if !prefixDefs.isEmpty && !infixDefs.isEmpty && reader.token.hasLeadingWhitespace && !reader.token.hasTrailingWhitespace { // treat as prefix (e.g. `a -1`)
            print("disambiguated", defs.name, "as prefix", reader)
            let (arg, reader) = try readAtom(reader, matchers: prefixDefs.flatMap{$0.patternMatchers}, allowLowPunctuationCommand: false)
            return (Command(name, [(nullSymbol, arg)]), reader)
        } else { // treat as infix (e.g. `a - 1`)
            print("disambiguated", defs.name, "as infix")
            return  (Command(name), reader) //try readOperation(reader, left: Command(name), precedence: argumentPrecedence, allowLowPunctuationCommand: false) // pass matchers?
        }
    default: // something else (i.e. unreduced token) after command name (e.g. [un]quotedName, operatorName, error)
        print("unreduced token after", name, "command name:", reader.token)

        throw BadSyntax.missingExpression // what error?
    }
}

//

func readAtom(_ reader: StackReader, matchers: [PatternMatcher] = [], allowLowPunctuationCommand: Bool) throws -> (Value, StackReader) { // need to return completed/progressed matches as well (i.e. if caller calls read…() with one or more matchers, it needs to know if one of those matches succeeded, at least up to next stopword)
    print("Reading atom…")
    var reader = reader
    let form = reader.token.form
    
    // what about existing matchers? if pattern is keyword, we want to match it to form here; problem is in matching EXPR; we can't do that until expr has been fully read (also, we're relying on pattern to provide stopword, e.g. in `tell…TO…`, `if…THEN…`, with extra caveat that conjunctions [stopwords] may also be primary operator names); it might be that pattern matching should only be done in outer readExpr (in which case matchers passed here would be to detect expected stopword and return control to that outer loop regardless of recursion depth)
    for matcher in matchers {
        print("readAtom matching existing:", matcher, matcher.match(form))
    }
    
    var left: Value?
    if let label = reader.argumentLabel {
        print("readAtom got label:", label) // need to decide what to do with this
        throw NotYetImplementedError()
    }
    switch form {
    case .value(let value):
        print("VALUE", value)
        left = value
        reader = reader.next()
    case .operatorName(let defs):
        print("readAtom matching op", defs.name)
        // this will start new matches of prefix ops
        let (_, newMatches) = match(operatorDefinitions: defs.definitions, to: form) // this will match atom/prefix ops only; infix ops will be discarded (since there's no previous token to back-match), and conjunctions won't match anyway
        print("…running matches for", newMatches) // this gives us an array of in-progress (prefix) and/or completed (atom) operator matchers // Q. when do we apply these matchers to next token?
        reader = reader.next()
        if newMatches.first(where: {!$0.isLongestPossibleMatch}) != nil { // one or more longer matches must/may be made, so attempt those
            print("Looking for longer match…")
            let (value, reader_) = try readAtom(reader, matchers: newMatches, allowLowPunctuationCommand: false) // allow LP?
            print("…read", newMatches, "=", value, reader_)
            left = value
            reader = reader_
        } else {
            assert(!newMatches.isEmpty)
            
            if newMatches.count > 1 {
                print("Reduce conflict on:", defs)
                throw NotYetImplementedError()
            }
            //newMatches
        }
    case .unquotedName(let name), .quotedName(let name):
        print("COMMAND", name)
        let (command, reader_) = try readCommand(reader, for: name, allowLowPunctuationCommand: allowLowPunctuationCommand)
        left = command
        reader = reader_
    default:
        print("OTHER", form) // linebreaks, punctuation, errors; what else?
        reader = reader.next()
        // note: this should not be delimiter when readExpr is first called (it could be an .error)
    }
    
    return (left ?? nullValue, reader) // TO DO: what to return?
}

func readOperation(_ reader: StackReader, left: Value, precedence: Precedence, matchers: [PatternMatcher] = [], allowLowPunctuationCommand: Bool) throws -> (Value, StackReader) {
    print("Reading operation… (LH: \(left))")
    switch reader.token.form {
    case .operatorName(let defs):
        print("readOp found opname:", defs.name)
    default:
        ()
    }
    return (42, reader)
}

func readExpr(_ reader: StackReader, matcher: PatternMatcher? = nil, precedence: Precedence = 0, allowLowPunctuationCommand: Bool = false) throws -> (Value, StackReader) { // TO DO: also needs to return reader (should this be for last consumed or first unconsumed token; for now, let's go with first unconsumed)
    print("Reading expr…", reader)
    var reader = reader
    skipAnnotations(&reader)
    //var form = reader.token.form
    
    var (left, reader_) = try readAtom(reader, allowLowPunctuationCommand: allowLowPunctuationCommand)
    reader = reader_
    
    print("LH:", left as Any)
    print(reader)
    //reader = reader.next()
    //form = reader.token.form
    
    print("…read.")
    return (left, reader)
}



enum ExpressionTerminator {
    case other // expr separator, end of list/record/group, or linebreak
    case label(Symbol) // if expression is an argument value in LP command
    case stopword(Symbol) // if expression is an operand that appears before an expected conjunction
}


// foo a: 1 + b c: 2 // this is problematic; is `1+b` argument to `foo{a:c:}`, or does `+` apply to `foo{a:1}` and `b{c:2}`? and what if we rewrite as `foo a: b + 1 c: 2`? if `+` is lower precedence than cmd arg (which it needs to be, along with most other operators except for chunk exprs)
// foo a: (1 + b) c: 2 // is this the interpretation we want?
// foo {a: 1 + b, c: 2} // Full-Punctuation syntax
// foo {a: 1 + b {c: 2}} // wrong interpretation (nested commands require record arg/no arg); note that FP flag needs to propagate through some operators, e.g. `+`, but not others, e.g. `do…done` - maybe set LP/FP flag per-line?


// TO DO: for `to NAME:ACTION` to parse, stopwords need to be punctuation as well as keywords

func parseExpr(_ reader: StackReader, stopwords: [Symbol] = [], matcher: PatternMatcher? = nil, precedence: Precedence = 0, allowLowPunctuationCommand: Bool = false) throws -> (ExpressionTerminator, Value, StackReader) {
    let form = reader.token.form
    var reader = reader.next() // step over this token
    switch form {
    case .unquotedName(let name), .quotedName(let name):
        print("parseExpr read command name:", name)
        if case .colon = reader.token.form { // token is start of labeled argument from parent command (or it may be the start of a top-level `name:value` binding) // TO DO: this'll also match colon in `to name:action` (Q. what are rules for allowing/disallowing LP commands?)
            return (.label(name), 0, reader.next()) // step over colon
        } else if reader.token.isExpressionTerminator {
            return (.other, Command(name), reader)
        } else if let label = reader.argumentLabel { // name is followed by LP labeled argument
            reader = reader.next().next() // step over label’s name and colon
            if allowLowPunctuationCommand { // labeled arg belongs to this command
                // read labeled args
                print("TODO: read labeled args", name, label, reader)
                
            } else { // LP argument label acts as expression terminator for preceding argument value (in this case, a nested arg-less command)
                return (.label(label), Command(name), reader) // nested arg-less command, so step over label and return
            }
        } else if case .value(let value) = reader.token.form { // command name is followed by direct argument
            if let record = value as? Record { // argument is record literal, which always binds to command name as FP args
                // not sure about returning here; what if there's an infix/postfix operator after command?
                return (.other, Command(name, record.fields), reader.next()) // step over record
            } else {
                print("TODO: read direct arg", name, reader)
                
                //let (status, value, reader_) = parseExpr(reader)
                
            }
        } else {
            // what else can appear after cmd name? .error, another command
        }
    case .operatorName(let defs):
        if stopwords.contains(defs.name) { // TO DO: what about pattern matchers?
            return (.stopword(defs.name), nullValue, reader)
        } else if case .colon = reader.token.form { // TO DO: as above
            return (.label(defs.name), nullValue, reader.next())
        }
        print("parseExpr read operator name:", defs.name)
        for matcher in defs.patternMatchers {
            if matcher.match(reader.token.form) {
                if matcher.isAFullMatch {
                    
                } else {
                    
                }
            }
        }
    default: ()
    }
    return (.other, nullValue, reader)
}
*/
