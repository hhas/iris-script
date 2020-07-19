//
//  commands.swift
//  iris-shell
//

// TO DO: `help` should take `optional command` argument, e.g. `help write` should print documentation for `write` command

import Foundation
import iris


// REPL support

func writeResult(_ value: Value) {
    print("\u{1b}[32m☺︎\u{1b}[m \(value)")
}

func writeError(_ error: Error) {
    fputs("\u{1b}[31m☹︎\u{1b}[m \(error)\n", stderr)
}

func writeHelp(_ string: String) {
    print(string)
}


// define REPL commands (for now these are handcoded but can eventually move to glue)

// `help` – print help
let interface_help = HandlerInterface(
    name: "help",
    parameters: [],
    result: asNothing
)
func procedure_help(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    if command.arguments.count > 0 { throw UnknownArgumentError(at: 0, of: command) }
    writeHelp("""
    # iris help

    ## REPL commands

    `_`         – output the result of the previous line
    
    `help`      – display this Help

    `commands`  – list all available commands
    
    `quit`      – exit the interactive shell

    ## Notes
    
    Emacs key bindings are supported, e.g. `Ctrl-L` to clear screen.
    
    """)
    return nullValue
}


// `commands` – list the contents of Environment
let interface_commands = HandlerInterface(
    name: "commands",
    parameters: [],
    result: asNothing
)
func procedure_commands(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    if command.arguments.count > 0 { throw UnknownArgumentError(at: 0, of: command) }
    for (name, value) in (commandEnv as! Environment).frame.sorted(by: {$0.key < $1.key}) {
        if let handler = value as? Handler {
            writeHelp("\(handler.interface)\n")
        } else {
            writeHelp("`\(name.label)` – \(value)\n")
        }
    }
    return nullValue
}


// `quit` – exit the REPL
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
