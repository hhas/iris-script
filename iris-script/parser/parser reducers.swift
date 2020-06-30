//
//  match and reduce.swift
//  iris-script
//

// WIP // pulled this out of Parser for now; not sure if it should be there or on matcher

import Foundation


extension Array {
    mutating func replaceFirst(with item: Element) {
        self[0] = item
    }
    mutating func replaceLast(with item: Element) {
        self[self.count - 1] = item
    }
}


extension Parser {
    
    // re. API designs: reduction APIs that returned a reduced value should return any adjusted indexes, not modify in-place; reduction APIs that replace stack tokens with a reduced value should adjust any indexes in-place (i.e. via inout parameter, not by returning new values) [i.e. the former can make no changes to parser state; the latter can leave no changes incomplete]
        
    // note that we make one restriction w.r.t. operator extensibility in order to simplify resolving operator vs command precedence: overloaded operator definitions are forbidden being both higher AND lower precedence than commands, e.g. assuming every command binds its arguments with precedence 1000, and an overloaded operator ‘∆’ were to have an infix form of precedence 999 and a postfix form of precedence 1001, the parser will flag `foo 1 ∆` as a syntax error requiring the user to manually parenthesize either `foo {1 ∆}` or `(foo 1) ∆` (or `foo {1} ∆`, since a record literal following a command name will _always_ bind to that name). Since all commands have a single fixed precedence, this restriction shouldn’t be too onerous: while it's still possible that two external libraries could overload the same operator name with incompatible precedences, that overloading probably violates good practice (i.e. don't give recognizable symbols arbitrary/non-standard meanings) and can still be manually resolved by the user adding parens when the parser refuses to do so (a fair penalty for library authors’ overreach); see also TODO on Associativity.none
    
    // problem with using PatternMatcher to match commands is that command parsing is context-sensitive: if a command appears as argument to a low-punctuation command, the nested command cannot also be low-punctuation and any `NAME:VALUE` pairs that appear after it must be associated with the outer, not inner, command (a pattern matcher would associate it with the most recently encountered command name, i.e. the inner one)

