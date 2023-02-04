//
//  sclib_operators.swift
//  sclib
//

import Foundation
import iris


public func sclib_loadOperators(into registry: OperatorRegistry) {
    registry.add(["shortcut_action", .expression, "requires", .expression], 180)
    registry.add([.expression, .keyword("returning"), .expression], 300)
    registry.add([.expression, "as", .expression], 350)
    registry.add([.expression, "AND", .expression], 362)
    registry.add([.expression, "OR", .expression], 360)
    registry.add([.expression, "but_not", .expression], 358)
    registry.add([.keyword("optional"), .optional(.expression), .optional([.keyword("with_default"), .boundExpression("with_default", "default_value")])], 1500, .left)
    registry.add([.keyword("record"), .optional(.boundExpression("of_type", "record_type"))], 1500, .left)

    
    registry.add([.keyword("set"), .boundExpression("name", "name"), .keyword("to"), .boundExpression("to", "value")], 80, .left)

}
