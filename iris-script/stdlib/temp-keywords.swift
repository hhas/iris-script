//
//  std misc.swift
//  iris-script
//

import Foundation


// used in stdlib_operators
let parseIfThenOperator = parsePrefixControlOperator(withConjunction:"then")
let parseWhileRepeatOperator = parsePrefixControlOperator(withConjunction:"repeat")
let parseRepeatWhileOperator = parsePrefixControlOperator(withConjunction:"while")
let parseTellToOperator = parsePrefixControlOperator(withConjunction:"to")

// TO DO: how to generate operator definitions for non-commands?
let parseDoBlock = parseCustomBlock(withStyle: Block.Style.custom(definition: "do", terminator: "done", delimiter: "\n"))



func stdlib_loadKeywords(into registry: OperatorRegistry) {    
    // constants
    registry.add(OperatorDefinition("nothing", .atom, precedence: 0)) // TO DO: operator or command?
    
    // TO DO: need to decide on Swift- vs Icon-style semantics (one option might be to define 'true' as a wrapper struct that encloses the actual value, allowing it to be obtained when needed, e.g. when chaining conditional operators as `a < b < c`, while displaying as "true" by default; similarly, 'false' would enclose only those values that may represent a false state: `false`, `nothing`, `did_nothing` [Q. should `did_nothing` be the standard return value for comparison tests, same as for `if`, `while` flow control tests? need to ensure `did_nothing` is immediately promoted to `nothing`/`false` if not intercepted by `else` clause])
    
    registry.add(OperatorDefinition("true", .atom, precedence: 0))
    registry.add(OperatorDefinition("false", .atom, precedence: 0))
    
    // used in custom control operators (`if … then …`)
    registry.add(OperatorDefinition("then", .custom(parseUnexpectedKeyword), precedence: -100))
    
    // used in procedure interface
    registry.add(OperatorDefinition("returning", .infix, precedence: 300))
    
    // block
    registry.add(OperatorDefinition("do", .custom(parseDoBlock), precedence: 100)) // `do…done` // precedence is unused
    registry.add(OperatorDefinition("done", .custom(parseUnexpectedKeyword), precedence: -100)) // being atom, precedence is ignored so won't break out of loop
}