    func reductionForOperatorExpression(from startIndex: Int, to stopIndex: Int) -> Token.Form { // start..<stop
        // reduces an expression composed of one or more operations (this includes unreduced nested commands for which matchers have been added, but not LP commands which must be custom-reduced beforehand)
        // important: any commands within the expression must already be reduced to .value(Command(…))
        if startIndex == stopIndex - 1 {
            switch self.stack[startIndex].form {
            case .value(let v):
                return .value(v)
            case .error(let e):
                return .value(BadSyntaxValue(error: e)) // TO DO: where should .error transform to error value?
            default: ()
            }
        }
        //print("reductionForOperatorExpression:"); self.stack.show(startIndex, stopIndex)
        var matches = self.stack.findLongestMatches(from: startIndex, to: stopIndex)
        //for m in matches { print("Longest ", m) }
        if matches.isEmpty { // note: this is empty when e.g. `do` keyword is followed by delimiter (since `do` is not an atom but part of a larger `do…done` block that spans multiple expressions, it should not be reduced at this time); we still go through the find-longest step in case there are completed pattern matchers available
            if startIndex == stopIndex - 1 { // TO DO: is there any situation where there’d be >1 token here that isn’t a syntax error?
                return self.stack[startIndex].form
            }
            return .value(BadSyntaxValue(error: InternalError(description: "Can't fully reduce \(startIndex)..<\(stopIndex) as no full matches found: \(self.stack.dump(startIndex, stopIndex))"))) // TO DO: BadSyntaxValue should always take stack and start+stop indexes and store its own copy of that array slice (may be used in generating syntax error descriptions and, potentially, making corrections in place [this'd need BadSyntaxValue class to delegate all Value operations to a private `Value?` var])
        }
        if matches[0].start != startIndex {print("BUG: Missing first matcher[s] for \(startIndex)...\(matches[0].start)")}
        if matches.last!.stop != stopIndex-1 {print("BUG: Missing last matcher[s] for \(matches.last!.stop)...\(stopIndex-1)")}
        // starting from right end of specified stack range, shift left to find the highest-precedence operator and reduce that; rinse and repeat until only one operator is left to reduce; note that this will also reduce nested commands as those had pattern matchers attached to them by reduceCommands
        var rightExpressionIndex = matches.count - 1
        var leftExpressionIndex = rightExpressionIndex - 1
        while matches.count > 1 {
            //print("matches:", matches.map{ "\($0.start)-\($0.stop) `\($0.match.name.label)`" }.joined(separator: ", "))
            var left = matches[leftExpressionIndex], right = matches[rightExpressionIndex]
            var hasSharedOperand = left.stop >= right.start
            while leftExpressionIndex > 0 && hasSharedOperand && reductionOrderFor(left.match, right.match) == .left {
                leftExpressionIndex -= 1; rightExpressionIndex -= 1
                left = matches[leftExpressionIndex]; right = matches[rightExpressionIndex]
                hasSharedOperand = left.stop >= right.start
            }
            // left = matches[index+1], right = matches[index]
           // print("LEFT:", left, "\nRIGHT:", right, "\n", rightExpressionIndex)
            //print("hasSharedOperand:", hasSharedOperand, left.match.name, right.match.name)
            if hasSharedOperand {
                switch reductionOrderFor(left.match, right.match) {
                case .left: // left expr is infix/postfix operation
                   // print("REDUCE LEFT MATCH", left.match.name)
                    matches.reduceMatch(at: leftExpressionIndex)
                case .right: // right expr is prefix/infix operation
                   // print("REDUCE RIGHT MATCH", right.match.name)
                    matches.reduceMatch(at: rightExpressionIndex)
                }
            } else {
                // TO DO: this also happens if a completed operator match is missing from matches array due to a bug in [e.g.] findLongestMatches()
                print("no shared operand:\n\n\tLEFT MATCH \(left.start)...\(left.stop):", left.match, "\n\t", left.tokens.map{".\($0.form)"}.joined(separator: "\n\t\t\t "), "\n\n\t RIGHT MATCH \(right.start)...\(right.stop)", right.match, "\n\t\t", right.tokens.map{".\($0.form)"}.joined(separator: "\n\t\t\t "), "\n")
                // TO DO: need to fully reduce right expr[s], move result to stack, remove that matcher and reset indices, then resume
                fatalError("TO DO: non-overlapping expressions, e.g. `1+2 3+4`, or missing [e.g. incomplete] match") // pretty sure `EXPR EXPR` is always a syntax error (with opportunities to suggest corrections, e.g. by inserting a delimiter)
            }
            //matches.show() // DEBUG
            if rightExpressionIndex == matches.count { // adjust indexes for shortened matches array as needed
                leftExpressionIndex -= 1
                rightExpressionIndex -= 1
            }
        }
        // reduce the final operator expression and replace the parser stack’s original frames with the result
        assert(matches.count == 1)
        return matches[0].tokens.reductionFor(fullMatch: matches[0].match)
    }
    
    
    
    
    func reductionForArgumentExpression(_ label: Symbol, from startIndex: Int, to stopIndex: Int) -> Value {
    //    print("reductionForArgumentExpression: \(label.isEmpty ? "direct" : label.label) argument at \(startIndex)..<\(stopIndex).")
    //    self.stack.show(startIndex, stopIndex)
        let value: Value
        let form = self.reductionForOperatorExpression(from: startIndex, to: stopIndex)
        switch form {
        case .value(let v): value = v
        default:
            
            value = BadSyntaxValue(error: InternalError(description: "\(label.isEmpty ? "direct" : label.label) argument did not fully reduce: .\(form)\n\(self.stack.dump(startIndex, stopIndex))\n"))
        }
        return value
    }
    
    
    
