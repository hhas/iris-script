
//
//  custom parsefuncs.swift
//  iris-script
//

// TO DO: this'll go away once temporary Pratt parser is replaced with table-driven bottom-up parser


import Foundation



// kludge
func parseCustomBlock(withStyle blockStyle: Block.Style) -> ParseFunc {
    guard case .custom(_, let terminator, _) = blockStyle else { fatalError("parseCustomBlock requires .custom(…) style.") }
    return { (_ parser: Parser, _ definition: OperatorDefinition, _ leftExpr: Value?, _ allowLooseArguments: Bool) throws -> Value in
        parser.advance(ignoringLineBreaks: true) // step over `do`
        switch parser.current.token.form {
        case .comma, .lineBreak: parser.advance(ignoringLineBreaks: true)
        case .operatorName(let operatorClass) where operatorClass.name == .word(Symbol(terminator)): return Block([], style: blockStyle)
        default: ()
        }
        let value = try parser.parseExpression()
        if case .operatorName(let operatorClass) = parser.peek(ignoringLineBreaks: true).token.form, operatorClass.name == .word("done") {
            parser.advance(ignoringLineBreaks: true)
        } else {
            print("Expected '\(terminator)' but found \(parser.current.token)")
            throw BadSyntax.unterminatedGroup
        }
        // TO DO: `done` should also act as sentence terminator
        if let seq = value as? ExpressionSequence {
            return Block(seq.items, style: blockStyle)
        } else {
            return Block([value], style: blockStyle)
        }
    }
}

// kludge: conjunction/closing names that are not already defined as operators should be declared using `registry.add("KEYWORD",.custom(parseUnexpectedKeyword))`; this will add them to list of known operator names (for code highlighting, etc) while raising a parse error if they appear anywhere out of place; as noted elsewhere, this will go away once table-driven parser is implemented
func parseUnexpectedKeyword(_ parser: Parser, _ definition: OperatorDefinition, _ leftExpr: Value?, _ allowLooseArguments: Bool) throws -> Value {
    print("Found unexpected `\(parser.current.token.content)` keyword",  leftExpr == nil ? "." : "after: \(leftExpr!)")
    throw BadSyntax.unterminatedExpression
}


func parsePrefixOperator(named operatorName: Symbol, withConjunction conjunctionName: Symbol) -> ParseFunc {
    return { (_ parser: Parser, _ definition: OperatorDefinition, _ leftExpr: Value?, _ allowLooseArguments: Bool) throws -> Value in
        if leftExpr != nil {
            print("expected delimiter before \(conjunctionName) but found: \(leftExpr!)")
            throw BadSyntax.unterminatedExpression
        }
        // print("parse control", parser.current.token)
        parser.advance()
        let leftExpr = try parser.parseExpression(allowLooseSequences: .no) // this breaks out on token before 'then'
        print(parser.current.token)
        print("LEFT", leftExpr)
        parser.advance()
        // check conjunction word is correct
        switch parser.current.token.form {
        case .comma: () // TO DO: not sure about this (e.g. `if test, action.`)
        case .operatorName(let operatorClass) where operatorClass.name == .word(conjunctionName): ()
        default: print("\(operatorName) operator expected comma or `\(conjunctionName.label)` keyword after first operand but found: `\(parser.current.token.content)`"); throw BadSyntax.unterminatedExpression
        }
        parser.advance()
        let rightExpr = try parser.parseExpression(definition.precedence, allowLooseSequences: .sentence)
        // kludge
        // TO DO: how to pick up sentence terminator?
        //print("ended sentence on", parser.peek().token)
        if let rightExpr = rightExpr as? ExpressionSequence {
            return Command(definition, left: leftExpr, right: Block(rightExpr.items, style: .sentence(terminator: Token(.period, nil, ".", " ", .last))))
        }
        return Command(definition, left: leftExpr, right: rightExpr)
    }
}


