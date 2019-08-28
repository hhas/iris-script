//
//  gluelib_operators.swift
//  iris-script
//

import Foundation


func gluelib_loadOperators(into registry: OperatorRegistry) {
    // constants
    registry.add(OperatorDefinition("nothing", .atom, precedence: 0))
    registry.add(OperatorDefinition("true", .atom, precedence: 0))
    registry.add(OperatorDefinition("false", .atom, precedence: 0))
    
    // operator keywords (minimum required to write glue definitions in native syntax)
    registry.add(OperatorDefinition("to", .prefix, precedence: 180))
    registry.add(OperatorDefinition("as", .infix, precedence: 350))
    registry.add(OperatorDefinition("returning", .infix, precedence: 300))
    registry.add(OperatorDefinition("do", .custom(parseDoBlock), precedence: 100))
    registry.add(OperatorDefinition("done", .custom(parseUnexpectedKeyword), precedence: -100))
}