    func addMatchersForNestedCommand(at index: Int, to stopIndex: Int) {
        // caution: caller is responsible for ensuring Parser.stack[index] is an .[un]quotedName(…) as we don't bother to re-match it here before adding the command matchers to it
        // nested commands accept an optional record or direct value argument but no LP labeled args; thus they are always terminated by a label (which is then added to outer command); where a nested command is followed by infix/postfix operator, if the operator’s precedence is greater than commandPrecedence it takes the innermost command as its left operand (this terminates the innermost command), otherwise it takes the outermost command (this terminates all commands); users can still disambiguate/override by parenthesizing, of course, e.g.:
        //    `foo bar of baz` -> `foo {bar of baz}`
        //    `foo bar + baz` -> `(foo {bar}) + baz`
        //    `(foo bar) of baz` -> `(foo {bar}) of baz`
        //    `foo (bar + baz)` -> `foo {bar + baz}`
        // this means that nested commands can be matched by a simple `NAME EXPR?` operator pattern, which is added here and reduced by reductionForOperatorExpression()
        //print("NESTED COMMAND at \(index): .\(form)")
        let matchers = nestedCommandLiteral.patternMatchers(groupID: OperatorDefinitions.newGroupID())
        self.stack[index].matches += matchers
        if index + 1 < stopIndex { // if there's more tokens after the name
            // advance the command matchers and try to match the [start of its] direct argument EXPR (if it has one)
            let matchers = matchers.flatMap{ $0.next() }
            let form = self.stack[index+1].form
            self.stack[index+1].matches += matchers.filter{ $0.match(form, allowingPartialMatch: true) }
            // reductionForOperatorExpression() can now reduce our newly added matchers as standard atomic/prefix operators of commandPrecedence
        }
    }
    
    
    func reductionForLowPunctuationCommand(from startIndex: Int, to stopIndex: Int) -> (command: Command, commandStopIndex: Int) { // startIndex..<stopIndex
        // reads, reduces, and returns the *first* low-punctuation command found the given range (e.g. a [presumably] complete, unreduced expression delimited at start and end by linebreaks/punctuation); this includes reading any nested commands in its arguments and reducing those argument tokens down to argument values in the final Command; on return, commandTokens is partly/fully consumed and the new stopIndex is given: the caller is responsible for invoking again if there are any command names remaining in commandTokens
        // startIndex is stack index of the LP command's name, which we've already matched; stopIndex is the index at which the entire expression must end; the result is the parsed Command and the index at which it ended
        let commandName = self.stack[startIndex].form.asCommandName()!
        // (note that because LP commands are self-delimiting on left side but not right, we must read commands left-to-right in order to determine what is an outer command vs nested command; additionally, we have to identify the start and end of each LP command and its arity before we can start to reduce operators by precedence; hence the departure from the usual right-to-left matching and reduction of a shift-reduce parser, which always operates from the head of the stack)
  //      print("Found command name:", commandName, "at:", startIndex)
        // note: where the command name is followed by a record literal, the command *always* binds the record as FP argument syntax; if that record is followed by a label that should be treated as a syntax error (i.e. if the direct argument to a command is itself a record literal, either use FP syntax or wrap the record in parens to disambiguate; while there isn't a way around this limitation, in practical use a post-parse linter should be  able to look up or guess most commands’ handlers and compare argument labels and types to detect many (though not all) likely syntax errors of this type and suggest corrections)
        var index = startIndex + 1 // start index is initially the command name, so step over that and look for a direct argument, e.g. `foo 1 …`
        if index == stopIndex { return (Command(commandName), index) } // command *cannot* have any arguments, so return now
        var commandStopIndex = stopIndex // if LP command is terminated by a lower-precedence operator, that end index is returned; otherwise the command will terminate at end of main expression
        var arguments = [Command.Argument]()
        var argumentLabel = nullSymbol // nullSymbol = direct argument, if there is one
        if case .label(let name) = self.stack[index].form { // command has no direct argument, e.g. `foo bar: expr …`
            index += 1 // step over label to the argument expression
            argumentLabel = name
      //      print("No direct argument")
        } else if case .operatorName(let d) = self.stack[index].form, d.hasInfixForms { // command name is immediately followed by an infix/postfix operator, which *may* terminate it
            if d.hasPrefixForms { // analyze to determine if operator is prefix (argument) or infix/postfix (terminator)
                print("TODO: determine if operator in `\(commandName) \(d.name) …` is prefix or infix/postfix")
                // TO DO: what if operator has prefix and postfix forms and no infix forms? depends if there's an expr after it: if there is, it’s prefix (can't be postfix); if there isn't, it’s postfix (can't be prefix)
                // TO DO: what if operator has prefix and infix/postfix forms? if there's an expr after it it can't be postfix (at which point we look at whitespace to determine if prefix, infix, or requires explicit parens); if there isn't, it must be postfix
                // Q. if ambiguous operator is itself followed by another operator, should we stop guessing and just demand explicit parens?
            } else { // infix/postfix-only operator *must* terminate arg-less command
                return (Command(commandName), startIndex + 1)
            }
        } else {
      //      print("ARGUMENT: \(self.stack[index].form)")
        }
        var argumentExpressionStartIndex = index
        // now find start and end of each argument expression, which may be delimited by lower-precedence operators, next argument label, or the main expression’s stopIndex (e.g. linebreaks, closing parens, conjunctions)
        argumentLoop: while index < stopIndex {
            let (form, matches, hasLeadingWhitespace) = self.stack[index]
        //    print("Parsing argument token:", index, form)
            switch form {
            case .unquotedName(_), .quotedName(_): // nested commands will be treated as atom/prefix operator patterns when argument expression is reduced (i.e. precedence should be handled automatically)
       //         print("…found nested command: \(form.asCommandName()!)")
                self.addMatchersForNestedCommand(at: index, to: stopIndex)
            case .label(let name): // a label always terminates the previous LP argument/nested command, so reduce the preceding argument expression…
      //          print("\\ Reducing \(argumentLabel.isEmpty ? "direct" : argumentLabel.label) argument expr at \(argumentExpressionStartIndex)..<\(index))…")
                let value = self.reductionForArgumentExpression(argumentLabel, from: argumentExpressionStartIndex, to: index)
      //          print("\\ …to:", value)
                arguments.append((argumentLabel, value))
                argumentLabel = name // …and begin reading the next argument
                argumentExpressionStartIndex = index + 1
            case .operatorName(let d):
                // any operators encountered here are either part of an argument expr (if prefix only or if infix/postfix of higher precedence) or (infix/postfix of lower precedence) terminate the LP command; Q. what about if prefix _and_ infix/postfix of lower precedence (depends if it's at start of argument expr: if it is, it must be prefix, otherwise the infix/postfix terminator rule takes precedence)
                if d.hasPrefixForms && !d.hasInfixForms { // prefix forms only; i.e. must be part of argument expr
             //       print("prefix-only \(d.name) operator is part of argument expr")
                } else { // d has infix forms, and may have infix forms as well
                    
                    // TO DO: this is wrong as it doesn't consider a prefix+infix operator (`-`) after an infix operator (`thru`)
                    
                    // TO DO: could really do with using matcher for LP command as that'd resolve most arity+precedence issues
                    
                    if d.hasPrefixForms && index == argumentExpressionStartIndex {
                        if argumentLabel.isEmpty {
                            print("\(d.name) is immediately after command name, so is either prefix or infix operator", matches, hasLeadingWhitespace, "\n")
                            
                            // TO DO: at this point we need to decide which it is: if it's infix then it terminates arg-less command; if it's prefix it's start of direct argument expr
                            
                            // if infix:
                            // commandStopIndex = index
                            // break argumentLoop

                            
                        } else {
                            print("\(d.name) must be prefix operator as it appears immediately after argument label: \(argumentLabel.label)")
                        }
                    } else { // it's infix/postfix only or it's not at start of argument expr so reductionForOperatorExpression can deal with it; all we have to do is decide if it terminates the command or is part of its current argument
                        guard let isHigherPrecedence = d.isInfixPrecedenceGreaterThanCommand else {
                            fatalError("Cannot resolve precedence between commandand overloaded operator \(d.name) as the operators’ precedences are higher AND lower than command’s.")
                        } // TO DO: this currently throws exception if operator precedences are both higher and lower than command's; it should output .error demanding user add explicit parens to disambiguate
                        if isHigherPrecedence {
                       //     print("higher-precedence \(d.name) operator is part of argument expr")
                        } else {
                            // TO DO: temporary kludge to get around problem of `-` in `NAME … OP -1` being treated as infix operator and so terminating command, even when OP is higher-precedence prefix/infix operator (which forbids `-` being infix) and so should force `-` to be prefix operator (which cannot terminate command); being a kludge this will likely break under sufficient pressure
                            // TO DO: ideally we'd use an intermediate `LABEL EXPR` to `.pair(NAME,VALUE)` reduction, where LABEL acts as prefix operator of commandPrecedence, and thus is able to split and reduce left side of EXPR automatically, [hopefully] allowing LP commands to be handled via [slightly customized] pattern matching rather than this fiddly hardcoded logic; we can explore this route later
                            if d.hasPrefixForms, d.hasInfixForms {
                                print("TODO: Decide if lower precedence prefix+infix \(d.name) operator should terminate LP command.")
                            }
                            if d.hasPrefixForms, d.hasInfixForms, index > argumentExpressionStartIndex,
                                case .operatorName(let pd) = self.stack[index - 1].form,
                                pd.contains(where: { $0.hasTrailingExpression }) {
                                print("Looks like prefix+infix \(d.name) operator is preceded by prefix/infix operator \(pd.name), so we'll treat it as prefix operator, i.e. as part of argument expr.")
                            } else {
                                //print("lower-precedence \(d.name) operator terminates command")
                                commandStopIndex = index
                                break argumentLoop
                            }
                            
                        }
                    }
                }
            default: () // step over other tokens
            }
            index += 1 // advance to next token
        }
        
     //   print("command \(commandName) ended at", commandStopIndex, self.stack[commandStopIndex-1].form)
        // reduce the preceding argument expression (i.e. last argument of LP/nested command)
        if argumentExpressionStartIndex < commandStopIndex { // startIndex = name/label index + 1; stopIndex is non-inclusive // TO DO: what should this test be?
     //       print("\\ Reducing \(argumentLabel.isEmpty ? "direct" : argumentLabel.label) argument expr at \(argumentExpressionStartIndex)..<\(commandStopIndex))…")
            let value = self.reductionForArgumentExpression(argumentLabel, from: argumentExpressionStartIndex, to: commandStopIndex)
     //       print("\\ …to:", value)
            arguments.append((argumentLabel, value))
        }
        return (Command(commandName, arguments), commandStopIndex)
    }
    
    
    
    
    func reduceCommands(from startIndex: Int, to stopIndex: inout Int) {
        // this is responsible for finding all unreduced LP commands within an expression (both outer and nested) and reducing them in-situ
        // important: outermost (non-nested) LP commands have an optional direct [non-record] argument followed by zero or more labeled arguments, i.e. `NAME EXPR? ( LABEL EXPR )*`; nested LP commands have an optional direct [non-record] argument only, i.e. `NAME EXPR?` (any labeled args after a nested command are associated with the outermost LP command; thus `foo bar baz: fub bub bim: zub` -> `foo{bar{}, baz: fub{bub}, bim: zub{}}`)
        //
        var outerCommands = [(start: Int, stop: Int, command: Command)]()
        var start = startIndex
        while let commandStartIndex = self.stack[start..<stopIndex].firstIndex(where: { $0.form.isCommandName }) {
            let (command, commandStopIndex) = self.reductionForLowPunctuationCommand(from: commandStartIndex, to: stopIndex)
            outerCommands.append((commandStartIndex, commandStopIndex, command)) // TO DO: make sure stopIndex is non-inclusive
            start = commandStopIndex
            
        }
//        print("FOUND outer commands:", outerCommands)
        let oldStackSize = self.stack.count
        for (start, stop, command) in outerCommands.reversed() {
            self.stack.replace(from: start, to: stop, withReduction: .value(command))
        }
        stopIndex = stopIndex - (oldStackSize - self.stack.count)
   //     self.stack.show(startIndex, stopIndex)
    }
    
    
    
