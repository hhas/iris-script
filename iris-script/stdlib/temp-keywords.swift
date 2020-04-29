//
//  std misc.swift
//  iris-script
//

import Foundation


// used in stdlib_operators
let parseIfThenOperator         = parsePrefixOperator(named: "if", withConjunction:"then")
let parseWhileRepeatOperator    = parsePrefixOperator(named: "while", withConjunction:"repeat")
let parseRepeatWhileOperator    = parsePrefixOperator(named: "repeat", withConjunction:"while")
let parseTellToOperator         = parsePrefixOperator(named: "tell", withConjunction:"to")

let parseSetToOperator          = parsePrefixOperator(named: "set", withConjunction:"to")

// TO DO: how to generate operator definitions for non-commands?
let parseDoBlock = parseCustomBlock(withStyle: Block.Style.custom(definition: "do", terminator: "done", delimiter: "\n"))



func stdlib_loadKeywords(into registry: OperatorRegistry) {    
    // constants
    registry.add(OperatorDefinition("nothing", .atom, precedence: 0)) // TO DO: operator or command?
    
    // TO DO: need to decide on Swift- vs Icon-style semantics (one option might be to define 'true' as a wrapper struct that encloses the actual value, allowing it to be obtained when needed, e.g. when chaining conditional operators as `a < b < c`, while displaying as "true" by default; similarly, 'false' would enclose only those values that may represent a false state: `false`, `nothing`, `did_nothing` [Q. should `did_nothing` be the standard return value for comparison tests, same as for `if`, `while` flow control tests? need to ensure `did_nothing` is immediately promoted to `nothing`/`false` if not intercepted by `else` clause])
    
    registry.add(OperatorDefinition("true", .atom, precedence: 0))
    registry.add(OperatorDefinition("false", .atom, precedence: 0))
    
    // used in custom control operators (e.g. `if … then …`)
    // should be okay overloading existing operator names (e.g. `to`) as long as they are prefix/atom
    // TO DO: these should be automatically added to operator registry when adding the operator
    
    // operators of form `NAME op1 CONJUNCTION op2`
    registry.add("if", .custom(parseIfThenOperator), 104, .left, [])
    registry.add("else", .infix, 100, .right, [])
    registry.add("while", .custom(parseWhileRepeatOperator), 104, .left, [])
    registry.add("repeat", .custom(parseRepeatWhileOperator), 104, .left, [])
    registry.add("tell", .custom(parseTellToOperator), 104, .left, [])
    
    // conjunctions for above
    registry.add(OperatorDefinition("then", .infix, precedence: -99)) // low precedence forces break-out, which parsePrefixOperator will intercept, check the conjunction is correct, then ; TO DO: this is kludgy
    registry.add(OperatorDefinition("repeat", .infix, precedence: -99))
    registry.add(OperatorDefinition("while", .infix, precedence: -99))
    registry.add(OperatorDefinition("to", .infix, precedence: -99))
    
    
    // TO DO: `set a to b` doesn't work as `to` is parsed as prefix operator: `a{to{b}}`
    //registry.add("set", .custom(parseSetToOperator), 102, .left, [])
    
    // used in procedure interface
    registry.add(OperatorDefinition("returning", .infix, precedence: 300))
    
    // block
    registry.add(OperatorDefinition("do", .custom(parseDoBlock), precedence: 100)) // `do…done` // precedence is unused
    registry.add(OperatorDefinition("done", .custom(parseUnexpectedKeyword), precedence: -100)) // being atom, precedence is ignored so won't break out of loop
}
