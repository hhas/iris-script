//
//  stdlib/handlers/state.swift
//

// TO DO: fix commandEnv, e.g. `tell` block creates thin non-env sub-scope over Env (might be best to put `environment` var on Scope)


func returning(left: Value, right: Value) -> Value { // `returning` operator evaluates to self
    return Command("returning", [(leftOperand, left), (rightOperand, right)])
}



func defineCommandHandler(right handler: Handler, commandEnv: Scope) throws -> Handler {
    try (commandEnv as! Environment).set(handler.interface.name, to: handler)
    return handler
}

func defineEventHandler(right handler: Handler, commandEnv: Scope) throws -> Handler {
    try (commandEnv as! Environment).set(handler.interface.name, to: handler) // TO DO: implement Handler.copy(isEventHandler:Bool) method (also need to finish argument unpacking; whereas command handler throws on unconsumed arguments, event handler should silently discard them)
    return handler
}




func set(name: Symbol, to value: Value, commandEnv: Scope) throws -> Value { // `set name to: expr`
    try (commandEnv as! Environment).set(name, to: value)
    return value
}



func coerce(left value: Value, right coercion: Coercion, commandEnv: Scope) throws -> Value { // `expr as coercion`
    return try value.eval(in: commandEnv, as: coercion) // TO DO: check this
}

// TO DO: how to parameterize run-time return type?
func tell(target: AttributedValue, action: Value, commandEnv: Scope) throws -> Value { // `tell expr to expr`
    let env = TargetScope(target: target, parent: commandEnv as! Environment)
    return try action.eval(in: env, as: asAnything) // TO DO: how to get coercion info?
}


