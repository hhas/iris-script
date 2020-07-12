//
//  stdlib_operators.swift
//
//  Bridging code for primitive handlers. This file is auto-generated; do not edit directly.
//

// TO DO: need to update glue generator and glue definition before regenerating this file

// TO DO: try implementing a repeating pattern for `&` operator, e.g. `foo & bar & baz` should reduce to a single command that joins an N-ary list of operands in a single operation (aside from testing parser implementation, this should also simplify partial evaluation and allow cross-compilation to idiomatic Swift code as interpolated string literals)

// TO DO: need to decide on Swift- vs Icon-style semantics (one option might be to define 'true' as a wrapper struct that encloses the actual value, allowing it to be obtained when needed, e.g. when chaining conditional operators as `a < b < c`, while displaying as "true" by default; similarly, 'false' would enclose only those values that may represent a false state: `false`, `nothing`, `did_nothing` [Q. should `did_nothing` be the standard "false" value returned by comparison operators, same as for `if`, `while` flow control tests? could be dicey? if so, would need to ensure `did_nothing` is immediately promoted to `nothing`/`false` if not intercepted by `else` clause])


import Foundation

func stdlib_loadOperators(into registry: OperatorRegistry) {
    registry.infix("^", 1300, .right)
    registry.prefix("+", 1298, reducer: reductionForPositiveOperator)
    registry.prefix("-", 1298, reducer: reductionForNegativeOperator)
    registry.infix("*", 1296, .left)
    registry.infix("/", 1296, .left)
    registry.infix("div", 1296, .left)
    registry.infix("mod", 1296, .left)
    registry.infix("+", 1290, .left)
    registry.infix("-", 1290, .left)
    registry.infix("<", 540, .left)
    registry.infix("≤", 540, .left)
    registry.infix("=", 540, .left)
    registry.infix("≠", 540, .left)
    registry.infix(">", 540, .left)
    registry.infix("≥", 540, .left)
    registry.prefix("NOT", 400)
    registry.infix("AND", 398, .left)
    registry.infix("OR", 396, .left)
    registry.infix("XOR", 394, .left)
    registry.infix("is_before", 540, .left)
    registry.infix("is_not_after", 540, .left)
    registry.infix("is_same_as", 540, .left)
    registry.infix("is_not_same_as", 540, .left)
    registry.infix("is_after", 540, .left)
    registry.infix("is_not_before", 540, .left)
    registry.infix("begins_with", 542, .left)
    registry.infix("ends_with", 542, .left)
    registry.infix("contains", 542, .left)
    registry.infix("is_in", 542, .left)
    registry.infix("&", 340, .left)
    registry.infix("is_a", 540, .left)
    registry.infix("as", 350, .left)
    registry.prefix("to", 80)
    registry.prefix("when", 80)
    registry.prefix("set", conjunction: "to", 80)
    registry.prefix("if", conjunction: "then", alternate: "else", 101)
    registry.prefix("while", conjunction: "repeat", 101)
    registry.prefix("repeat", conjunction: "while", 101)
    registry.prefix("tell", conjunction: "to", 101)
    registry.infix("of", 1100, .left)
    registry.infix("at", 1110, .right)
    registry.infix("named", 1110, .left)
    registry.infix("id", 1110, .left)
    registry.infix("from", 1110, .left)
    registry.infix("whose", 1110, .left)
    registry.infix("thru", 1120, .left)
    registry.prefix("first", 1130)
    registry.prefix("middle", 1130)
    registry.prefix("last", 1130)
    registry.prefix("any", 1130)
    registry.prefix("every", 1130)
    registry.infix("before", 1126, .left)
    registry.infix("after", 1126, .left)
    registry.prefix("before", 1106)
    registry.prefix("after", 1106)
    registry.atom("beginning")
    registry.atom("end")
    
    
    // TO DO: these entries need to be autogenerated:
    
    registry.atom("nothing") // analogous to Python's `None`
    registry.atom("did_nothing") // returned by `if`, loops when their action is not performed; it can be intercepted by `else` to perform its alternate action, otherwise it should degrade to standard `nothing` when next evaled
    
    registry.atom("true")
    registry.atom("false")
    // used in procedure interface
    registry.infix("returning", 300)
    // block
    registry.prefix("do", suffix: "done")
    // TO DO: `optional`, `editable` prefix operators for constructing coercions (they're commonly used so will allow command operand to use LP syntax as long as their precedence is set lower than argument precedence, e.g. `foo as optional list of: string min: 1 max: 10` -> `as{foo{},optional{list{of:string{},min:1,max:10}}}`)

    
    
    
    
}
