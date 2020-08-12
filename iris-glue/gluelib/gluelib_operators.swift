//
//  gluelib_operators.swift
//  iris-script
//

import Foundation
import iris


func gluelib_loadOperators(into registry: OperatorRegistry) {
    
    // operator keywords (minimum required to write glue definitions in native syntax)
    registry.add(["swift_handler", .expression, "requires", .expression], 180)
    registry.add(["swift_record", .expression, "requires", .expression], 180)
    registry.add(["swift_coercion", .expression, "requires", .expression], 180)
    registry.add(["swift_multichoice", .expression, "requires", .expression], 180)
    
    // TO DO: how to make library import/includes more granular? we don’t want to import all of stdlib, but we do need the following definitions:
    
    // used in interface definitions
    registry.add([.expression, .keyword("returning"), .expression], 300)
    registry.add([.expression, "as", .expression], 350)
    
    // coercion operators (now defined in stdlib_operators, which gluelib ignores, so copied here as workaround)
    registry.add([.keyword("editable"), .optional(.expressionLabeled("of_type"))], 1500, .left)
    registry.add([.keyword("optional"), .optional(.expressionLabeled("of_type")), .optional([.keyword("with_default"), .expressionLabeled("with_default")])], 1500, .left)
    registry.add([.keyword("record"), .optional(.expressionLabeled("of_type"))], 1500, .left)

}
