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

        
    func findStartIndex(from startIndex: Int, to stopIndex: Int) -> (Int, [CommandIndex]) {
        // TO DO: what if labels are found but no command names? presumably that's a syntax error
        var commandIndexes = [CommandIndex]()
        var hasCommands = false
        for i in stride(from: stopIndex - 1, to: startIndex - 1, by: -1) {
            let form = self.stack[i].reduction
            switch form { // can't use Token.isLeftDelimited as that's not implemented
            case .semicolon, .colon, .separator(_), .startList, .startRecord, .startGroup, .lineBreak:
                // note that .colon here typically denotes kv-list item; TO DO: what about records? when we reduce record values, we need to stop on the colon even though it's already been partly reduced to a .label
                return (i + 1, commandIndexes.reversed()) // TO DO: what if this returns on the first token checked? the index returned will be stopIndex, which is out of range
            case .unquotedName(let n), .quotedName(let n):
                commandIndexes.append((i, .name(n)))
                hasCommands = true
            case .label(let n):
                commandIndexes.append((i, .label(n)))
            case .operatorName(let d): // we need this to determine where commands are right-delimited by infix/postfix operators of lower precedence
                // when parsing commands, we only need consider operators that appear after a command name
                if hasCommands { commandIndexes.append((i, .operatorName(d))) }
            default: ()
            }
        }
        return (startIndex, commandIndexes.reversed())
    }
    
    
    
    func reductionForOperatorExpression(from startIndex: Int, to stopIndex: Int) -> Token.Form {
        // reduces an expression composed of one or more operations
        // important: any commands within the expression must already be reduced to .value(Command(…))
        if startIndex == stopIndex - 1 {
            return self.stack[startIndex].reduction // presumably already reduced
        }
        var matches = self.stack.findLongestMatches(from: startIndex, to: stopIndex)
        if matches.isEmpty { // TO DO: also empty if it's already a reduced .value/.error
            print("BUG/WARNING: Can't fully reduce \(startIndex)..<\(stopIndex) as no full matches found:")
            self.stack.show(startIndex, stopIndex)
            return .error(InternalError(description: "Can't fully reduce \(startIndex)..<\(stopIndex) as no full matches found."))
        }
        if matches[0].start != startIndex {print("BUG: Missing first matcher[s] for \(startIndex)...\(matches[0].start)")}
        if matches.last!.stop != stopIndex-1 {print("BUG: Missing last matcher[s] for \(matches.last!.stop)...\(stopIndex-1)")}
        
        matches.show() // DEBUG
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
    
    func fullyReduceExpression(from _startIndex: Int = 0, to stopIndex: Int? = nil, allowLPCommands: Bool = false) {
        var stopIndex = stopIndex ?? self.stack.count // caution: stopIndex is nearest head of stack, so will no longer be valid once a reduction is performed
        print("fullyReduceExpression:"); self.stack.show(_startIndex, stopIndex)
        // scan back from stopIndex until an expression delimiter is found or given startIndex is reached; that then becomes the startIndex for findLongestMatches
        // TO DO: this only goes as far back as last label; to read an entire LP command we'll need additional smarts
        let (startIndex, commandIndexes) = self.findStartIndex(from: _startIndex, to: stopIndex)
        
        // TO DO: we might be able to read LP commands using matchers if we add those matchers here (i.e. for nested commands, add non-LP matcher only)

        print("…found startIndex", startIndex)
        if !commandIndexes.isEmpty {
            print("…found commandIndexes:", commandIndexes)
            guard case .name(let commandName) = commandIndexes[0].form else {
                // found a label but no command name before it; for now, treat this as an error
                print("Found label before command name:", commandIndexes[0].form)
                return
            }
            print("Reading command:", commandName, commandIndexes[0].index)
            /*
            if commandIndexes.count == 1 { // there are no labeled args, no trailing operators, and no other commands so we can immediately reduce this command // TO DO: this is wrong: LP command may have a direct [non-record literal] arg so we need to look for that before concluding [un]quotedName token is an arg-less command
                let index = commandIndexes[0].index
                let value = Command(commandName)
                self.stack.replace(from: index, to: index + 1, withReduction: .value(value))
            } */
            
            var i = 0
            
            var outerCommands = [(start: Int, stop: Int, name: Symbol, arguments: [Command.Argument])]()
            
            
            //var foundArguments = [(label: Symbol, start: Int, stop: Int, tokens: [StackItem])]()
            // Q. what about using same divide strategy as operators?
            
            while i < commandIndexes.count {
                let (index, form) = commandIndexes[i]
                i += 1 // step over command name to start of LP arguments (if any); this item may be an EXPR or LABEL
                var commandStopIndex = -1
                if case .name(let commandName) = form {
                    print("Found command name:", commandName, "at:", index)
                    // TO DO: if the command name is followed by a record literal, the command *always* binds the record as FP argument syntax; if record is followed by a label that’s a syntax error
                    outerCommands.append((start: index, stop: -1, name: commandName, arguments: []))
                    var argumentLabel = nullSymbol
                    var argumentStartIndex = index + 1 // this assumes nothing between
                    argumentLoop: while i < commandIndexes.count {
                        let (index, form) = commandIndexes[i]
                        switch form {
                        case .operatorName(let d):
                            // determine if operator terminates the command or is part of an LP argument
                            let (minPrecedence, maxPrecedence) = d.filter{ $0.hasLeadingExpression }.reduce(
                                (Precedence.max, Precedence.min), { (min($0.0, $1.precedence), max($0.1, $1.precedence)) })
                            if maxPrecedence > commandPrecedence && minPrecedence < commandPrecedence {
                                fatalError("Cannot resolve precedence between command \(commandName) and overloaded operator \(d.name) as operator precedences are not all higher or all lower than command.")
                            }
                            if maxPrecedence < commandPrecedence { // reduce command first (i.e. operator right-terminates command's arguments)
                                commandStopIndex = index // non-inclusive
                                print("Operator \(d.name) terminates command \(commandName)’s arguments at \(commandStopIndex)")
                                break argumentLoop
                            } else {
                                print("Operator \(d.name) at \(index) is part of command \(commandName)’s arguments.")
                                
                                
                            }
                        case .label(let name): // a label always terminates the previous LP argument
                            let argumentStopIndex = index // non-inclusive
                            print("Label \(name) terminates \(argumentLabel) argument at \(argumentStopIndex).")
                            let value: Value
                            print("reducing argument:"); self.stack.show(argumentStartIndex, argumentStopIndex)
                            let form = self.reductionForOperatorExpression(from: argumentStartIndex, to: argumentStopIndex)
                            switch form {
                            case .value(let v): value = v
                            default: fatalError("TODO: \(argumentLabel) argument did not fully reduce: \(form)")
                            }
                            outerCommands[outerCommands.count - 1].arguments.append((argumentLabel, value))
                            argumentStartIndex = argumentStopIndex + 1 // subsequent arguments have label
                            argumentLabel = name
                        case .name(let n):
                            // important: nested commands accept an optional record or direct value argument but no LP labeled args; thus they are always terminated by a label (which is then added to outer command); where a nested command is followed by infix/postfix operator, the operator binds the inner command as its left operand if its precedence is greater than commandPrecedence, or binds the outer command if its precedence is less than commandPrecedence (users can still override by parenthesizing, of course); e.g.:
                            // `foo bar of baz` -> `foo {bar of baz}`
                            // `foo bar + baz` -> `(foo {bar} + baz`
                            print("Found nested command \(n) at \(index).")
                        }
                        
                        
                        
                        
                        
                        i += 1
                    }
                    if commandStopIndex == -1 { commandStopIndex = stopIndex }

                    outerCommands[outerCommands.count - 1].stop = commandStopIndex

                    if argumentStartIndex < commandStopIndex { // TO DO: not sure what this check should be
                        print("Add last LP argument: \(argumentLabel) \(argumentStartIndex)..<\(commandStopIndex)")
                        let value: Value
                        let form = self.reductionForOperatorExpression(from: argumentStartIndex, to: commandStopIndex)
                        switch form {
                        case .value(let v): value = v
                        default: fatalError("TODO: \(argumentLabel) argument did not fully reduce: \(form)")
                        }
                        outerCommands[outerCommands.count - 1].arguments.append((argumentLabel, value))
                    }
                    
                    /*
                    if index < stopIndex - 1 { // command name is followed by an argument (this might be a .value, an unreduced operator expr, another command name) or argument label
                        let form = self.stack[index + 1].reduction
                        if case .label(let argumentName) = form {
                            
                        } else {
                            
                        }
                    }*/
                    
                    //let record = self.stack[index] as? Record
                    //let value = Command(commandName, record)
                    //self.stack.replace(from: index, to: index + 2, withReduction: .value(value))
                }
            }
            print("FOUND outer commands:", outerCommands)
            
            let oldStackSize = self.stack.count
            
            for (start, stop, name, arguments) in outerCommands.reversed() {
                self.stack.replace(from: start, to: stop, withReduction: .value(Command(name, arguments)))
            }
            
            stopIndex = stopIndex - (oldStackSize - self.stack.count)
            
            // having found all commands in expr, probably best to reduce them immediately (in reverse order) then update stopIndex
            
            // Q. would it be simpler to iterate backwards? (this means we'd detect nested command names first)
            
            
            // command names have no leading operand so can be treated as start of expr range (where expr is entire command); however, before we can reduce command expr to value, we must identify and reduce its arguments (if any)
            // this suggests we call fullyReduceExpression recursively (however, we really want to avoid repeating all this prep work, so probably best to split)
            
            
            
        }
        // TO DO: can we introduce command matchers here? we're basically looking for `command EXPR? (LABEL EXPR)*` with the added caveats that an infix/postfix operator of lower precedence acts as right delimiter for LP command, while commands appearing in argument EXPRs must be of form `command RECORD?` only // Q. when is a LABEL *not* a right delimiter for preceding EXPR?
        
        // if two labels are separated by an infix/postfix operator of lower precedence, the operator right-delimits the left command
        
        // TO DO: if final startIndex == stopIndex - 1, it should be a .value, .error, or argless command name (anything else?) so we should be able to skip straight to reducing that to .value and updating stack
        
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
