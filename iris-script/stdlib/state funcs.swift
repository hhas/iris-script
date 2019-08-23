//
//  stdlib/handlers/state.swift
//

// TO DO: fix commandEnv, e.g. `tell` block creates thin non-env sub-scope over Env (might be best to put `environment` var on Scope)

func defineHandler(interface: HandlerInterface, action: Value, commandEnv: Scope) throws { // `to/when interface: action`?
    try (commandEnv as! Environment).define(interface, action)
} // TO DO: how to set interface's isEventHandler flag?


func returning(left: Value, right: Value) -> Value { // `returning` operator evaluates to self
    return Command("returning", [(leftOperand, left), (rightOperand, right)])
}



func defineCommandHandler(handler: Handler, commandEnv: Scope) throws -> Value {
    try (commandEnv as! Environment).set(handler.interface.name, to: handler)
    return handler
}




func set(name: Symbol, value: Value, commandEnv: Scope) throws -> Value { // `set name to: expr`
    try (commandEnv as! Environment).set(name, to: value)
    return value
}



func coerce(value: Value, coercion: Coercion, commandEnv: Scope) throws -> Value { // `expr as coercion`
    return try value.eval(in: commandEnv, as: coercion) // TO DO: check this
}


func tell(target: AttributedValue, action: Value, commandEnv: Scope) throws -> Value { // `tell expr to expr`
    let env = TargetScope(target: target, parent: commandEnv as! Environment)
    return try action.eval(in: env, as: asAnything) // TO DO: how to get coercion info?
}


