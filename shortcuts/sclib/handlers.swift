//
//  handlers.swift
//  sclib
//

import Foundation
import iris

// is.workflow.actions.conditional uses multiple Dicts with a common GroupingIdentifier to denote start and end of action/alternative_action blocks


func set(name: Symbol, to value: Value, commandEnv: Scope) throws -> Value {
    try (commandEnv as! Environment).set(name, to: value)
    return nullValue
}


// primarily for capturing action output, e.g. `foo; store NAME; …`
func store(value: Value, named name: Symbol, commandEnv: Scope) throws -> Value {
    try (commandEnv as! Environment).set(name, to: value)
    return value
}
