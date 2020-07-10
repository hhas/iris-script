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
        // (note that because LP commands are self-delimiting on left side but not right, we must read commands left-to-right in order to determine what is an outer command vs nested command; additionally, we have to identify the start and end of each LP command and its arity before we can start to reduce operators by precedence; hence the departure from the usual right-to-left matching and reduction of a shift-reduce parser, which always operates from the head of the stack)
        // note: where the command name is followed by a record literal, the command *always* binds the record as FP argument syntax; if that record is followed by a label that should be treated as a syntax error (i.e. if the direct argument to a command is itself a record literal, either use FP syntax or wrap the record in parens to disambiguate; while there isn't a way around this limitation, in practical use a post-parse linter should be  able to look up or guess most commands’ handlers and compare argument labels and types to detect many (though not all) likely syntax errors of this type and suggest corrections)
        let commandName = self.tokenStack[startIndex].form.asCommandName()!
       //print("READ LP COMMAND", commandName, "at", startIndex)
        var index = startIndex + 1 // start index is initially the command name, so step over that and look for a direct argument, e.g. `foo 1 …`
        if index == stopIndex { // end of expression; command *cannot* have any arguments, so reduce and return
            self.tokenStack[startIndex].form = .value(Command(commandName))
            return
        }
        var isDirectArgument = true
        if case .label(_) = self.tokenStack[index].form { // command has no direct argument, e.g. `foo bar: expr …`
            index += 1 // step over label to the argument expression
            isDirectArgument = false
        } else if case .operatorName(let d) = self.tokenStack[index].form, d.hasInfixForms { // `NAME OPNAME …`
            // command name is immediately followed by an infix/postfix operator, which *may* terminate it:
            // - a prefix-only operator *must* be direct argument to command
            // - an infix/postfix-only operator *must* terminate arg-less command
            // - an operator that is both prefix and infix/postfix is disambiguated by its whitespace:
            //     - balanced whitespace is treated as infix operator, e.g. `foo - 1` ➞ `‘-’{foo{}, 1}`
            //     - imbalanced whitespace is treated as prefix operator, e.g. `foo -1` ➞ `foo{-1}`
          //  print("Determine if ambiguous `(d.name) operator in `\(commandName) \(d.name) …` is prefix or infix/postfix: has balanced whitespace:", self.tokenStack.hasBalancedWhitespace(at: index))
            if !d.hasPrefixForms || self.tokenStack.hasBalancedWhitespace(at: index) { // treat as infix (no arguments)
                self.tokenStack[startIndex].form = .value(Command(commandName))
                stopIndex = startIndex + 1
              //  print("…no argument.")
                return
            } // else operator is start of direct argument
        }
        var argumentExpressionStartIndex = index
      //  print("Begin reading argument[s] at", index, stopIndex)
        // now find start and end of each argument expression, which may be delimited by lower-precedence operators, next argument label, or the main expression’s stopIndex (e.g. linebreaks, closing parens, conjunctions)
        argumentLoop: while index < stopIndex {
            assert(index < self.tokenStack.count, "LP command’s argument loop: index \(index) exceeds stack size \(self.tokenStack.count) (stop: \(stopIndex))\n\(self.tokenStack.dump())\n\n")
            let form = self.tokenStack[index].form
           // print("Reading argument token at \(index):", form)
            switch form {
            case .unquotedName(_), .quotedName(_): // nested commands will be treated as atom/prefix operator patterns when argument expression is reduced (i.e. precedence should be handled automatically)
                self.matchNestedCommand(from: index, to: stopIndex)
            case .label(_): // a label always terminates the previous LP argument/nested command
                stopIndex -= (index - argumentExpressionStartIndex) - 1 // adjust stopIndex for removed tokens…
                self.tokenStack.reduceOperatorExpression(from: argumentExpressionStartIndex, to: &index) // …reduce…
                argumentExpressionStartIndex = index + 1 // …and begin reading the next argument
                isDirectArgument = false
            case .operatorName(let d):
                // any operators encountered here are either part of an argument expr (if prefix only or if infix/postfix of higher precedence) or (infix/postfix of lower precedence) terminate the LP command; Q. what about if prefix _and_ infix/postfix of lower precedence (depends if it's at start of argument expr: if it is, it must be prefix, otherwise the infix/postfix terminator rule takes precedence)
                if d.hasPrefixForms && !d.hasInfixForms { // prefix forms only; i.e. must be part of argument expr
                    //       print("prefix-only \(d.name) operator is part of argument expr")
                } else { // d has infix forms, and may have prefix forms as well
                    if d.hasPrefixForms && index == argumentExpressionStartIndex {
                        if isDirectArgument && self.tokenStack.hasBalancedWhitespace(at: index) { // treat as infix
                            break argumentLoop
                        }
                    } else { // operator is infix/postfix only or not at start of argument expr, so reductionForOperatorExpression will deal with it; all we have to do is decide if it terminates this command or is part of its current argument
                        guard let isLowerPrecedence = d.isInfixPrecedenceLessThanCommand else {
                            fatalError("Cannot resolve precedence between commandand overloaded operator \(d.name) as the operators’ precedences are higher AND lower than command’s.")
                        } // TO DO: this currently throws exception if operator precedences are both higher and lower than command's; it should output .error demanding user add explicit parens to disambiguate // TO DO: this is going to blow up on `+`/`-` as prefix ops need to bind tighter than `of`, `thru`, etc (which bind tighter than commands) but infix versions bind looser than commands
                        if isLowerPrecedence {
                            let isAmbiguous = d.hasPrefixForms && d.hasInfixForms
                            //print("Decide if lower precedence prefix+infix \(d.name) operator should terminate LP command.")
                            if isAmbiguous && self.tokenStack.hasBalancedWhitespace(at: index) { // treat as infix
                                break argumentLoop
                            }
                            if isAmbiguous && index > argumentExpressionStartIndex,
                                case .operatorName(let pd) = self.tokenStack[index - 1].form,
                                pd.contains(where: { $0.hasRightOperand }) {
                                //print("Looks like prefix+infix \(d.name) operator is preceded by prefix/infix operator \(pd.name), so we'll treat it as prefix operator, i.e. as part of argument expr.")
                            } else {
                                //print("lower-precedence \(d.name) operator terminates command")
                                break argumentLoop
                            }
                        }
                    }
                }
            default: () // step over other tokens
            }
            index += 1 // advance to next token
        }
        stopIndex = index
        // reduce the preceding argument expression (i.e. last argument of LP/nested command)
        if argumentExpressionStartIndex < stopIndex { // startIndex = name/label index + 1; stopIndex is non-inclusive // TO DO: what should this test be?
            self.tokenStack.reduceOperatorExpression(from: argumentExpressionStartIndex, to: &stopIndex)
            assert(stopIndex > argumentExpressionStartIndex)
        }
        let value: Value
        do {
            value = try reductionForCommandLiteral(stack: self.tokenStack, match: nullMatch,
                                                   start: startIndex, end: stopIndex)
        } catch {
            value = SyntaxErrorDescription(error: error as? NativeError ?? InternalError(error))
        }
        //print("reduceLowPunctuationCommand: ", commandName, self.tokenStack[startIndex..<stopIndex].map{$0.form})
        self.tokenStack.replace(from: startIndex, to: stopIndex, withReduction: .value(value))
       // print("LPC REPLACED", startIndex..<stopIndex, "WITH:", command)
        stopIndex = startIndex + 1
    }
    
    //
    
    func reduceIfFullPunctuationCommand() { // called by parser’s main loop after reducing a record literal; if top two tokens in stack are `NAME RECORD`, reduce them to a Command (while we could use a `NAME RECORD` PatternMatch to auto-reduce FP commands, it’s simpler just to hardcode it here; in addition, `NAME RECORD` should probably be part of the core syntax, which means it should always be available even if, say, the LP/argless command syntax is omitted [although for a JSON-like data-only DSL the FP command syntax may be undesirable too])
        // TO DO: what if record is reduced to SyntaxErrorDescription? while syntax errors within individual field exprs should already be encapsulated as SyntaxErrorDescription so won't stop the record itself reducing, messed up labels/delimiters or bad block nesting will likely prevent reduction to a Record value; currently both tokens are left on stack but the presence of `{…}` makes clear that it is intended to be a valid record, so should we capture both tokens as a SyntaxErrorDescription and describe it as malformed command, rather than leave the command unreduced (which will likely result in a [probably unnecessary/unhelpful] second syntax error); ignore for now and sort out later as part of final error handling
        let startIndex = self.tokenStack.count - 2
        if startIndex >= 0, case .value(let v) = self.tokenStack.last!.form,
            let record = v as? Record, let name = self.tokenStack[startIndex].form.asCommandName() {
            // (note: name-only and low-punctuation commands require additional scanning to determine right-hand boundary to their argument list so will be dealt with later by reduceExpression)
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

