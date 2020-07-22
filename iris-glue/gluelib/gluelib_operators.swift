//
//  gluelib_operators.swift
//  iris-script
//

import Foundation
import iris


func gluelib_loadOperators(into registry: OperatorRegistry) {
    
    // operator keywords (minimum required to write glue definitions in native syntax)
    registry.add(["to", .expressionNamed("interface"), "requires", .expression], 180, reductionForPrefixOperatorWithConjunction)
    
    // TO DO: what about `when`? (depends on whether or not there’s any use-case where primitive libs would/should be used to define event handlers; generally they’d be written as native code and called into from primitive host)
    
    registry.add([.expression, "as", .expression], 350, reductionForInfixOperator)
}
