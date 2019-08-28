//
//  std misc.swift
//  iris-script
//

import Foundation




func stdlib_loadKeywords(into registry: OperatorRegistry) {
    /*
    registry.add(OperatorDefinition("of", .infix, precedence: 900))
    registry.add(OperatorDefinition("at", .infix, precedence: 940, aliases: ["at_index"])) // by index/range
    registry.add(OperatorDefinition("thru", .infix, precedence: 960, aliases: ["through"])) // range clause
    registry.add(OperatorDefinition("named", .infix, precedence: 940)) // by name
    registry.add(OperatorDefinition("id", .infix, precedence: 940)) // by ID // TO DO: what about `id` properties? either we define an "id" .atom, or we need some way to tell parser that only infix `id` should be treated as an operator and other forms should be treated as ordinary [command] name
    registry.add(OperatorDefinition("where", .infix, precedence: 940, aliases: ["whose"])) // by test
    registry.add(OperatorDefinition("first", .prefix, precedence: 930)) // absolute ordinal
    registry.add(OperatorDefinition("middle", .prefix, precedence: 930))
    registry.add(OperatorDefinition("last", .prefix, precedence: 930))
    registry.add(OperatorDefinition("any", .prefix, precedence: 930, aliases: ["some"]))
    registry.add(OperatorDefinition("every", .prefix, precedence: 930))
    registry.add(OperatorDefinition("before", .infix, precedence: 930)) // relative
    registry.add(OperatorDefinition("after", .infix, precedence: 930))
    registry.add(OperatorDefinition("before", .prefix, precedence: 930)) // insertion
    registry.add(OperatorDefinition("after", .prefix, precedence: 930))
    registry.add(OperatorDefinition("beginning", .atom, precedence: 930))
    registry.add(OperatorDefinition("end", .atom, precedence: 930))
    // control structures
    // TO DO: what precedence for these operators? (also consider whether tell/if/while should just be commands; main reason to prefer operators is that operators can customize parsing for right operand to take a complete sentence, whereas a command only consumes up to the next comma)
    registry.add(OperatorDefinition("tell", .custom(parsePrefixControlOperator(withConjunction: "to")), precedence: 100))
    
    registry.add(OperatorDefinition("while", .custom(parsePrefixControlOperator(withConjunction: "repeat")), precedence: 100))
    // TO DO: .custom
    */
    
    // constants
    registry.add(OperatorDefinition("nothing", .atom, precedence: 0)) // TO DO: operator or command?
    
    // TO DO: need to decide on Swift- vs Icon-style semantics (one option might be to define 'true' as a wrapper struct that encloses the actual value, allowing it to be obtained when needed, e.g. when chaining conditional operators as `a < b < c`, while displaying as "true" by default; similarly, 'false' would enclose only those values that may represent a false state: `false`, `nothing`, `did_nothing` [Q. should `did_nothing` be the standard return value for comparison tests, same as for `if`, `while` flow control tests? need to ensure `did_nothing` is immediately promoted to `nothing`/`false` if not intercepted by `else` clause])
    
    registry.add(OperatorDefinition("true", .atom, precedence: 0))
    registry.add(OperatorDefinition("false", .atom, precedence: 0))
    
    // used in custom control operators
    registry.add(OperatorDefinition("then", .custom(parseUnexpectedKeyword), precedence: -100))
    registry.add(OperatorDefinition("repeat", .custom(parseUnexpectedKeyword), precedence: -100))
    
    // used in procedure interface
    registry.add(OperatorDefinition("returning", .infix, precedence: 300))
    
    // block
    registry.add(OperatorDefinition("do", .custom(parseDoBlock), precedence: 100)) // `do…done` // precedence is unused
    registry.add(OperatorDefinition("done", .custom(parseUnexpectedKeyword), precedence: -100)) // being atom, precedence is ignored so won't break out of loop
}
