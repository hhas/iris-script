//
//  stdlib_constants.swift
//


public func stdlib_loadConstants(into env: Environment) {
    env.define("nothing", nullValue) // TO DO: should `nothing` be both Value and TYPE? e.g. `foo {} returning nothing`? (note: primitive handlers use `asNoResult` as signature's return coercion to indicate no return value, in which case bridge code generator changes return statement to `return nullValue`)
    env.define("π", Double.pi) // Q. should `π` slot always evaluate to `π` symbol (with asTYPE methods converting it to Double when required)? (Swift, Python, AppleScript, etc define `pi` constant as numeric [64-bit float] value, 3.1415…, which is technically correct [enough], but aesthetically less helpful when displayed; Q. what other values might have different symbolic Text vs raw data representations? [currently true/false constants, though those will probably go away]) // TO DO: decide policy on when to define constants as .atom operators vs plain commands (e.g. `π2` is currently legal syntax, being a command with right-hand operand)
    
    // not sure if defining true/false constants is a good idea; if using 'emptiness' to signify true/false, having `true`/`false` constants that evaluate to anything other than `true`/`false` is liable to create far more confusion than convenience (one option is to define a formal Boolean value class and use that, but that raises questions on how to coerce it to text - it can't go to "true"/"false", as "false" is non-empty text, so would have to go to "ok"/"" which is unintuitive; another option is to copy Swift's approach where *only* true/false can be used in Boolean contexts, but that doesn't fit well with weak typing behavior; last alternative is to do away with true/false constants below and never speak of them again; note that only empty text and lists should be treated as Boolean false; 1 and 0 would both be true since both are represented as non-empty text, whereas strongly typed languages such as Python can treat 0 as false; the whole point of weak typing being to roundtrip data without changing its meaning even as its representation changes)
    env.define("true", true)
    env.define("false", false)
    
    
    env.define(coercion: asValue) // `value` (i.e. accepts anything except `nothing`)
    env.define(coercion: asString)
    env.define(coercion: asBool)   // TO DO: need to decide if native Boolean representation should be `true`/`false` constants or non-empty/empty values
    
    env.define(coercion: asNumber)
    env.define(coercion: asSymbol)
    
    env.define(coercion: asInt)
    env.define(coercion: asDouble)
    env.define(coercion: asList)
    env.define(coercion: asRecord)
    
    env.define(coercion: asCoercion)
    env.define(coercion: asHandler)
    env.define(coercion: asBlock) // TO DO: asBlockLiteral? (this'd need to accept single values too)
    
    
    env.define(coercion: asNothing) // by default, a native handler will return the result of the last expression evaluated; use `…returning no_result` to suppress that so that it always returns `nothing` (note that while using `return nothing` would give same the runtime result, declaring it via signature makes it clear and informs introspection and documentation tools as well)
    
    env.define(coercion: AsDefault(asValue, defaultValue: nullValue)) // note: AsDefault requires constraint args (coercion and defaultValue) to instantiate; native language will call() it to create new instances with appropriate constraints

    env.define(coercion: AsEditable())

    env.define(coercion: AsSwiftPrecis(asAnything, "anything")) // `anything` = `optional value` (i.e. accepts anything, including `nothing`)

}

