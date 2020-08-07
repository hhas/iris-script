//
//  stdlib_coercions.swift
//  libiris
//

import Foundation


public func stdlib_loadCoercions(into env: Environment) {
    // define operator names for constants, miscellany
    if let registry = (env as? ExtendedEnvironment)?.operatorRegistry {
        
        // define `record` as keyword to simplify syntax when passing record as operand, i.e. `record {…}` instead of `record {{…}}`
        registry.add([.keyword("record"), .optional(.expressionLabeled("of_type"))], 1500)
        
        // coercion modifiers (defined as operators to allow nesting of LP commands)
        registry.add([.keyword("optional"), .optional(.expressionLabeled("of_type")),
                      .optional([.keyword("with_default"), .expressionLabeled("with_default")])], 1500)
        
        // `editable EXPR?` (note: this could be defined as single operator with optional operand, but for now add two separate definitions to test alternate code path in pattern matching)
        registry.atom("editable")
        registry.prefix("editable", 1500)
    }
    
    env.define(coercion: asAnything) // `anything` is equivalent to `optional value` (i.e. accepts anything, including `nothing`)
    env.define(coercion: asValue) // `value` (i.e. accepts anything except `nothing`)
    
    env.define(coercion: asBool)   // TO DO: need to decide if native Boolean representation should be `true`/`false` constants or non-empty/empty values (probably best with traditional constants for pedagogical purposes, although “emptiness” does have its advantages as does Icon-style result/failure)
    env.define(coercion: asSymbol)
    
    env.define(coercion: asInt) // TO DO: define `integer` slot as handler that forwards to `number{whole: true,…}`
    //env.define(coercion: asDouble)
    env.define(coercion: CallableCoercion(asNumber))

    env.define(coercion: asText) // constraint options?

    env.define(coercion: CallableCoercion(asOrderedList))
    env.define("list",   CallableCoercion(asOrderedList)) // `ordered_list` is aliased as `list` for convenience
    env.define(coercion: CallableCoercion(asKeyedList))
    env.define(coercion: CallableCoercion(asRecord))
    
    env.define(coercion: asCoercion)
    env.define(coercion: asHandler)
    env.define(coercion: asBlock) // TO DO: asBlockLiteral? (this'd need to accept single values too) // TO DO: replace with `expression`, which thunks a given value in current command context
    
    env.define(coercion: CallableCoercion(asEditable))

    env.define(coercion: CallableCoercion(asOptional)) // TO DO: by default this is `optional value` which is equivalent to `anything`; would it help

}

