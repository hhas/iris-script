//
//  commands.swift
//  iris-shell
//

import Foundation
import libIris


// define `help` command

let interface_help = HandlerInterface(
    name: "help",
    parameters: [],
    result: asNothing
)
func procedure_help(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    if command.arguments.count > 0 { throw UnknownArgumentError(at: 0, of: command) }
    writeOutput("""
    # iris help

    ## REPL commands

    `_`         – output the result of the previous line
    
    `help`      – display this Help

    `commands`  – list all available commands
    
    `quit`      – exit the interactive shell
    
    """)
    return nullValue
}


let interface_commands = HandlerInterface(
    name: "commands",
    parameters: [],
    result: asNothing
)
func procedure_commands(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    if command.arguments.count > 0 { throw UnknownArgumentError(at: 0, of: command) }
    for (name, value) in env.frame.sorted(by: {$0.key < $1.key}) {
        if let handler = value as? Handler {
            writeOutput("\(handler.interface)\n")
        } else {
            writeOutput("`\(name.label)` – \(value)\n")
        }
    }
    return nullValue
}


// define `quit` command for exiting REPL
var isRunning = true

let interface_quit = HandlerInterface(
    name: "quit",
    parameters: [],
    result: asNothing
)
func procedure_quit(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    if command.arguments.count > 0 { throw UnknownArgumentError(at: 0, of: command) }
    isRunning = false
    return Text("Goodbye.")
}
