//
//  gluelib_operators.swift
//  iris-script
//

import Foundation


func gluelib_loadOperators(into registry: OperatorRegistry) {
    registry.add(OperatorDefinition("to", .prefix, precedence: 180))
    registry.add(OperatorDefinition("as", .infix, precedence: 350))
    registry.add(OperatorDefinition("returning", .infix, precedence: 300))
    registry.add(OperatorDefinition("do", .custom(parseDoBlock), precedence: 100))
    registry.add(OperatorDefinition("done", .custom(parseUnexpectedKeyword), precedence: -100))
}
