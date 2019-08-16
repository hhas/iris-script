//
//  stdlib_operators.swift
//  iris-script
//

import Foundation


func stdlib_loadOperators(into registry: OperatorRegistry) {
    registry.add(OperatorDefinition("true", .atom, precedence: 0))
    registry.add(OperatorDefinition("false", .atom, precedence: 0))
    registry.add(OperatorDefinition("\u{FF0B}", .prefix, precedence: 800, aliases: ["+"])) // full-width plus
    registry.add(OperatorDefinition("\u{2212}", .prefix, precedence: 800, aliases: ["-", "\u{FF0D}", "\u{FE63}"])) // full-width minus
    registry.add(OperatorDefinition("×", .infix, precedence: 600, aliases: ["*"]))
    registry.add(OperatorDefinition("÷", .infix, precedence: 600, aliases: ["/"]))
    registry.add(OperatorDefinition("\u{FF0B}", .infix, precedence: 590, aliases: ["+"])) // full-width plus
    registry.add(OperatorDefinition("\u{2212}", .infix, precedence: 590, aliases: ["-", "\u{FF0D}", "\u{FE63}"])) // full-width minus
    // chunk expressions
    registry.add(OperatorDefinition("of", .infix, precedence: 900))
    registry.add(OperatorDefinition("at", .infix, precedence: 910)) // by index/range
    registry.add(OperatorDefinition("thru", .infix, precedence: 920)) // range clause
    registry.add(OperatorDefinition("named", .infix, precedence: 910)) // by name
    registry.add(OperatorDefinition("id", .infix, precedence: 910)) // by ID // TO DO: what about `id` properties? either we define an "id" .atom, or we need some way to tell parser that only infix `id` should be treated as an operator and other forms should be treated as ordinary [command] name
    registry.add(OperatorDefinition("where", .infix, precedence: 910, aliases: ["whose"])) // by test
    registry.add(OperatorDefinition("first", .prefix, precedence: 930)) // absolute ordinal
    registry.add(OperatorDefinition("middle", .prefix, precedence: 930))
    registry.add(OperatorDefinition("last", .prefix, precedence: 930))
    registry.add(OperatorDefinition("any", .prefix, precedence: 930))
    registry.add(OperatorDefinition("every", .prefix, precedence: 930))
    registry.add(OperatorDefinition("before", .infix, precedence: 930)) // relative
    registry.add(OperatorDefinition("after", .infix, precedence: 930))
    registry.add(OperatorDefinition("before", .prefix, precedence: 930)) // insertion
    registry.add(OperatorDefinition("after", .prefix, precedence: 930))
    registry.add(OperatorDefinition("beginning", .atom, precedence: 930))
    registry.add(OperatorDefinition("end", .atom, precedence: 930))
    // control structures
    // TO DO: these all need to take two right-hand operands, either by using a custom parsefunc that looks for 'conjugating' word ('to', 'then', etc) or a comma delimiter, or by taking an array of conjugating words/symbols which standard parser will process; either way, these need encoded as .customPrefix(_) and .customInfix(_) [in principle, we could also have .customPrefix(parseFunc) where the parseFunc finishes on keyword `end` instead of an EXPR, which'd let us emulate AS's block statements, but loathe to do so as that breaks composability; it'd also require each word to include linebreaking/delimiting rules and just gets messy in general]
    // note: if we want to keep this somewhat introspectable, we can't use custom parseFuncs; however, we could use an array of Pattern enums (.keyword, .expression, .delimiter/.lineBreak?; caveat we don't want to allow `keyword keyword` as a pattern, as in AS's `repeat while EXPR …`, or `expr expr` either given that that pattern overlaps command's `name expr`)
    // TO DO: what about `do…done`? (technically that’s a customPrefix(parseFunc) job, since the content is an expr seq potentially containing multiple sentences, that only ends on a clearly delimited `done`)
    // TO DO: how much does PP need to know in order to provide general 'keyword' (operatorName) highlighting?
    registry.add(OperatorDefinition("tell", .prefix, precedence: 100))
    registry.add(OperatorDefinition("if", .prefix, precedence: 100))
    registry.add(OperatorDefinition("to", .prefix, precedence: 100))
    registry.add(OperatorDefinition("when", .prefix, precedence: 100))
}