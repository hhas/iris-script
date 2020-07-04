//
//  built-in patterns.swift
//  iris-script
//
// special-purpose patterns hardcoded into the parser, used to match value literals and some commands; unlike library-defined operators (which are completely customizable), these patterns are part of the language’s core syntax and cannot be modified, overloaded, removed, or replaced


import Foundation

// note that list/record/group/block literals (which, unlike true library-defined operators, are constructed using the language’s reserved punctuation symbols) are also treated as operators for pattern-matching purposes, as are full-punctuation commands (`NAME RECORD`) and nested commands (`NAME EXPR?`); however, unlike library-defined operators (which are loaded from file into a standard lookup table), these non-operator matchers are instantiated and attached directly to the parser stack by the parser itself when the relevant tokens are encountered (i.e. don’t futz with the below definitions and don't try to overload them with standard operator glues)

// (remember: homonyms are a bad idea in general; even if the parser did allow it, overloading […] or {…} syntax to describe anything other than list and record literals would be bad design practice, confusing users as to their meaning and correct usage)

// caution: each time parser directly calls PatternDefinition.newMatches() on one of the definitions below, the returned matchers are assigned a new groupID; this means the hardcoded patterns in `literal patterns.swift` must not be overloaded, as the findLongestMatches() method relies on shared group IDs to prune multiple matches of the same tokens (this is does not apply to overloaded library-defined operators as those are stored in OperatorDefinitions instances, and OperatorDefinitions.newMatches() assigns a common group ID to all matchers)

// TO DO: should kv-list and record patterns allow LF between colon and value? (the reducefunc does allow it so it’s a question of whether it aids or impairs legibility)


let EXPR: Pattern = .expression
let SKIP_LF: Pattern = .zeroOrMore(.lineBreak)
let M_DELIM: Pattern = [.delimiter, SKIP_LF] // a multi-line delimiter (e.g. a comma, a linebreak, or a comma followed by a linebreak)

func M_ITEMS(_ item: Pattern) -> Pattern {
    return [item, .zeroOrMore([.delimiter, SKIP_LF, item]), SKIP_LF]
}

func M_BLOCK(_ start: Token.Form, _ item: Pattern, _ end: Token.Form) -> [Pattern] {
    return [.token(start),
            SKIP_LF,
            .optional(M_ITEMS(item)),
            .token(end)]
}

// ordered list

let orderedListLiteral = PatternDefinition(name: "[…]", pattern: M_BLOCK(.startList, EXPR, .endList),
                                            autoReduce: true, reducer: reductionForOrderedListLiteral)



// TO DO: might want to leave left side of colon pairs as .expression and have reduce funcs report error if it's not valid (this might allow reducing colon pairs down to Pair values)

// keyed list

let keyValueListLiteral = PatternDefinition(name: "[…:…]", pattern:
    [.token(.startList), .anyOf([
        .token(.colon), // empty kv-list uses same literal syntax as Swift, `[:]`
        [SKIP_LF, M_ITEMS([.testValue({$0 is HashableValue}), .token(.colon), EXPR])] // a kv-list with one or more items
    ]), .token(.endList)], autoReduce: true, reducer: reductionForKeyedListLiteral)


// record

let recordLiteral = PatternDefinition(name: "{…}", pattern: M_BLOCK(.startRecord, [.optional(.label), EXPR], .endRecord),
                                       autoReduce: true, reducer: reductionForRecordLiteral)


// group/parenthesized block

let groupLiteral = PatternDefinition(name: "(…)", pattern:
    [.token(.startGroup), SKIP_LF, EXPR, SKIP_LF, .token(.endGroup)], autoReduce: true, reducer: reductionForGroupLiteral)


let parenthesizedBlockLiteral = PatternDefinition(name: "(…,…)", pattern: M_BLOCK(.startGroup, EXPR, .endGroup),
                                      autoReduce: true, reducer: reductionForParenthesizedBlockLiteral)


// command

// note: the challenge with pattern-matching commands is that 1. LP syntax is superset of standard `NAME EXPR` syntax, and 2. LP syntax should not nest (as that creates ambiguity over which command owns trailing labeled arguments, c.f. C’s “dangling else”); one more gotcha of LP syntax is when first arg is itself a record literal (i.e. that command must be written as `name {{…},…}` to distinguish the argument record of an FP command from a record literal to be passed as command’s direct argument. The requirement for this special-case syntax rule is an irritation; however, the advantages of LP syntax, particularly when using the language as a command shell (where typing commands many not incur too many additional keystrokes when compared to a traditional *nix CLI such as bash), are such that this compromise should be worth it, but it will have to be tested in real-world use to verify).

let nestedCommandLiteral = PatternDefinition(name: "«COMMAND»", pattern:
    [.name, .optional(.expression)], precedence: commandPrecedence, reducer: reductionForCommandLiteral)



let pipeLiteralPrecedence: Precedence = 96 // TO DO: check that `;` doesn't need precedence or associativity: it should always delimit exprs in the same way that other built-in punctuation (comma, period, etc) do (for now though we keep the values it had in the old recursive descent parser)


let pipeLiteral = PatternDefinition(name: "«PIPE»", pattern:
[EXPR, .token(.semicolon), EXPR], // TO DO: allow LF after semicolon?
                                  precedence: pipeLiteralPrecedence,
                                  reducer: reductionForPipeOperator)