    // TO DO: it'd be better to reduce `LABEL EXPR` to intermediate .pair form, allowing record patterns to use `.anyOf([.expr, .pair])` to match fields; LP commands could also use .pair
    
    func fullyReduceExpression(from _startIndex: Int = 0, to stopIndex: Int? = nil) {
        var stopIndex = stopIndex ?? self.stack.count // caution: stopIndex is nearest head of stack, so will no longer be valid once a reduction is performed
      //  print("fullyReduceExpression:"); self.stack.show(_startIndex, stopIndex)
        // scan back from stopIndex until an expression delimiter is found or original startIndex is reached; that then becomes the startIndex for findLongestMatches // TO DO: is this still needed? currently when fullyReduceExpression is called, how is the _startIndex argument determined?
        var startIndex = self.stack.findStartIndex(from: _startIndex, to: stopIndex)
      //  print("…found startIndex", startIndex)
        
        if startIndex == stopIndex { return } // zero length, e.g. `[ ]`
        
        // if the token range starts with a label, leave it and only reduce the expr after it; this may be a bit kludgy, but fingest crossed it solves the problem well enough to proceed as `LABEL EXPR` should only [currently?] appear in two places: after an LP command name and in a record field, and in first case we want findStartIndex to skip over labels (which are always preceded by at least one token) while in the second the label, if present, is always the first token in found range (which is what the next line ignores), and the record literal’s reducefunc eventually takes care of it // TO DO: if we allow `LABEL EXPR` for name-value bindings in blocks, how will this affect parsing/matching
        if startIndex < stopIndex, case .label(_) = self.stack[startIndex].form {
            startIndex += 1
        }
        self.reduceCommands(from: startIndex, to: &stopIndex) // on return, all commands have been reduced in-place and stopIndex is decremented by the number of tokens removed during that reduction
        let form = self.reductionForOperatorExpression(from: startIndex, to: stopIndex)
     //   print("REDUCED OPERATOR"); self.stack.show(startIndex, stopIndex)
        self.stack.replace(from: startIndex, to: stopIndex, withReduction: form)
        //print("…EXPR FULLY REDUCED TO: .\(form)\n")
    }
    
