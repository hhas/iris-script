//
//  construct pattern.swift
//  iris-glue
//

import Foundation
import iris



    
func keyword(for names: [String]) -> Keyword {
    return Keyword(Symbol(names[0]), aliases: names.dropFirst().map{Symbol($0)})
}


func newSequencePattern(for patterns: [PatternValue]) -> PatternValue {
    return PatternValue(Pattern.sequence(patterns.map{$0.data}))
}

func newAnyOfPattern(for patterns: [PatternValue]) -> PatternValue {
    return PatternValue(Pattern.anyOf(patterns.map{$0.data}))
}

func newKeywordPattern(for names: [String]) -> PatternValue {
    return PatternValue(.keyword(keyword(for: names)))
}

func newExpressionPattern(named names: [String]) -> PatternValue {
    if names.count > 0 {
        return PatternValue(.expressionNamed(keyword(for: names)))
    } else {
        return PatternValue(.expression)
    }
}

func newOptionalPattern(pattern: PatternValue) -> PatternValue {
    return PatternValue(.optional(pattern.data))
}

func newZeroOrMorePattern(pattern: PatternValue) -> PatternValue {
    return PatternValue(.zeroOrMore(pattern.data))
}

func newOneOrMorePattern(pattern: PatternValue) -> PatternValue {
    return PatternValue(.oneOrMore(pattern.data))
}

func newAtomPattern(named names: [String]) -> PatternValue {
    return PatternValue(.keyword(keyword(for: names)))
}

func newPrefixPattern(named names: [String]) -> PatternValue {
    return PatternValue([.keyword(keyword(for: names)), .expression])
}

func newInfixPattern(named names: [String]) -> PatternValue {
    return PatternValue([.expression, .keyword(keyword(for: names)), .expression])
}

func newPostfixPattern(named names: [String]) -> PatternValue {
    return PatternValue([.expression, .keyword(keyword(for: names))])
}
