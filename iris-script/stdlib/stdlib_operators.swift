//
//  stdlib_operators.swift
//
//  Bridging code for primitive handlers. This file is auto-generated; do not edit directly.
//

import Foundation

func stdlib_loadOperators(into registry: OperatorRegistry) {
    
    registry.atom("nothing", 0) // TO DO: operator or command?
    
    // TO DO: need to decide on Swift- vs Icon-style semantics (one option might be to define 'true' as a wrapper struct that encloses the actual value, allowing it to be obtained when needed, e.g. when chaining conditional operators as `a < b < c`, while displaying as "true" by default; similarly, 'false' would enclose only those values that may represent a false state: `false`, `nothing`, `did_nothing` [Q. should `did_nothing` be the standard return value for comparison tests, same as for `if`, `while` flow control tests? need to ensure `did_nothing` is immediately promoted to `nothing`/`false` if not intercepted by `else` clause])
    registry.atom("true", 0)
    registry.atom("false", 0)
    
    // flow control
    registry.prefix("if", conjunction: "then", 104)
    registry.infix("else", 100, .right)
    registry.prefix("while", conjunction: "repeat", 104)
    registry.prefix("repeat", conjunction: "while", 104)
    registry.prefix("tell", conjunction: "to", 104)
        
    // used in procedure interface
    registry.infix("returning", 300)
    
    // block
    registry.prefix("do", terminator: "done", 100)
    
    // assignment // TO DO: what should LH operand pattern be?
    registry.prefix("set", conjunction: "to", 102)

    
    registry.infix(Keyword("^", "to_the_power_of"), 600, .right) // TO DO: rename "pow"? (AS uses caret accent char, but that rather abuses our "honest symbols" rule [e.g. don't use `$` to denote anything except currency])
    registry.prefix(Keyword("positive", "+", "＋"), 598) // TO DO: canonical name should be "+" and operator should determine which handler to bind by matching argument record label[s] (we need to implement some form of multimethods for this)
    registry.prefix(Keyword("negative", "-", "－", "−", "﹣"), 598) // TO DO: ditto
    registry.infix(Keyword("*", "×"), 596)
    registry.infix(Keyword("/", "÷"), 596)
    registry.infix("div", 596)
    registry.infix("mod", 596)
    registry.infix(Keyword("+", "＋", "plus"), 590)
    registry.infix(Keyword("-", "－", "−", "﹣", "minus"), 590)
    registry.infix("<", 540)
    registry.infix(Keyword("≤", "<="), 540)
    registry.infix(Keyword("=", "=="), 540)
    registry.infix(Keyword("≠", "<>"), 540)
    registry.infix(">", 540)
    registry.infix(Keyword("≥", ">="), 540)
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
    registry.infix("&", 340)
    registry.infix("is_a", 540) // TO DO: pattern? (RH should always be a command)
    registry.infix("as", 350) // TO DO: pattern? (RH should always be a command)
    registry.prefix("to", 180) // TO DO: pattern? (RH operand should always be colon pair)
    registry.prefix("when", 180) // TO DO: ditto

    registry.infix("of", 306, .right)
    registry.infix("at", 310)
    registry.infix("named", 310)
    registry.infix("id", 310)
    registry.infix("from", 310)
    registry.infix(Keyword("where", "whose"), 310)
    registry.infix("thru", 330)
    registry.prefix("first", 320)
    registry.prefix("middle", 320)
    registry.prefix("last", 320)
    registry.prefix(Keyword("any", "some"), 320)
    registry.prefix(Keyword("every", "all"), 320)
    registry.infix("before", 320)
    registry.infix("after", 320)
    registry.prefix("before", 320)
    registry.prefix("after", 320)
    registry.atom("beginning", 320)
    registry.atom("end", 320)
}


