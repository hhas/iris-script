//
//  stdlib_constants.swift
//

//  declares various constants and operators that glue generator doesn’t yet support

// TO DO: autogenerate?


// from language’s POV, should the nominal type for numbers and text be `scalar`? (i.e. while they are implemented internally as multiple Swift types, presenting natively as a single uniform datatype reminds that the data’s behavior depends on how it is used, not on how it is encoded); Q. how would other atomic values—e.g. dates and times, file paths [where used], currencies and weights and measures—mesh with this?


public func stdlib_loadConstants(into env: Environment) {
    
    // define operator names for constants, miscellany
    if let registry = (env as? ExtendedEnvironment)?.operatorRegistry {
        
        // constants
        registry.atom("nothing") // analogous to Python's `None`
        //registry.atom("did_nothing") // TO DO: get rid of this if a satisfactory solution to `…else…` operator can’t be found
        registry.atom("true")
        registry.atom("false")
        registry.atom("π") // TO DO: alias `pi`?
        
        // used in procedure interface
        //registry.infix("returning", 300)
        
        // keyword-based block
        registry.prefix("do", suffix: "done")

        // coercion modifiers (defined as operators to allow nesting of LP commands)
        registry.prefix("optional", 320)
        registry.prefix("editable", 320)
        
        // TO DO: FIX: defining both atomic and prefix forms of `optional` operator doesn’t parse correctly (the latter definition appears to mask the former; thus, in this case, `foo as editable` parses but `foo as editable value` does not); a workaround for now would be to define `optional EXPR?` as a single pattern with optional EXPR, however, it'd be best to fix the bug at source (presumably in OperatorRegistry)
        registry.atom("optional")
        registry.atom("editable")
        registry.infix("with_default", 500)

    }
    
    env.define("nothing", nullValue) // TO DO: should `nothing` be both Value and TYPE? e.g. `foo {} returning nothing`? (note: primitive handlers use `asNoResult` as signature's return coercion to indicate no return value, in which case bridge code generator changes return statement to `return nullValue`)
    env.define("π", Double.pi) // Q. should `π` slot always evaluate to `π` symbol (with asTYPE methods converting it to Double when required)? (Swift, Python, AppleScript, etc define `pi` constant as numeric [64-bit float] value, 3.1415…, which is technically correct [enough], but aesthetically less helpful when displayed; Q. what other values might have different symbolic Text vs raw data representations? [currently true/false constants, though those will probably go away]) // TO DO: decide policy on when to define constants as .atom operators vs plain commands (e.g. `π2` is currently legal syntax, being a command with right-hand operand)
    
    // not sure if defining true/false constants is a good idea; if using 'emptiness' to signify true/false, having `true`/`false` constants that evaluate to anything other than `true`/`false` is liable to create far more confusion than convenience (one option is to define a formal Boolean value class and use that, but that raises questions on how to coerce it to text - it can't go to "true"/"false", as "false" is non-empty text, so would have to go to "ok"/"" which is unintuitive; another option is to copy Swift's approach where *only* true/false can be used in Boolean contexts, but that doesn't fit well with weak typing behavior; last alternative is to do away with true/false constants below and never speak of them again; note that only empty text and lists should be treated as Boolean false; 1 and 0 would both be true since both are represented as non-empty text, whereas strongly typed languages such as Python can treat 0 as false; the whole point of weak typing being to roundtrip data without changing its meaning even as its representation changes)
    env.define("true", true)
    env.define("false", false)
    
    
    env.define(coercion: asValue.nativeCoercion) // `value` (i.e. accepts anything except `nothing`)
    env.define(coercion: asString.nativeCoercion)
    env.define(coercion: asBool.nativeCoercion)   // TO DO: need to decide if native Boolean representation should be `true`/`false` constants or non-empty/empty values (probably best with traditional constants for pedagogical purposes, although “emptiness” does have its advantages as does Icon-style result/failure)
    
    env.define(coercion: asNumber.nativeCoercion)
    env.define(coercion: asSymbol.nativeCoercion)
    
    env.define(coercion: asInt.nativeCoercion)
    env.define(coercion: asDouble.nativeCoercion)
    env.define(coercion: asList)
    env.define(coercion: asRecord.nativeCoercion)
    
    env.define(coercion: asCoercion)
    env.define(coercion: asHandler.nativeCoercion)
    env.define(coercion: asBlock.nativeCoercion) // TO DO: asBlockLiteral? (this'd need to accept single values too)
    
    
    env.define(coercion: asNothing) // by default, a native handler will return the result of the last expression evaluated; use `…returning no_result` to suppress that so that it always returns `nothing` (note that while using `return nothing` would give same the runtime result, declaring it via signature makes it clear and informs introspection and documentation tools as well)
    
    env.define(coercion: AsSwiftPrecis(AsSwiftDefault(asValue, nullValue), "with_default")) // TO DO: AsDefault requires constraint args (coercion and defaultValue) to instantiate; native language will call() it to create new instances with appropriate constraints // TO DO: need to review SwiftCoercion usage within native environment // TO DO: should `with_default` be an optional clause to `optional…with_default…`?

    env.define(coercion: asEditable)

    env.define(coercion: asAnything) // `anything` = `optional value` (i.e. accepts anything, including `nothing`)
    env.define(coercion: AsSwiftOptional(asValue)) // TO DO: decide on `optional` vs `anything`; stdlib glue currently uses `optional` rather than `anything` (`anything` may be more easily confused with `value`)

}

