//
//  literal patterns.swift
//  iris-script
//

import Foundation


// CAUTION: for now, avoid creating matchers for patternseqs that start with a composite pattern as that is not yet supported


private let EXPR: Pattern = .expression
private let LF: Pattern = .zeroOrMore(.lineBreak)
private let DELIM: Pattern = [.delimiter, LF] // e.g. comma, linebreak, or comma followed by linebreak



let pipeOperator = OperatorDefinition(name: ";", pattern:
    [EXPR, .token(.semicolon), EXPR], // TO DO: allow LF after semicolon?
                                      precedence: Token.Form.semicolon.precedence, associate: .right,
                                      reducer: reducePipeOperator)


// ordered list

let orderedListLiteral = OperatorDefinition(name: "[…]", pattern:
    [.token(.startList), LF, .optional([EXPR, .zeroOrMore([DELIM, EXPR])]), LF, .token(.endList)],
                                            autoReduce: true, reducer: reduceOrderedListLiteral)



// TO DO: might want to leave left side of colon pairs as .expression and have reduce funcs report error if it's not valid (this might allow reducing colon pairs down to Pair values)

// keyed list

private func isHashableLiteral(_ form: Token.Form) -> Pattern.MatchResult {
    if case .value(let v) = form, v is HashableValue { return .fullMatch } else { return .noMatch }
}

let keyValuePair: Pattern = [.test(isHashableLiteral), .token(.colon), EXPR] // TO DO: allow LF after colon? (the reducefunc does allow it)

let keyValueListLiteral = OperatorDefinition(name: "[…:…]", pattern:
    [.token(.startList), .anyOf([
        .token(.colon),
        [keyValuePair, LF, .zeroOrMore([DELIM, keyValuePair]), LF]
    ]), .token(.endList)], autoReduce: true, reducer: reduceKeyedListLiteral)


// record

let recordField: Pattern = [.optional([.label, .token(.colon)]), EXPR]

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

//let commandLiteral = OperatorDefinition(name: "COMMAND", pattern:
//    [.name, .optional(EXPR), .zeroOrMore(recordField)], reducer: reduceCommandLiteral)

// for now, match FP command syntax only
let commandLiteral = OperatorDefinition(name: "COMMAND", pattern:
    [.name, .optional(EXPR)], reducer: reduceCommandLiteral)



// TO DO: what about colon pairs for name-value bindings in block contexts? (convenient for declaring constants, properties)

// TO DO: what about colon pairs for `interface:action` callable definitions?


