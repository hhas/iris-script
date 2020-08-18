//
//  gluelib_constants.swift
//  iris-glue
//

import Foundation
import iris


public func gluelib_loadConstants(into env: Environment) {
    
    try! env.set("expression", to: asIs.nativeCoercion) // caution: AsIs outputs the input Value exactly as-is, without evaluating it or capturing its lexical scope; this coercion is suitable for use only within primitive handlers that eval the parameter themselves using commandEnv // TO DO: stdlib needs to implement a native `expression` Coercion which thunks the input value before returning it // TO DO: rename `raw`/`raw_expression`/`unbound_expression`?
    
    //  env.define(coercion: asScope)
    env.define(coercion: asItself)
    env.define(coercion: asLiteralName)
    env.define(coercion: asLiteralCommand)
    env.define(coercion: asHandlerType)
    
    // TO DO: how best to expose SwiftCoercions under stable names that don’t conflict with native names?
    env.define(coercion: asInt)
    env.define(coercion: asDouble)
    env.define(coercion: asString)
    
    env.define(coercion: asOperatorSyntax)
    env.define(coercion: asAssociativity)
    env.define(coercion: asOperatorDefinition)
    env.define(coercion: asHandlerScope)
    
    env.define(coercion: asRecordType)
    
    
    
}
