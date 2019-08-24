//
//  stdlib_operators.swift
//  iris-script
//

import Foundation


// absolute kludge
func parseDoBlock(_ parser: Parser, _ definition: OperatorDefinition, _ leftExpr: Value?, _ allowLooseArguments: Bool) throws -> Value {
    parser.advance(ignoringLineBreaks: true) // step over `do`
    switch parser.current.token.form {
    case .comma, .lineBreak: parser.advance(ignoringLineBreaks: true)
    default: ()
    }
    //print("DO", parser.current.token)
    let value = try parser.parseExpression()
    //print("DO =", value); print(parser.current.token, parser.peek().token)
    if case .operatorName(let operatorClass) = parser.peek(ignoringLineBreaks: true).token.form, operatorClass.name == .word("done") {
        //print("found closing 'done' keyword")
        parser.advance(ignoringLineBreaks: true)
    } else {
        print("Expected 'done' but found \(parser.current.token)")
        throw BadSyntax.unterminatedGroup
    }
    // TO DO: `done` should also act as sentence terminator
    if let seq = value as? ExpressionSequence {
        return Block(seq.items, style: .custom(definition: "do", terminator: "done", delimiter: "\n"))
    } else {
        return Block([value], style: .custom(definition: "do", terminator: "done", delimiter: "\n"))
    }
}

func parseUnexpectedKeyword(_ parser: Parser, _ definition: OperatorDefinition, _ leftExpr: Value?, _ allowLooseArguments: Bool) throws -> Value {
    print("Found unexpected `\(parser.current.token.content)` keyword",  leftExpr == nil ? "." : "after: \(leftExpr!)")
    throw BadSyntax.unterminatedExpression
}


func parsePrefixControlOperator(withConjunction operatorName: Symbol) -> ParseFunc {
    return { (_ parser: Parser, _ definition: OperatorDefinition, _ leftExpr: Value?, _ allowLooseArguments: Bool) throws -> Value in
        if leftExpr != nil {
            print("expected delimiter before \(operatorName) but found: \(leftExpr!)")
            throw BadSyntax.unterminatedExpression
        }
       // print("parse control", parser.current.token)
        parser.advance()
        let leftExpr = try parser.parseExpression(allowLooseSequences: .no)
        //print(leftExpr)
        parser.advance()
        //print("parse control", parser.current.token)
        switch parser.current.token.form {
        case .comma: ()
        case .operatorName(let operatorClass) where operatorClass.name == .word(operatorName): ()
        default: print("expected comma or `\(operatorName.label)` keyword but found: `\(parser.current.token.content)`"); throw BadSyntax.unterminatedExpression
        }
        parser.advance()
        let rightExpr = try parser.parseExpression(allowLooseSequences: .sentence)
        // kludge
        // TO DO: how to pick up sentence terminator?
        //print("ended sentence on", parser.peek().token)
        if let rightExpr = rightExpr as? ExpressionSequence {
            return Command(definition, left: leftExpr, right: Block(rightExpr.items, style: .sentence(terminator: Token(.period, nil, ".", " ", .last))))
        }
        return Command(definition, left: leftExpr, right: rightExpr)
    }
}


func stdlib_loadOperators(into registry: OperatorRegistry) {
    registry.add(OperatorDefinition("nothing", .atom, precedence: 0)) // TO DO: operator or command?
    registry.add(OperatorDefinition("true", .atom, precedence: 0))
    registry.add(OperatorDefinition("false", .atom, precedence: 0))
    registry.add(OperatorDefinition("\u{FF0B}", .prefix, precedence: 800, aliases: ["+"])) // full-width plus
    registry.add(OperatorDefinition("\u{FF0D}", .prefix, precedence: 800, aliases: ["-", "\u{2212}", "\u{FE63}"])) // full-width minus
    registry.add(OperatorDefinition("×", .infix, precedence: 600, aliases: ["*"]))
    registry.add(OperatorDefinition("÷", .infix, precedence: 600, aliases: ["/"]))
    registry.add(OperatorDefinition("\u{FF0B}", .infix, precedence: 590, aliases: ["+"])) // full-width plus
    registry.add(OperatorDefinition("\u{FF0D}", .infix, precedence: 590, aliases: ["-", "\u{2212}", "\u{FE63}"])) // full-width minus
    registry.add(OperatorDefinition("=", .infix, precedence: 580, aliases: ["=="]))
    registry.add(OperatorDefinition("≠", .infix, precedence: 580, aliases: ["<>"])) // can't alias "!=" as `!` is reserved punctuation
    registry.add(OperatorDefinition("<", .infix, precedence: 580))
    registry.add(OperatorDefinition("≤", .infix, precedence: 580, aliases: ["<="]))
    registry.add(OperatorDefinition(">", .infix, precedence: 580))
    registry.add(OperatorDefinition("≥", .infix, precedence: 580, aliases: [">="]))
    
    registry.add(OperatorDefinition("&", .infix, precedence: 550))
    // TO DO: comparison operators for non-numeric values (is_same_as, is_before, etc); Q. should these have optional `as` clause, e.g. `a is_before b as case_insensitive_text`? this'd avoid scoping problems of AS's `considering`/`ignoring` blocks (Q. what to use as default if clause is not given?)
    // chunk expressions
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
    registry.add(OperatorDefinition("if", .custom(parsePrefixControlOperator(withConjunction: "then")), precedence: 100))
    registry.add(OperatorDefinition("then", .custom(parseUnexpectedKeyword), precedence: -100))
    registry.add(OperatorDefinition("while", .custom(parsePrefixControlOperator(withConjunction: "repeat")), precedence: 100))
    registry.add(OperatorDefinition("repeat", .custom(parseUnexpectedKeyword), precedence: -100))
    registry.add(OperatorDefinition("else", .infix, precedence: 90)) // lower precedence than `if`, lp commands
    // TO DO: .custom
    registry.add(OperatorDefinition("to", .prefix, precedence: 180))
    registry.add(OperatorDefinition("when", .prefix, precedence: 100))
    registry.add(OperatorDefinition("as", .infix, precedence: 350))
    registry.add(OperatorDefinition("returning", .infix, precedence: 300))
    // block
    registry.add(OperatorDefinition("do", .custom(parseDoBlock), precedence: 100)) // `do…done` // precedence is unused
    registry.add(OperatorDefinition("done", .custom(parseUnexpectedKeyword), precedence: -100)) // being atom, precedence is ignored so won't break out of loop
}
