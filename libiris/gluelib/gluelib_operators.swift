//
//  gluelib_operators.swift
//  iris-script
//

import Foundation


func gluelib_loadOperators(into registry: OperatorRegistry) {
    // constants
    registry.atom("nothing")
    registry.atom("true")
    registry.atom("false")
    
    // operator keywords (minimum required to write glue definitions in native syntax)
    registry.prefix("to", conjunction: "requires", 180)
    // TO DO: what about `when`?
    registry.infix("as", 350)
    registry.infix("returning", 300)
}
