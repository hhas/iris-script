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

    `clear`     – clear screen
    
    `help`      – display this Help

    `commands`  – list all available commands
    
    `quit`      – exit the interactive shell

    `read {prompt as text with_default "?"} – read next line of input from stdin, with customizable prompt

    ## Notes
    
    Emacs key bindings are supported, e.g. `Ctrl-L` to clear screen.
    
    """)
    return nullValue
}

// `clear` – clear screen

let interface_clear = HandlerInterface(
    name: "clear",
    parameters: [],
    result: asNothing
)
func procedure_clear(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    if command.arguments.count > 0 { throw UnknownArgumentError(at: 0, of: command) }
    fputs("\u{1b}[H\u{1b}[2J", stdout)
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

// `read` – read line input

private let type_read_prompt = (
    param_0: (Symbol("prompt"), AsSwiftDefault(asString, defaultValue: "?")),
    result: asString
)

let interface_read_prompt = HandlerInterface(
    name: "read",
    parameters: [(type_read_prompt.param_0.0, "", type_read_prompt.param_0.1)],
    result: type_read_prompt.result
)
func procedure_read_prompt(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_read_prompt.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    fputs("\(arg_0) ", stdout)
    let rawInput = String(data: FileHandle.standardInput.availableData, encoding: .utf8) ?? ""
    let input = rawInput.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    return type_read_prompt.result.box(value: input, in: commandEnv)
}



func loadREPLHandlers(_ env: Environment) {
    env.define(interface_help, procedure_help)
    env.define(interface_clear, procedure_clear)
    env.define(interface_commands, procedure_commands)
    env.define(interface_quit, procedure_quit)
    env.define(interface_read_prompt, procedure_read_prompt)
}
