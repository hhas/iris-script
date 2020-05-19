//
//  literal patterns.swift
//  iris-script
//

import Foundation


// TO DO: ignore linebreaks

// CAUTION: for now, avoid creating matchers for patternseqs that start with a composite pattern as that is not yet supported

// TO DO: still need to decide how to back-match infix/postfix operators


let pipeOperator = OperatorDefinition(name: ";", pattern:
    [.expression, .token(.semicolon), .expression],
                                      precedence: Token.Form.semicolon.precedence, associate: .right,
                                      reducer: reducePipeOperator)


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


