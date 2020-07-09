//
//  match and reduce.swift
//  iris-script
//

import Foundation

// nested commands accept an optional record or direct value argument but no LP labeled args; thus they are always terminated by a label (which is then added to outer command); where a nested command is followed by infix/postfix operator, if the operator’s precedence is greater than commandPrecedence it takes the innermost command as its left operand (this terminates the innermost command), otherwise it takes the outermost command (this terminates all commands); users can still disambiguate/override by parenthesizing, of course, e.g.:
//    `foo bar of baz` -> `foo {bar of baz}`
//    `foo bar + baz` -> `(foo {bar}) + baz`
//    `(foo bar) of baz` -> `(foo {bar}) of baz`
//    `foo (bar + baz)` -> `foo {bar + baz}`
// this means that nested commands can be matched by a simple `NAME EXPR?` operator pattern, which is added in reduceLowPunctuationCommand’s argument loop and reduced by reduceOperatorExpression() // TO DO: don't think this is currently the case



extension Parser {
    
    // called by reduceLowPunctuationCommand() after reducing argument expression
    func argument(_ label: Symbol, of commandName: Symbol, at index: Int) -> Value {
        let form = self.tokenStack[index].form
        let value: Value
        switch form {
        case .value(let v): value = v
        default: value = SyntaxErrorDescription("The \(commandName.label) command’s \(label.isEmpty ? "direct" : label.label) argument did not fully reduce: .\(form)\n")
        }
        return value
    }
    
    
    
