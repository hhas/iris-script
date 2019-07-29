//
//  patterns.swift
//  iris-script
//

import Foundation




struct PatternDefinition {
    let name: String
    let pattern: Pattern
    
    init(_ name: String, _ pattern: Pattern) {
        self.name = name
        self.pattern = pattern
    }
}


// TO DO: these are rather complex; may be simpler to define block as `.oneOf([[start, anyLF, end], [start, item, .zeroPlus([separator, anyLF, item]), end]])`

func delimitedItems(_ pattern: Pattern, _ separator: Pattern) -> Pattern {
    return .optional([pattern, .zeroPlus([separator, pattern])])
}

func block(_ start: Pattern, _ pattern: Pattern, _ separator: Pattern, _ end: Pattern, _ action: Pattern) -> Pattern {
    return [start, anyLF, delimitedItems(pattern, separator), anyLF, end, action]
}

// 'some' = one, 'any' = zero or more

func ofForm(_ forms: [Token.Form]) -> Pattern {
    return .oneOf(forms.map{ .form($0) })
}
func ofForm(_ forms: Token.Form...) -> Pattern {
    return ofForm(forms)
}




let LF: Pattern = .form(.eol)
let anyLF: Pattern = .zeroPlus(LF) // optional line breaks // TO DO: how best to record positions of elective linebreaks for pretty printer? (e.g. make lists/records/groups annotatable? would prefer not to annotate individual items); we also need a way to annotate exprs [or at least commands] with line no. for error reporting purposes


// TO DO: Q. a chain of `expr, expr, expr, … , expr TERMINATOR` tends to match recursively (since it is itself an expr); should we define `exprseq = [.expr, .comma, .expr]`? or could that blow up? another problem with this: the commas are context-sensitive, having subtly different meaning inside list and record literals


let field: Pattern = [.form(.letters), .form(.colon), .expr] // record/argument labels should always be always .letters (operator reader should always ignore a .letters token immediately followed by .colon [unless there's a bug])
let itemSep: Pattern = [.contiguous(.yes, .form(.comma), .no), anyLF] // right-side could be .any, with pp annotation to insert space, but this would be inadequate if also using `,` as thousands separator in numbers (or as decimal separator in Euro-localized numbers)
let exprSep: Pattern = [.contiguous(.yes, ofForm(.comma, .semicolon, .period, .query, .exclamation), .no), anyLF] // not sure about this

let LIST = PatternDefinition("list", block(.form(.startList), .expr, itemSep, .form(.endList), .action({ (builder: ASTBuilder) in print("reduce list", builder.stack) })))   // […]
let RECORD = PatternDefinition("record", block(.form(.startRecord), field, itemSep, .form(.endRecord), .action({ _ in print("reduce record") }))) // (…)

let GROUP = PatternDefinition("group", block(.form(.startGroup), .expr, exprSep, .form(.endGroup), .action({ _ in print("reduce group") }))) // (…)


let LOW_PUNC_COMMAND = PatternDefinition("command", [.commandName, .optional(.expr), .zeroPlus(field), .action({ _ in print("reduce lp command") })]) // note: `'+' 3 right: 5` is valid, if unhelpful, syntax (it'd be better written as `'+' {3, 5}`) // TO DO: in bottom-up, the argument expr should reduce to value before command pattern is fully matched // TO DO: .optional(.expr) will also match a record; if that happens, we should reduce immediately

let FULL_PUNC_COMMAND = PatternDefinition("command", [.commandName, RECORD.pattern, .action({ _ in print("reduce fp command") })])


// TO DO: operator patterns

let PREFIXOP = PatternDefinition("prefix operator", [.operatorName(.prefix), .expr, .action({ _ in print("reduce prefix op") })])
let INFIXOP = PatternDefinition("infix operator", [.expr, .operatorName(.infix), .expr, .action({ _ in print("reduce infix op") })])
let POSTFIXOP = PatternDefinition("postfix operator", [.expr, .operatorName(.postfix), .action({ _ in print("reduce postfix op") })])
let DOUBLEPREFIXOP = PatternDefinition("dprefix operator", [.operatorName(.postfix), PAIR, .action({ _ in print("reduce dprefix op") })]) // alternative to comma separator would be colon separator (which suggests `pair` as a standard pattern, if not first-class value), `if test: do…done` `repeat 5: say “hello”`; Q. what about annotating patterns with type info, tooltip text, etc? (this'd be orthogonal to command-supplied type and userdoc info, which is contingent the command/operator name)

let ATOMICOP = PatternDefinition("atomic operator", [.operatorName(.atom), .action({ _ in print("reduce atomic op") })]) // true, false, nothing; basically commonly used constants where we don't want commands' right-associativity to be an issue (e.g. ensures `foo by: true in: 1` will parse as `foo {by:true,in:1}`, not `foo {by:true{in:1}}`, obviating need for parens)



let PAIR: Pattern = [.expr, .form(.colon), .expr] // more specialized versions of pair are label:value; kinda need patterns to be comparable to allow most specific match (Q. does it matter?)

// if we're consuming mutable lexer, all tokens must go onto stack [backtracking is more of a top-down need anyway]; .sequence will do reductions when final token is encountered (upon matching first token it will need to capture stack depth so it can pop the lot)

// TO DO: precedence and associativity must be supplied by `.operatorName(OperatorDefinition)` (or, if it's .letters/.symbol, use the defaults: right-associative with fixed precedence [Q. what about low-punctuation syntax?])

// TO DO: above patterns need a function (or functions) to initialize builder on stack (where appropriate) and/or reduce on complete match (still with caveat about longest-match)

// TO DO: what else? pattern

