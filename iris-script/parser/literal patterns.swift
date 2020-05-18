//
//  literal patterns.swift
//  iris-script
//

import Foundation


// TO DO: ignore linebreaks

// CAUTION: for now, avoid creating matchers for patternseqs that start with a composite pattern as that is not yet supported

// TO DO: still need to decide how to back-match infix/postfix operators


// ordered list

let orderedListLiteral = OperatorDefinition(name: "[…]", pattern:
    [.token(.startList), .optional([.expression, .zeroOrMore([.delimiter, .expression])]), .token(.endList)],
                                            autoReduce: true, reducer: reduceOrderedListLiteral)



// TO DO: might want to leave left side of colon pairs as .expression and have reduce funcs report error if it's not valid (this might allow reducing colon pairs down to Pair values)

// keyed list

private func isHashableLiteral(_ form: Token.Form) -> Pattern.MatchResult {
    if case .value(let v) = form, v is HashableValue { return .fullMatch } else { return .noMatch }
}

let keyValuePair: Pattern = [.test(isHashableLiteral), .token(.colon), .expression]

let keyValueListLiteral = OperatorDefinition(name: "[…:…]", pattern:
    [.token(.startList), .anyOf([
        .token(.colon),
        [keyValuePair, .zeroOrMore([.delimiter, keyValuePair])]
    ]), .token(.endList)], autoReduce: true, reducer: reduceKeyedListLiteral)


// record

let recordField: Pattern = [.optional([.label, .token(.colon)]), .expression]

let recordLiteral = OperatorDefinition(name: "{…}", pattern:
    [.token(.startRecord), .optional([recordField, .zeroOrMore([.delimiter, recordField])]), .token(.endRecord)],
                                       autoReduce: true, reducer: reduceRecordLiteral)


// group/parenthesized block

let groupLiteral = OperatorDefinition(name: "(…)", pattern:
    [.token(.startGroup), .expression, .token(.endGroup)], autoReduce: true, reducer: reduceGroupLiteral)

let parenthesizedBlockLiteral = OperatorDefinition(name: "(…,…)", pattern:
    [.token(.startGroup), .optional([.expression, .oneOrMore([.delimiter, .expression])]), .token(.endGroup)],
                                      autoReduce: true, reducer: reduceParenthesizedBlockLiteral)


// command

// challenge with matching commands is that 1. LP syntax is superset of standard `NAME EXPR` syntax, and 2. LP syntax should not nest (reducefunc will need to handle nested commands somehow); one more gotcha of LP syntax is when first arg is itself a record literal (i.e. command must be written `name {{…}}`; the advantages of LP syntax, particularly when using the language as a command shell, are such that this compromise should be worth it, but it will have to be tested in real-world use to verify)

//let commandLiteral = OperatorDefinition(name: "COMMAND", pattern:
//    [.name, .optional(.expression), .zeroOrMore(recordField)], reducer: reduceCommandLiteral)

// for now, match FP command syntax only
let commandLiteral = OperatorDefinition(name: "COMMAND", pattern:
    [.name, .optional(.expression)], reducer: reduceCommandLiteral)



// TO DO: what about colon pairs for name-value bindings in block contexts? (convenient for declaring constants, properties)

// TO DO: what about colon pairs for `interface:action` callable definitions?



// need a way to reify a pattern up to first operatorName

// TO DO: conjunctions should trigger reduction (what if conjunction is also non-conjunction)

func match(operatorGroup: OperatorGroup, to stack: inout Parser.Stack) -> [PatternMatcher] {
    
    var m = [PatternMatcher]()
    
    // TO DO: should this be moved to shift()? (it would mean shift's 2nd parameter becomes [OpDef] instead of [PatternMatcher])
    print("MATCH OP")
    for definition in operatorGroup.definitions {
        // TO DO: is there any situation where neither first nor second pattern is a keyword?
        //print("back-matching:", definition)
        // temporary kludge
        for pattern in reifySequence(definition.pattern) {
            print("--matching ", pattern)
            if case .keyword(let k) = pattern[0], k.matches(operatorGroup.name) { // prefix operator
                let newMatch = PatternMatcher(for: definition)
                print("  adding matcher for ‘\(operatorGroup.name.label)’:", newMatch)
                m.append(newMatch)
                // print("matched prefix op", newMatch)
            } else if case .expression = pattern[0] {
                print("backmatching…")
                for pattern in reifySequence([Pattern](pattern.dropFirst())) {
                    
                    if let next = pattern.first, case .keyword(let k) = next, k.matches(operatorGroup.name) { // infix/postfix operator
                        if let last = stack.last {
                            // print("checking last", last.reduction)
                            if case .value(_) = last.reduction { // TO DO: this needs work as .value is not the only valid Reduction: stack's head can also be an unreduced command or LP argument, but we don't know if we should reduce that command now or later (we have to finish matching the operator in order to know the operator's precedence, at which point we can determine which to reduce first: command (into an operand) or operator (into an argument)); Q. do we actually need to know if EXPR is a valid expression to proceed with the match? if it looks like it *could* be reduced later on (i.e. it's not a linebreak or punctuation), that might be enough to proceed with match for now
                                let newMatch = PatternMatcher(for: definition)
                                print("  adding matcher for ‘\(operatorGroup.name.label)’:", newMatch)
                                stack[stack.count-1].matches.append(newMatch) // add matcher to head of stack, before operator name is shifted onto it
                                // shift() will carry this forward from head of stack
                                //print("matched infix/postfix op", newMatch)
                            }
                        }
                    }
                }
            }
        }
    }
    return []
}
