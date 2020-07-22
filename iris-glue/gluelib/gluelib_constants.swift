//
//  gluelib_constants.swift
//  iris-glue
//

import Foundation
import iris


public func gluelib_loadConstants(into env: Environment) {

      try! env.set("expression", to: asIs) // caution: AsIs outputs the input Value exactly as-is, without evaluating it or capturing its lexical scope; this coercion is suitable for use only within primitive handlers that eval the parameter themselves using commandEnv // TO DO: stdlib needs to implement a native `expression` Coercion which thunks the input value before returning it // TO DO: rename `raw`/`raw_expression`/`unbound_expression`?
      
    //  env.define(coercion: asScope)
      env.define(coercion: asLiteralName)
      env.define(coercion: asHandlerInterface)
}
