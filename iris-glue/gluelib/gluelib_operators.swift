//
//  gluelib_operators.swift
//  iris-script
//

import Foundation
import iris


func gluelib_loadOperators(into registry: OperatorRegistry) {
    
    // operator keywords (minimum required to write glue definitions in native syntax)
    registry.prefix("to", conjunction: "requires", 180)
    // TO DO: what about `when`?
    
    registry.infix("as", 350)
}