    func matchNestedCommand(from startIndex: Int, to stopIndex: Int) {
        // called by reduceLowPunctuationCommand() when a nested command is encountered; this allows reduceOperatorExpression() to reduce the nested command (which may or may not have a direct argument) as an atomic/prefix operator of commandPrecedence
        // caution: caller is responsible for ensuring Parser.stack[index] is an .[un]quotedName(…) as we don't bother to re-match it here before adding the command matchers to it
        let matchers = nestedCommandLiteral.newMatches(groupID: OperatorDefinitions.newGroupID())
        self.tokenStack[startIndex].matches += matchers
        if startIndex + 1 < stopIndex { // if there's more tokens after the name
            // advance the command matchers and try to match the [start of its] direct argument EXPR (if it has one)
            let matchers = matchers.flatMap{ $0.next() }
            let form = self.tokenStack[startIndex+1].form
            self.tokenStack[startIndex+1].matches += matchers.filter{ $0.provisionallyMatches(form: form) }
        }
    }
    
    
    func reduceLowPunctuationCommand(from startIndex: Int, to stopIndex: inout Int) { // startIndex..<stopIndex
        // reads, reduces, and returns the *first* low-punctuation command found the given range (e.g. a [presumably] complete, unreduced expression delimited at start and end by linebreaks/punctuation); this includes reading any nested commands in its arguments and reducing those argument tokens down to argument values in the final Command; on return, commandTokens is partly/fully consumed and the new stopIndex is given: the caller is responsible for invoking again if there are any command names remaining in commandTokens
        // startIndex is stack index of the LP command's name, which we've already matched; stopIndex is the index at which the entire expression containing this command ends; the result is the parsed Command and the index at which it actually ended
        let commandName = self.tokenStack[startIndex].form.asCommandName()!
        // (note that because LP commands are self-delimiting on left side but not right, we must read commands left-to-right in order to determine what is an outer command vs nested command; additionally, we have to identify the start and end of each LP command and its arity before we can start to reduce operators by precedence; hence the departure from the usual right-to-left matching and reduction of a shift-reduce parser, which always operates from the head of the stack)
        //      print("Found command name:", commandName, "at:", startIndex)
        // note: where the command name is followed by a record literal, the command *always* binds the record as FP argument syntax; if that record is followed by a label that should be treated as a syntax error (i.e. if the direct argument to a command is itself a record literal, either use FP syntax or wrap the record in parens to disambiguate; while there isn't a way around this limitation, in practical use a post-parse linter should be  able to look up or guess most commands’ handlers and compare argument labels and types to detect many (though not all) likely syntax errors of this type and suggest corrections)
       // print("READ COMMAND", commandName)
        var index = startIndex + 1 // start index is initially the command name, so step over that and look for a direct argument, e.g. `foo 1 …`
        if index == stopIndex {
            self.tokenStack[startIndex].form = .value(Command(commandName))
            //print("…No arguments.")
            return
        } // command *cannot* have any arguments, so return now
        var arguments = [Command.Argument]()
        var argumentLabel = nullSymbol // nullSymbol = direct argument, if there is one
        if case .label(let name) = self.tokenStack[index].form { // command has no direct argument, e.g. `foo bar: expr …`
            index += 1 // step over label to the argument expression
            argumentLabel = name
            //print("…No direct argument")
        } else if case .operatorName(let d) = self.tokenStack[index].form, d.hasInfixForms { // command name is immediately followed by an infix/postfix operator, which *may* terminate it// if the operator _also_ has a prefix form it could be meant as part of direct argument, so analyze its surrounding whitespace to determine if operator is prefix (argument) or infix/postfix (terminator); e.g. given `-` operator which has both prefix and infix forms:
                // `foo - 1` and `foo-1` are parsed as infix, with `foo` and `1` as operands to `-`
                // `foo -1` is parsed as prefix, with `-1` as argument to `foo`
                // TO DO: `foo- 1` is for now also treated as prefix, but this isn't ideal as we can't be sure if malformed `A- B` is due to transposition of operator and space or to omission/addition of one space; however, it'll do for now and once we implement PP we can decide how to handle going forward (e.g. since Command is directly annotatable, one option might be to attach a SyntaxWarning to that to draw user's attention to our auto-correction)
          //  print("Determine if ambiguous `(d.name) operator in `\(commandName) \(d.name) …` is prefix or infix/postfix")
          //  print("…has balanced whitespace:", self.tokenStack.hasBalancedWhitespace(at: index))
            if !d.hasPrefixForms || self.tokenStack.hasBalancedWhitespace(at: index) {
                // an infix/postfix-only operator *must* terminate arg-less command
                // an ambiguous operator that has balanced whitespace is treated as infix
                self.tokenStack[startIndex].form = .value(Command(commandName))
                stopIndex = startIndex + 1
              //  print("…no argument.")
                return
            } // else operator is part of direct argument
            else {
             //   print("…has direct argument…")
            }
        } else {
           // print("ARGUMENT: \(self.tokenStack[index].form)")
        }
        var argumentExpressionStartIndex = index
      //  print("Begin reading argument[s] at", index, stopIndex)
        // now find start and end of each argument expression, which may be delimited by lower-precedence operators, next argument label, or the main expression’s stopIndex (e.g. linebreaks, closing parens, conjunctions)
        argumentLoop: while index < stopIndex {
            let form = self.tokenStack[index].form
        //    print("Reading argument token at \(index):", form)
            switch form {
            case .unquotedName(_), .quotedName(_): // nested commands will be treated as atom/prefix operator patterns when argument expression is reduced (i.e. precedence should be handled automatically)
                //         print("…found nested command: \(form.asCommandName()!)")
                
             //   print("…FOUND NESTED COMMAND at \(index): .\(form)")
                
                self.matchNestedCommand(from: index, to: stopIndex)
            case .label(let name): // a label always terminates the previous LP argument/nested command, so reduce the preceding argument expression…
                //          print("\\ Reducing \(argumentLabel.isEmpty ? "direct" : argumentLabel.label) argument expr at \(argumentExpressionStartIndex)..<\(index))…")
                
                self.tokenStack.reduceOperatorExpression(from: startIndex, to: &index)
                
                let value = self.argument(argumentLabel, of: commandName, at: argumentExpressionStartIndex) // TO DO: index will change
                //          print("\\ …to:", value)
                arguments.append((argumentLabel, value))
                argumentLabel = name // …and begin reading the next argument
                argumentExpressionStartIndex = index + 1
            case .operatorName(let d):
                // any operators encountered here are either part of an argument expr (if prefix only or if infix/postfix of higher precedence) or (infix/postfix of lower precedence) terminate the LP command; Q. what about if prefix _and_ infix/postfix of lower precedence (depends if it's at start of argument expr: if it is, it must be prefix, otherwise the infix/postfix terminator rule takes precedence)
                if d.hasPrefixForms && !d.hasInfixForms { // prefix forms only; i.e. must be part of argument expr
                    //       print("prefix-only \(d.name) operator is part of argument expr")
                } else { // d has infix forms, and may have infix forms as well
                    if d.hasPrefixForms && index == argumentExpressionStartIndex {
                        if argumentLabel.isEmpty {
                            //print("\(d.name) operator is immediately after command name, so determine if is prefix or infix/postfix", matches, hasLeadingWhitespace, "\n")
                            if self.tokenStack.hasBalancedWhitespace(at: index) { // treat as infix
                                // TO DO: at this point we need to decide which it is: if it's infix then it terminates arg-less command; if it's prefix it's start of direct argument expr
                                stopIndex = index
                                break argumentLoop
                            }
                        //} else { // do nothing
                            //print("\(d.name) must be prefix operator as it appears immediately after argument label: \(argumentLabel.label)")
                        }
                    } else { // it's infix/postfix only or it's not at start of argument expr so reductionForOperatorExpression can deal with it; all we have to do is decide if it terminates the command or is part of its current argument
                        // TO DO: this is going to blow up on `+`/`-` as prefix ops need to bind tighter than `of`, `thru`, etc (which bind tighter than commands) but infix versions bind looser than commands
                        guard let isLowerPrecedence = d.isInfixPrecedenceLessThanCommand else {
                            fatalError("Cannot resolve precedence between commandand overloaded operator \(d.name) as the operators’ precedences are higher AND lower than command’s.")
                        } // TO DO: this currently throws exception if operator precedences are both higher and lower than command's; it should output .error demanding user add explicit parens to disambiguate
                        if isLowerPrecedence {
                            //print("Decide if lower precedence prefix+infix \(d.name) operator should terminate LP command.")
                            if d.hasPrefixForms && d.hasInfixForms && self.tokenStack.hasBalancedWhitespace(at: index) {
                                stopIndex = index
                                break argumentLoop
                            }
                            if d.hasPrefixForms, d.hasInfixForms,
                                index > argumentExpressionStartIndex,
                                case .operatorName(let pd) = self.tokenStack[index - 1].form,
                                pd.contains(where: { $0.hasRightOperand }) {
                                //print("Looks like prefix+infix \(d.name) operator is preceded by prefix/infix operator \(pd.name), so we'll treat it as prefix operator, i.e. as part of argument expr.")
                            } else {
                                //print("lower-precedence \(d.name) operator terminates command")
                                stopIndex = index
                                break argumentLoop
                            }
                    //  } else {
                    //       print("higher-precedence \(d.name) operator is part of argument expr")
                        }
                    }
                }
            default: () // step over other tokens
            }
            index += 1 // advance to next token
        }
      //  print("Ended reading argument[s] at", index, stopIndex, argumentExpressionStartIndex)
        //   print("command \(commandName) ended at", commandStopIndex, self.tokenStack[commandStopIndex-1].form)
        // reduce the preceding argument expression (i.e. last argument of LP/nested command)
        if argumentExpressionStartIndex < stopIndex { // startIndex = name/label index + 1; stopIndex is non-inclusive // TO DO: what should this test be?
           // print("\\ Reducing \(argumentLabel.isEmpty ? "direct" : argumentLabel.label) argument expr at \(argumentExpressionStartIndex)..<\(stopIndex))…", self.tokenStack.count)
            self.tokenStack.reduceOperatorExpression(from: argumentExpressionStartIndex, to: &stopIndex)
            assert(stopIndex > argumentExpressionStartIndex)
            //print("…reduced:", stopIndex, self.tokenStack.count)
            let value = self.argument(argumentLabel, of: commandName, at: argumentExpressionStartIndex)
            //       print("\\ …to:", value)
            arguments.append((argumentLabel, value))
        }
        let command = Command(commandName, arguments)
        self.tokenStack.replace(from: startIndex, to: stopIndex, withReduction: .value(command))
       // print("LPC REPLACED", startIndex..<stopIndex, "WITH:", command)
        stopIndex = startIndex + 1
    }
    
