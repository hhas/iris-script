//
//  stdlib_operators.swift
//
//  Bridging code for primitive handlers. This file is auto-generated; do not edit directly.
//

// TO DO: need to update glue generator and glue definition before regenerating this file

import Foundation

func stdlib_loadOperators(into registry: OperatorRegistry) {
    
    registry.atom("nothing") // analogous to Python's `None`
    registry.atom("did_nothing") // returned by `if`, loops when their action is not performed; it can be intercepted by `else` to perform its alternate action, otherwise it should degrade to standard `nothing` when next evaled
    
    // TO DO: need to decide on Swift- vs Icon-style semantics (one option might be to define 'true' as a wrapper struct that encloses the actual value, allowing it to be obtained when needed, e.g. when chaining conditional operators as `a < b < c`, while displaying as "true" by default; similarly, 'false' would enclose only those values that may represent a false state: `false`, `nothing`, `did_nothing` [Q. should `did_nothing` be the standard "false" value returned by comparison operators, same as for `if`, `while` flow control tests? could be dicey? if so, would need to ensure `did_nothing` is immediately promoted to `nothing`/`false` if not intercepted by `else` clause])
    registry.atom("true")
    registry.atom("false")
    
    // TO DO: `optional`, `editable` prefix operators for constructing coercions (they're commonly used so will allow command operand to use LP syntax as long as their precedence is set lower than argument precedence, e.g. `foo as optional list of: string min: 1 max: 10` -> `as{foo{},optional{list{of:string{},min:1,max:10}}}`)
    
    // flow control
    registry.prefix("if", conjunction: "then", 104)
    registry.infix("else", 100, .right)
    registry.prefix("while", conjunction: "repeat", 104)
    registry.prefix("repeat", conjunction: "while", 104)
    registry.prefix("tell", conjunction: "to", 104)
        
    // used in procedure interface
    registry.infix("returning", 300)
    
    // block
    registry.prefix("do", suffix: "done")
    
    // assignment // TO DO: what should LH operand pattern be?
    registry.prefix("set", conjunction: "to", 102)

    
    registry.infix(Keyword("^", "to_the_power_of"), 600, .right) // TO DO: rename "pow"? (AS uses caret accent char, but that rather abuses our "honest symbols" rule [e.g. don't use `$` to denote anything except currency])
    registry.prefix(Keyword("positive", "+", "＋"), 598, reducer: reducePositiveOperator) // TO DO: canonical name should be "+" and operator should determine which handler to bind by matching argument record label[s] (we need to implement some form of multimethods for this)
    registry.prefix(Keyword("negative", "-", "－", "−", "﹣"), 598, reducer: reduceNegativeOperator) // TO DO: ditto
    registry.infix(Keyword("*", "×", "multiplied_by"), 596)
    registry.infix(Keyword("/", "÷", "divided_by"), 596)
    registry.infix("div", 596)
    registry.infix("mod", 596)
    registry.infix(Keyword("+", "＋", "plus"), 590)
    registry.infix(Keyword("-", "－", "−", "﹣", "minus"), 590)
    registry.infix(Keyword("<", "is_less_than"), 540)
    registry.infix(Keyword("≤", "<=", "is_less_than_or_equal_to", "is_not_greater_than"), 540)
    registry.infix(Keyword("=", "==", "is_equal_to"), 540)
    registry.infix(Keyword("≠", "<>", "is_not_equal_to"), 540)
    registry.infix(Keyword(">", "is_greater_than"), 540)
    registry.infix(Keyword("≥", ">=", "is_greater_than_or_equal_to", "is_not_less_than"), 540)
    registry.prefix("NOT", 400)
    registry.infix("AND", 398)
    registry.infix("OR", 396)
    registry.infix("XOR", 394)
    registry.infix("is_before", 540)
    registry.infix(Keyword("is_not_after", "is_before_or_same_as"), 540)
    registry.infix("is", 540)
    registry.infix("is_not", 540)
    registry.infix("is_after", 540)
    registry.infix(Keyword("is_not_before", "is_same_as_or_after"), 540)
    registry.infix("begins_with", 542)
    registry.infix("ends_with", 542)
    registry.infix("contains", 542)
    registry.infix("is_in", 542)
    registry.infix(Keyword("&", "joined_with"), 340)
    registry.infix("is_a", 540) // TO DO: pattern? (RH should always be a command)
    registry.infix("as", 350) // TO DO: pattern? (RH should always be a command)
    registry.prefix("to", conjunction: "run", 180) // TO DO: precedence, associativity? // TO DO: one problem with defining `run` as keyword is that `run…` is also a standard command name (still, the same can be said of `set…to…` and `get…[as…]` and those will probably be defined as operators for usability [e.g. allows `set`'s RH operand to be an LP command])
    registry.prefix("when", conjunction: "run", 180) // TO DO: ditto

    // references should always bind tighter than command arguments so that they can be used in LP commands without requiring parentheses
    
    registry.infix("of", 1306, .right)
    registry.infix("at", 1310)
    registry.infix("named", 1310)
    registry.infix("id", 1310)
    registry.infix("from", 1310)
    registry.infix(Keyword("where", "whose"), 1310)
    registry.infix("thru", 1330)
    registry.prefix("first", 1320)
    registry.prefix("middle", 1320)
    registry.prefix("last", 1320)
    registry.prefix(Keyword("any", "some"), 1320)
    registry.prefix(Keyword("every", "all"), 1320)
    registry.infix("before", 1320)
    registry.infix("after", 1320)
    registry.prefix("before", 1320)
    registry.prefix("after", 1320)
    registry.atom("beginning")
    registry.atom("end")
}


