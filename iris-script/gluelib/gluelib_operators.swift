//
//  gluelib_operators.swift
//  iris-script
//

import Foundation


func gluelib_loadOperators(into registry: OperatorRegistry) {
    // constants
    registry.add(PatternDefinition("nothing", .atom, precedence: 0))
    registry.add(PatternDefinition("true", .atom, precedence: 0))
    registry.add(PatternDefinition("false", .atom, precedence: 0))
    
    // operator keywords (minimum required to write glue definitions in native syntax)
    registry.add(PatternDefinition("to", .prefix, precedence: 180))
    registry.add(PatternDefinition("as", .infix, precedence: 350))
    registry.add(PatternDefinition("returning", .infix, precedence: 300))
    registry.add(PatternDefinition("do", .custom(parseDoBlock), precedence: 100))
    registry.add(PatternDefinition("done", .custom(parseUnexpectedKeyword), precedence: -100))
}