    //
    
    func reduceIfFullPunctuationCommand() { // called by parser’s main loop after reducing a record literal; if top two tokens in stack are `NAME RECORD`, reduce them to a Command (while we could use a `NAME RECORD` PatternMatch to auto-reduce FP commands, it’s simpler just to hardcode it here; in addition, `NAME RECORD` should probably be part of the core syntax, which means it should always be available even if, say, the LP/argless command syntax is omitted [although for a JSON-like data-only DSL the FP command syntax may be undesirable too])
        // TO DO: what if record is reduced to SyntaxErrorDescription? while syntax errors within individual field exprs should already be encapsulated as SyntaxErrorDescription so won't stop the record itself reducing, messed up labels/delimiters or bad block nesting will likely prevent reduction to a Record value; currently both tokens are left on stack but the presence of `{…}` makes clear that it is intended to be a valid record, so should we capture both tokens as a SyntaxErrorDescription and describe it as malformed command, rather than leave the command unreduced (which will likely result in a [probably unnecessary/unhelpful] second syntax error); ignore for now and sort out later as part of final error handling
        let startIndex = self.tokenStack.count - 2
        if startIndex >= 0, case .value(let v) = self.tokenStack.last!.form,
            let record = v as? Record, let name = self.tokenStack[startIndex].form.asCommandName() {
            // (note: name-only and low-punctuation commands require additional scanning to determine right-hand boundary to their argument list so will be dealt with later by fullyReduceExpression)
            self.tokenStack.replace(from: startIndex, withReduction: .value(Command(name, record)))
        }
    }
    
