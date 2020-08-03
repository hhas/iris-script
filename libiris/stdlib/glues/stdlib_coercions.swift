//
//  stdlib_coercions.swift
//  libiris
//

import Foundation


public func stdlib_loadCoercions(into env: Environment) {
    
    env.define(coercion: asAnything) // `anything` is equivalent to `optional value` (i.e. accepts anything, including `nothing`)
    env.define(coercion: asValue) // `value` (i.e. accepts anything except `nothing`)
    
    // TO DO: most of these are SwiftCoercions which box themselves; it may be better to define separate NativeCoercions, particularly for those that support constraints
    env.define(coercion: asBool)   // TO DO: need to decide if native Boolean representation should be `true`/`false` constants or non-empty/empty values (probably best with traditional constants for pedagogical purposes, although “emptiness” does have its advantages as does Icon-style result/failure)
    env.define(coercion: asSymbol)
    
    env.define(coercion: asInt)
    env.define(coercion: asDouble)
    env.define(coercion: asNumber)

    env.define(coercion: asText) //

    env.define(coercion: CallableCoercion(asOrderedList))
    env.define(coercion: asRecord)
    
    env.define(coercion: asCoercion)
    env.define(coercion: asHandler)
    env.define(coercion: asBlock) // TO DO: asBlockLiteral? (this'd need to accept single values too)
    
    //env.define(coercion: asNothing) // redundant as constants already defines `nothing` (which is both value and coercion)
    
    // TO DO: need a native AsDefault, and need to decide its syntax too
    env.define(coercion: AsSwiftPrecis(AsSwiftDefault(asValue, nullValue), "with_default")) // TO DO: AsDefault requires constraint args (coercion and defaultValue) to instantiate; native language will call() it to create new instances with appropriate constraints // TO DO: need to review SwiftCoercion usage within native environment // TO DO: should `with_default` be an optional clause to `optional…with_default…`?

    env.define(coercion: asEditable)

    env.define(coercion: CallableCoercion(asOptional)) // TO DO: decide on `optional` vs `anything`; stdlib glue currently uses `optional` rather than `anything` (`anything` may be more easily confused with `value`)

}

