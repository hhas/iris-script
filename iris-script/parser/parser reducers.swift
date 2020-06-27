//
//  match and reduce.swift
//  iris-script
//

// WIP // pulled this out of Parser for now; not sure if it should be there or on matcher

import Foundation


extension Parser {
    
    // TO DO: two options for parsing commands: 1. leave it entirely to fullyReduceExpression(), which can search for names and labels and call itself to reduce arguments in LP syntax (the delimiter being `NAME COLON` labels); or 2. put commands on Parser.blockMatches and read them in main loop
    
        
    // simplest way to deal with command precedence is to forbid overloaded operator definitions from being both higher AND lower precedence than commands (since all commands have a single fixed precedence, this limitation is slightly less onerous than operator-vs-operator precedence; although it's still possible that two external libraries could define the same custom operator with incompatible precedences, in which case would need to throw parse error REQUIRING user to parenthesize one or other when encountered in code [see also TODO on Associativity.none])
    
    // problem with using PatternMatcher to match commands is that command parsing is context-sensitive: if a command appears as argument to a low-punctuation command, the nested command cannot also be low-punctuation and any `NAME:VALUE` pairs that appear after it must be associated with the outer, not inner, command (a pattern matcher would associate it with the most recently encountered command name, i.e. the inner one)

    func reductionForOperatorExpression(from startIndex: Int, to stopIndex: Int) -> Token.Form {
        // reduces an expression composed of one or more operations (this includes unreduced nested commands for which matchers have been added, but not LP commands which must be custom-reduced beforehand)
        // important: any commands within the expression must already be reduced to .value(Command(…))
        if startIndex == stopIndex - 1 {
            switch self.stack[startIndex].reduction {
            case .value(let v):
                return .value(v)
            case .error(let e):
                return .error(e) // TO DO: where should .error transform to .value(BadSyntaxValue(…))?
            default: ()
            }
        }
       // print("reductionForOperatorExpression:")
       // self.stack.show(startIndex, stopIndex)
        var matches = self.stack.findLongestMatches(from: startIndex, to: stopIndex)
      //  print("->", matches)
        if matches.isEmpty { // TO DO: also empty if it's already a reduced .value/.error
            print("BUG/WARNING: Can't fully reduce \(startIndex)..<\(stopIndex) as no full matches found:")
            self.stack.show(startIndex, stopIndex)
            return .error(InternalError(description: "Can't fully reduce \(startIndex)..<\(stopIndex) as no full matches found."))
        }
        if matches[0].start != startIndex {print("BUG: Missing first matcher[s] for \(startIndex)...\(matches[0].start)")}
        if matches.last!.stop != stopIndex-1 {print("BUG: Missing last matcher[s] for \(matches.last!.stop)...\(stopIndex-1)")}
        
      //  matches.show() // DEBUG
        //print(">>>", matches[0])
        
        // starting from head (right) of stack, shift left to find the highest-precedence operator and reduce that; rinse and repeat until only one operator is left to reduce
        var rightExpressionIndex = matches.count - 1
        var leftExpressionIndex = rightExpressionIndex - 1
        while matches.count > 1 {
            //print("matches:", matches.map{ "\($0.start)-\($0.stop) `\($0.match.name.label)`" }.joined(separator: ", "))
            var left = matches[leftExpressionIndex], right = matches[rightExpressionIndex]
            var hasSharedOperand = left.stop == right.start
            while leftExpressionIndex > 0 && hasSharedOperand && reductionOrderFor(left.match, right.match) == .left {
                leftExpressionIndex -= 1; rightExpressionIndex -= 1
                left = matches[leftExpressionIndex]; right = matches[rightExpressionIndex]
                hasSharedOperand = left.stop == right.start
            }
            // left = matches[index+1], right = matches[index]
            //print("LEFT:", left, "\nRIGHT:", right, "\n", rightExpressionIndex)
            //print("hasSharedOperand:", hasSharedOperand, left.match.name, right.match.name)
            if hasSharedOperand {
                // caution: reductionOrderFor only indicates which of two exprs should be reduced first; it does not indicate how that reduction should be performed, as the process for reducing unary operations is not quite the same as for binary operations
                switch reductionOrderFor(left.match, right.match) {
                case .left:
                    //print("REDUCE LEFT EXPR", left.match.name)
                    let form = left.tokens.reductionFor(completedMatch: left.match)
                    //print("…TO: \(form)")
                    // e.g. `3 + - 1 * 2`
                    // copy the reduced value to the start of the right expr
                    let reduction: StackItem = (form, [], left.tokens[0].hasLeadingWhitespace)
                    matches[rightExpressionIndex].tokens[0] = reduction
                    matches[rightExpressionIndex].start = left.start
                    matches.remove(at: leftExpressionIndex)
                    // if left expr was atom/postfix operator, copy the reduced value to the left expr as well, e.g. `[A op startB] reducedB [endB op C]` -> `[A op reducedB] [reducedB op C]`
                    if !left.match.definition.hasTrailingExpression && leftExpressionIndex > 0 {
                        let lastIndex = matches[leftExpressionIndex-1].tokens.count - 1
                        matches[leftExpressionIndex-1].tokens[lastIndex].reduction = form
                    }
                case .right:
                    //print("REDUCE RIGHT EXPR", right.match.name)
                    let form = right.tokens.reductionFor(completedMatch: right.match)
                    //print("…TO: \(form)")
                    // copy the reduced value to the end of the left expr
                    let lastIndex = matches[leftExpressionIndex].tokens.count - 1
                    let reduction: StackItem = (form, [], right.tokens[0].hasLeadingWhitespace)
                    matches[leftExpressionIndex].tokens[lastIndex] = reduction
                    matches[leftExpressionIndex].stop = right.stop
                    matches.remove(at: rightExpressionIndex)
                    // if right expr was atom/prefix operator, copy the reduced value to the start of the new right-hand expr as well
                    if !right.match.definition.hasLeadingExpression && rightExpressionIndex < matches.count {
                        matches[rightExpressionIndex].tokens[0] = reduction
                    }
                }
            } else {
                // TO DO: this also happens if an operator match is missing from matches (which is itself probably a bug)
                //assert(left.stop < right.start) // left.stop == right.start-1, they're adjacent (a larger gap suggests a missing matcher)
                print("no shared operand:\n\t", left, "\n\t", right)
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
        return matches[0].tokens.reductionFor(completedMatch: matches[0].match)
    }
    
    
    
    
    func reductionForArgument(_ label: Symbol, from startIndex: Int, to stopIndex: Int) -> Value {
        //print("Label \(name) terminates \(argumentLabel) argument at \(argumentStopIndex).")
        let value: Value
      //  print("reducing \(label.isEmpty ? "direct" : label.label) argument:"); self.stack.show(startIndex, stopIndex)
        let form = self.reductionForOperatorExpression(from: startIndex, to: stopIndex)
        switch form {
        case .value(let v): value = v
        default: fatalError("TODO: \(label.isEmpty ? "direct" : label.label) argument did not fully reduce: \(form)")
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
            let form = self.stack[index+1].reduction
            self.stack[index+1].matches += matchers.filter{ $0.match(form, allowingPartialMatch: true) }
            // reductionForOperatorExpression() can now reduce our newly added matchers as standard atomic/prefix operators of commandPrecedence
        }
    }
    
    
    func readLowPunctuationCommand(_ commandName: (Symbol), commandTokens: inout [CommandToken], from startIndex: Int, to stopIndex: Int) -> (command: Command, stopIndex: Int) { // startIndex..<stopIndex; these are parser stack indexes
        // reads the first command in expression (this includes reading any nested commands in its arguments and reducing those argument tokens down to argument values in the final Command; on return, commandTokens is partly/fully consumed and the new stopIndex is given)
       // print("Found command name:", commandName, "at:", startIndex)
        // TO DO: if the command name is followed by a record literal, the command *always* binds the record as FP argument syntax; if record is followed by a label that’s a syntax error
        var stopIndex = stopIndex // if command is terminated by a lower-precedence operator, that index is returned, otherwise it terminates at end of main expression
        var arguments = [Command.Argument]()
        var argumentLabel = nullSymbol
        var startIndex = startIndex + 1 // start index is initially the command name, so step over that and look for a direct argument, e.g. `foo 1 …`
        if !commandTokens.isEmpty {
            if case .label(let name) = commandTokens[0].form { // found an argument label instead (i.e. LP command has no direct argument), e.g. `foo bar: 1 …`
                commandTokens.removeFirst()
                startIndex += 1 // step over label to the argument expression
                argumentLabel = name
            }
            // now scan for argument expressions, which may be delimited by lower-precedence operators, next argument label, or the main expression’s stopIndex (e.g. linebreaks, closing parens, conjunctions)
            argumentLoop: while !commandTokens.isEmpty {
                let (index, form) = commandTokens.removeFirst()
                switch form {
                case .label(let name): // a label always terminates the previous LP argument/nested command, so reduce the preceding argument expression…
                    arguments.append((argumentLabel, self.reductionForArgument(name, from: startIndex, to: index)))
                    argumentLabel = name // …and begin reading the next argument
                    startIndex = index + 1 // step over argument label
                case .name(_):
                    self.addMatchersForNestedCommand(at: index, to: stopIndex)
                case .terminatingOperator: // a lower-precedence infix/postfix operator always right-terminates an LP/nested command's arguments list
                    stopIndex = index
                    break argumentLoop
                }
            }
        }
        // reduce the preceding argument expression (i.e. last argument of LP/nested command)
        if startIndex < stopIndex { // startIndex = name/label index + 1; stopIndex is non-inclusive
            //print("Add last LP argument: \(argumentLabel) \(startIndex)..<\(stopIndex)")
            //self.stack.show(startIndex, stopIndex)
           // print()
            let value: Value
            let form = self.reductionForOperatorExpression(from: startIndex, to: stopIndex)
            switch form {
            case .value(let v): value = v
            default: fatalError("TODO: \(argumentLabel) argument did not fully reduce: \(form)")
            }
            arguments.append((argumentLabel, value))
        }
        return (Command(commandName, arguments), stopIndex)
    }
    
    
    
    
    func reduceCommands(_ commandTokens: [(index: Int, form: CommandTokenForm)], _ stopIndex: inout Int) {
        var commandTokens = commandTokens
       // print("…found commandTokens:", commandTokens)
        while case .terminatingOperator = commandTokens[0].form {
            commandTokens.removeFirst()
        }
        guard case .name(let commandName) = commandTokens[0].form else {
            // found a label but no command name before it; for now, treat this as an error
            print("Found label before command name:", commandTokens[0].form)
            return
        }
        //print("Reading command:", commandName, commandTokens[0].index)
        var outerCommands = [(start: Int, stop: Int, command: Command)]()
        while !commandTokens.isEmpty {
            let (index, form) = commandTokens.removeFirst()
            if case .name(let commandName) = form {
                let (command, commandStopIndex) = self.readLowPunctuationCommand(commandName, commandTokens: &commandTokens, from: index, to: stopIndex) // TO DO: either return both stopIndex and commandTokens values, or pass both as inout and update in-place
                outerCommands.append((index, commandStopIndex, command))
            } // else it's either stray label (syntax error) or lower-precedence infix/postfix operator (command terminator)
        }
        //print("FOUND outer commands:", outerCommands)
        let oldStackSize = self.stack.count
        for (start, stop, command) in outerCommands.reversed() {
            self.stack.replace(from: start, to: stop, withReduction: .value(command))
        }
        stopIndex = stopIndex - (oldStackSize - self.stack.count)
    }
    
    func fullyReduceExpression(from _startIndex: Int = 0, to stopIndex: Int? = nil, allowLPCommands: Bool = false) {
        var stopIndex = stopIndex ?? self.stack.count // caution: stopIndex is nearest head of stack, so will no longer be valid once a reduction is performed
       // print("fullyReduceExpression:"); self.stack.show(_startIndex, stopIndex)
        // scan back from stopIndex until an expression delimiter is found or given startIndex is reached; that then becomes the startIndex for findLongestMatches
        // TO DO: this only goes as far back as last label; to read an entire LP command we'll need additional smarts
        let (startIndex, commandTokens) = self.stack.findStartIndex(from: _startIndex, to: stopIndex)
        //print("…found startIndex", startIndex)
        
        if !commandTokens.isEmpty {
            self.reduceCommands(commandTokens, &stopIndex)
        }
        
        if startIndex == stopIndex - 1 { // only one token in this expression
            switch self.stack[startIndex].reduction {
            case .value(_): ()
            case .quotedName(let n), .unquotedName(let n):
                self.stack.replace(from: startIndex, to: stopIndex, withReduction: .value(Command(n)))
            // TO DO: case .error(let e) should encapsulate error in BadSyntaxValue, allowing rest of code to be parsed and [in interactive/debug mode] partially run
            default:
                print("BUG/WARNING: single non-value at \(startIndex) won't be reduced: \(self.stack[startIndex].reduction)")
            }
            return
        }
        
        let form = self.reductionForOperatorExpression(from: startIndex, to: stopIndex)
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
        let startIndex = self.stack.lastIndex{ $0.matches.first{ $0.matchID == matchID } != nil }! + 1
        let stopIndex = self.stack.count
        //print("FULLY REDUCING EXPR before conjunction: .\(conjunction)…")
        self.fullyReduceExpression(from: startIndex, to: stopIndex) // start..<stop
    }
    
}