    //
    
    func reduceCommandExpressions(from startIndex: Int, to stopIndex: inout Int) {
        // this is responsible for finding all unreduced LP commands within an expression (both outer and nested) and reducing them in-situ
        // important: outermost (non-nested) LP commands have an optional direct [non-record] argument followed by zero or more labeled arguments, i.e. `NAME EXPR? ( LABEL EXPR )*`; nested LP commands have an optional direct [non-record] argument only, i.e. `NAME EXPR?` (any labeled args after a nested command are associated with the outermost LP command; thus `foo bar baz: fub bub bim: zub` -> `foo{bar{}, baz: fub{bub}, bim: zub{}}`)
        //
        var outerCommands = [(start: Int, stop: Int, command: Command)]()
        var start = startIndex
        while let commandStartIndex = self.tokenStack[start..<stopIndex].firstIndex(where: { $0.form.isCommandName }) {
            var commandStopIndex = stopIndex
            let n = self.tokenStack.count
            self.reduceLowPunctuationCommand(from: commandStartIndex, to: &commandStopIndex)
            let d = n - self.tokenStack.count
            stopIndex -= d
            guard let command = self.tokenStack.value(at: commandStartIndex) as? Command else {
                fatalError("TODO: expected Command at \(commandStartIndex) but found: .\(self.tokenStack[commandStartIndex].form)")
            }
            outerCommands.append((commandStartIndex, commandStopIndex, command))
            start = commandStopIndex // (returned commandStopIndex is the first token after command)
        }
        //print("FOUND outer commands:", outerCommands)
        let oldStackSize = self.tokenStack.count
        for (start, stop, command) in outerCommands.reversed() {
            self.tokenStack.replace(from: start, to: stop, withReduction: .value(command))
        }
        stopIndex = stopIndex - (oldStackSize - self.tokenStack.count)
        //     self.tokenStack.show(startIndex, stopIndex)
    }
}

