//
//  stdlib/handlers/state.swift
//


// references

// TO DO: fix commandEnv, e.g. `tell` block creates thin non-env sub-scope over Env (might be best to put `environment` var on Scope)


func tell(target: AttributedValue, action: Value, commandEnv: Scope) throws -> Value { // `tell expr to expr`
    let env = TargetScope(target: target, parent: commandEnv as! Environment) // TO DO: fix (TBH, APIs that currently require Environment should really take [Mutable]Scope)
    return try action.eval(in: env, as: asAnything) // TO DO: how to get coercion info?
}

func ofClause(attribute: Value, target value: Value, commandEnv: Scope, handlerEnv: Scope) throws -> Value { // TO DO: see TODO on AsAnything re. limiting scope of `didNothing` result
    // look up command's name in target
    //print("ofClause looking up", attribute, "on", value)
    if let command = attribute as? Command {
        if let selector = value.get(command.name) ?? commandEnv.get(command.name) { // TO DO: what lookup chain (e.g. reference form operators are defined in global namespace); or will target value always end up delegating lookups to that itself [e.g. document -> tell target, which extends global namespace]?
            if let handler = selector as? Handler {
                // command's arguments are evaled in commandEnv as normal (the Handler already contains a [strong]ref to its owner, )
                return try handler.call(with: command, in: commandEnv, as: asAnything) // TO DO: what env?
            } else if command.arguments.isEmpty {
                return selector
            } // fall thru
        }
    }
    throw UnsupportedCoercionError(value: attribute, coercion: asHandler) // TO DO: what error?
}

// handlers

func defineCommandHandler(right handler: Handler, commandEnv: Scope) throws -> Handler {
    try (commandEnv as! Environment).set(handler.interface.name, to: handler)
    return handler
}

func defineEventHandler(right handler: Handler, commandEnv: Scope) throws -> Handler {
    try (commandEnv as! Environment).set(handler.interface.name, to: handler) // TO DO: implement Handler.copy(isEventHandler:Bool) method (also need to finish argument unpacking; whereas command handler throws on unconsumed arguments, event handler should silently discard them)
    return handler
}


func returning(left: Value, right: Value) -> Value { // `returning` operator evaluates to self
    return Command("returning", [(leftOperand, left), (rightOperand, right)])
}

// set

func set(name: Symbol, to value: Value, commandEnv: Scope) throws -> Value { // `set name to: expr`
    try (commandEnv as! Environment).set(name, to: value)
    return value
}

// coerce

func coerce(left value: Value, right coercion: Coercion, commandEnv: Scope) throws -> Value { // `expr as coercion`
    return try value.eval(in: commandEnv, as: coercion) // TO DO: check this
}


