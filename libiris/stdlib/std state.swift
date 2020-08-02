//
//  stdlib/handlers/state.swift
//


// references

// TO DO: fix commandEnv, e.g. `tell` block creates thin non-env sub-scope over Env (might be best to put `environment` var on Scope)

// TO DO: should `set…to…` support multiple assignment?


func tell(target: AttributedValue, action: Value, commandEnv: Scope) throws -> Value { // `tell expr to expr`
    let env = TargetScope(target: target, parent: (commandEnv as? MutableScope) ?? MutableShim(commandEnv)) // TO DO: most/all APIs that currently require Environment should really take [Mutable]Scope
    return try asAnything.coerce(action, in: env) // TO DO: how to get coercion info?
}

func ofClause(attribute: Value, target value: Value, commandEnv: Scope, handlerEnv: Scope) throws -> Value { // TO DO: see TODO on AsAnything re. limiting scope of `didNothing` result
    // look up command's name in target
    //print("ofClause looking up", attribute, "on", value)
    if let command = attribute as? Command {
        if let selector = value.get(command.name) ?? commandEnv.get(command.name) { // TO DO: what lookup chain (e.g. reference form operators are defined in global namespace); or will target value always end up delegating lookups to that itself [e.g. document -> tell target, which extends global namespace]?
            if let handler = selector as? Callable {
                // command's arguments are evaled in commandEnv as normal (the Handler already contains a [strong]ref to its owner, )
                return try handler.call(with: command, in: commandEnv, as: asAnything) // TO DO: what env?
            } else if command.arguments.isEmpty {
                return selector
            } // fall thru
        }
    }
    throw TypeCoercionError(value: attribute, coercion: asHandler) // TO DO: what error?
}

// handlers

func defineCommandHandler(interface: HandlerInterface, action: Value, commandEnv: Scope) throws -> Handler {
    guard let env = commandEnv as? Environment else {
        fatalError("\(interface.name) handler requires a full Environment but received \(commandEnv)")
    }
    let handler = NativeHandler(interface: interface, action: action, in: env)
    try (commandEnv as! Environment).set(interface.name, to: handler)
    return handler
}

func defineEventHandler(interface: HandlerInterface, action: Value, commandEnv: Scope) throws -> Handler {
    guard let env = commandEnv as? Environment else {
        fatalError("\(interface.name) handler requires a full Environment but received \(commandEnv)")
    }
    let handler = NativeHandler(interface: interface.asEventHandler(), action: action, in: env)
    try (commandEnv as! Environment).set(interface.name, to: handler)
    return handler
}

// set

func set(name: Symbol, to value: Value, commandEnv: Scope) throws -> Value { // `set name to expr`
    try (commandEnv as! Environment).set(name, to: value)
    return value
}

// coerce

func coerce(value: Value, coercion: NativeCoercion, commandEnv: Scope) throws -> Value { // `expr as coercion`
    return try coercion.coerce(value, in: commandEnv) // TO DO: check this
}




func returning(interface: HandlerInterface, coercion: Coercion) -> Value {
    fatalError()
}