    func reduce(conjunction: Token.Form, matchedBy matchers: [PatternMatcher]) {
        // note: matching a conjunction keyword forces reduction of the preceding expr
        // TO DO: this assumes conjunction's .operatorName token has yet to be shifted onto parser stack (for now this assumption should hold as it's only ever called from parser's main loop, which always operates on head of stack)
        let matchID: Int // find nearest
        if matchers.count == 1 {
            matchID = matchers[0].matchID
        } else {
            matchID = matchers.min{ $0.count < $1.count }!.matchID // confirm this logic; if there are multiple matchers in progress it should associate with the nearest/innermost, i.e. shortest = most recently started (e.g. consider nested `if…then…` expressions); it does smell though
        }
        // TO DO: this will fail if no matchers found with given ID, e.g. `do…done` blocks currently fail here
        guard let i = self.stack.lastIndex(where: { $0.matches.contains{ $0.matchID == matchID } }) else {
            print(matchers)
            fatalError("BUG: Can't find start index for \(conjunction) (matchID: \(matchID)) in:\n \(self.stack.dump())")
        }
        let startIndex = i + 1
        let stopIndex = self.stack.count
        //print("FULLY REDUCING EXPR before conjunction: .\(conjunction)…")
        self.fullyReduceExpression(from: startIndex, to: stopIndex) // start..<stop
    }
    
}
