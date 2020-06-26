//
//  literal patterns.swift
//  iris-script
//

import Foundation


// remember: homonyms bad (e.g. don't overload […] or {…} syntax to describe anything except lists and records)


private let EXPR: Pattern = .expression
private let LF: Pattern = .zeroOrMore(.lineBreak)
private let DELIM: Pattern = [.delimiter, LF] // e.g. comma, linebreak, or comma followed by linebreak



// ordered list

let orderedListLiteral = OperatorDefinition(name: "[…]", pattern:
    [.token(.startList), LF, .optional([EXPR, .zeroOrMore([DELIM, EXPR])]), LF, .token(.endList)],
                                            autoReduce: true, reducer: reduceOrderedListLiteral)



// TO DO: might want to leave left side of colon pairs as .expression and have reduce funcs report error if it's not valid (this might allow reducing colon pairs down to Pair values)

// keyed list


let keyValuePair: Pattern = [.testValue({$0 is HashableValue}), .token(.colon), EXPR] // TO DO: allow LF after colon? (the reducefunc does allow it)

let keyValueListLiteral = OperatorDefinition(name: "[…:…]", pattern:
    [.token(.startList), .anyOf([
        .token(.colon), // empty kv-list uses same literal syntax as Swift, `[:]`
        [keyValuePair, LF, .zeroOrMore([DELIM, keyValuePair]), LF] // a kv-list with one or more items
    ]), .token(.endList)], autoReduce: true, reducer: reduceKeyedListLiteral)


// record

let recordField: Pattern = [.optional(.label), EXPR] // Parser and Pattern now define .label as `NAME COLON` token sequence

let recordLiteral = OperatorDefinition(name: "{…}", pattern:
    [.token(.startRecord), LF, .optional([recordField, .zeroOrMore([DELIM, recordField])]), LF, .token(.endRecord)],
                                       autoReduce: true, reducer: reduceRecordLiteral)


// group/parenthesized block

let groupLiteral = OperatorDefinition(name: "(…)", pattern:
    [.token(.startGroup), LF, EXPR, LF, .token(.endGroup)], autoReduce: true, reducer: reduceGroupLiteral)

let parenthesizedBlockLiteral = OperatorDefinition(name: "(…,…)", pattern:
    [.token(.startGroup), LF, .optional([EXPR, .oneOrMore([DELIM, EXPR])]), LF, .token(.endGroup)],
                                      autoReduce: true, reducer: reduceParenthesizedBlockLiteral)


// command

// challenge with matching commands is that 1. LP syntax is superset of standard `NAME EXPR` syntax, and 2. LP syntax should not nest (reducefunc will need to handle nested commands somehow); one more gotcha of LP syntax is when first arg is itself a record literal (i.e. command must be written `name {{…}}`; the advantages of LP syntax, particularly when using the language as a command shell, are such that this compromise should be worth it, but it will have to be tested in real-world use to verify)



// TO DO: using patterns to match FP commands will only conflict with hardcoded behavior for LP commands, so best delete

//let labeledValue = OperatorDefinition(name: "«LABELEDVALUE»", pattern:
//    [.label, .expression], precedence: commandPrecedence, reducer: reducePairLiteral)

// full punctuation command with argument can be implemented as pattern
//let commandLiteral = OperatorDefinition(name: "«COMMAND»", pattern:
//    [.name, .testValue({$0 is Record})], autoReduce: true, reducer: reduceCommandLiteral)



//let pairLiteral = OperatorDefinition(name: "«LABEL»", pattern:
//    [.label, .token(.colon), EXPR], reducer: reducePairLiteral) // TO DO: what precedence? (should be very low, but presumably not as low as `to` operator) what associativity? (.none or .right?)


// TO DO: what about colon pairs for name-value bindings in block contexts? (convenient for declaring constants, properties)

// TO DO: what about colon pairs for `interface:action` callable definitions? (to avoid parsing problems, we're using `to…run…`, `when…run…`; to define an unbound proc, use `procedure…run…`? Q. what about `ignoring unknown arguments` option?)


// TO DO: pretty sure `;` shouldn't need precedence: it should always delimit exprs in the same way that comma, period, etc do; for now though we keep the value that was defined in Token.Form.precedence
let pipeLiteralPrecedence: Precedence = 96 // important: precedence needs to be higher than expr sep punctuation (comma, period, etc), but lower than lp command’s argument label [Q. lp command argument shouldn't have precedence]


let pipeLiteral = OperatorDefinition(name: "«PIPE»", pattern:
[EXPR, .token(.semicolon), EXPR], // TO DO: allow LF after semicolon?
                                  precedence: pipeLiteralPrecedence,
                                  reducer: reducePipeOperator)

