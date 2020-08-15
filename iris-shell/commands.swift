//
//  commands.swift
//  iris-shell
//

// TO DO: `help` should take `optional command` argument, e.g. `help write` should print documentation for `write` command

import Foundation
import iris

// TO DO: colorization doesn't offset corectly if entered code produces parse error


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
let interface_help = HandlerType(
    name: "help",
    parameters: [],
    result: asNothing.nativeCoercion
)
func procedure_help(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    if command.arguments.count > 0 { throw UnknownArgumentError(at: 0, of: command, to: handler) }
    writeHelp("""
    # iris help
    
    ## REPL commands

    `_`         – output the result of the previous line

    `clear`     – clear screen
    
    `help`      – display this Help

    `commands`  – list all available commands

    `operators` – list all available operators
    
    `quit`      – exit the interactive shell
    
    `read {prompt as optional string with_default "?"} – read next line of input from stdin, with customizable prompt
    
    ## Notes
    
    Emacs key bindings are supported, e.g. `Ctrl-L` to clear screen.
    
    """)
    return nullValue
}

// `clear` – clear screen

let interface_clear = HandlerType(
    name: "clear",
    parameters: [],
    result: asNothing.nativeCoercion
)
func procedure_clear(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    if command.arguments.count > 0 { throw UnknownArgumentError(at: 0, of: command, to: handler) }
    fputs("\u{1b}[H\u{1b}[2J", stdout)
    return nullValue
}

// `commands` – list the contents of Environment
let interface_commands = HandlerType(
    name: "commands",
    parameters: [],
    result: asNothing.nativeCoercion
)
func procedure_commands(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    if command.arguments.count > 0 { throw UnknownArgumentError(at: 0, of: command, to: handler) }
    for (name, value) in (commandEnv as! Environment).frame.sorted(by: {$0.key < $1.key}) {
        if let handler = value as? Callable {
            writeHelp("\(handler.interface)\n")
        } else {
            writeHelp("‘\(name.label)’ – \(value)\n")
        }
    }
    return nullValue
}

// `operators` – list the contents of Environment
let interface_operators = HandlerType(
    name: "operators",
    parameters: [],
    result: asNothing.nativeCoercion
)
func procedure_operators(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    guard let env = handlerEnv as? ExtendedEnvironment else {
        print("not available")
        return nullValue
    }
    if command.arguments.count > 0 { throw UnknownArgumentError(at: 0, of: command, to: handler) }
    var found = Set<String>()
    var precedence: Precedence = 0
    let definitions = env.operatorRegistry.patternDefinitions.map{($0.precedence, $0.name, $0.description)}
    for definition in definitions.sorted(by: { ($1.0, $0.1) < ($0.0, $1.1) }) {
        if !found.contains(definition.2) {
            found.insert(definition.2)
            if definition.0 != precedence {
                precedence = definition.0
                print()
            }
            print(definition.2) // TO DO: how best to format operators?
        }
    }
    print()
    return nullValue
}


// `quit` – exit the REPL
var isRunning = true

let interface_quit = HandlerType(
    name: "quit",
    parameters: [],
    result: asNothing.nativeCoercion
)
func procedure_quit(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    if command.arguments.count > 0 { throw UnknownArgumentError(at: 0, of: command, to: handler) }
    isRunning = false
    return Text("Goodbye.")
}

// `read {prompt}` – read line input

private let type_read_prompt = (
    name: Symbol("read"),
    param_0: (Symbol("prompt"), Symbol("prompt"), AsSwiftDefault(asString, "?")),
    result: asString
)

let interface_read_prompt = HandlerType(
    name: type_read_prompt.name,
    parameters: [
        nativeParameter(type_read_prompt.param_0),
    ],
    result: type_read_prompt.result.nativeCoercion
)
func procedure_read_prompt(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_read_prompt.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    fputs("\(arg_0) ", stdout)
    let rawInput = String(data: FileHandle.standardInput.availableData, encoding: .utf8) ?? ""
    let input = rawInput.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    return type_read_prompt.result.wrap(input, in: commandEnv)
}


// `pp {value}` – pretty-print value/previous input

private let type_pp_value = (
    name: Symbol("pp"),
    param_0: (Symbol("value"), Symbol("value"), AsSwiftOptional(asValue)), // TO DO: this is a bit problematic: the proc below really wants Value, with nullValue rather than nil, but AsOptional doesn't compose with asValue and is in any case not a SwiftCoercion which is what's needed to unpack arguments
    result: asNothing
)

let interface_pp_value = HandlerType(
    name: type_pp_value.name,
    parameters: [
        nativeParameter(type_pp_value.param_0),
    ],
    result: type_pp_value.result.nativeCoercion
)
func procedure_pp_value(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    let formatter = VT100ValueFormatter()
    if command.arguments.count == 0 {
        print("  \(formatter.format(previousInput))")
    } else {
        var index = 0
        let arg_0 = try command.value(for: type_pp_value.param_0, at: &index, in: commandEnv)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
        print("  \(formatter.format(arg_0 ?? nullValue))")
    }
    return previousValue.get(nullSymbol) ?? nullValue
}
// `spp {value}` – print Swift representation of value/previous input; caution this may raise exception for some types (if unsupported the fallback behavior is fatalError)

private let type_spp_value = (
    name: Symbol("spp"),
    param_0: (Symbol("value"), Symbol("value"), AsSwiftOptional(asValue)),
    result: asNothing
)

let interface_spp_value = HandlerType(
    name: type_spp_value.name,
    parameters: [
        nativeParameter(type_spp_value.param_0),
    ],
    result: type_spp_value.result.nativeCoercion
)
func procedure_spp_value(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    if command.arguments.count == 0 {
        print("  \(previousInput.swiftLiteralDescription)")
    } else {
        var index = 0
        let arg_0 = try command.value(for: type_spp_value.param_0, at: &index, in: commandEnv)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
        print("  \((arg_0 ?? nullValue).swiftLiteralDescription)")
    }
    return previousValue.get(nullSymbol) ?? nullValue
}



func loadREPLHandlers(_ env: Environment) {
    env.define(interface_help, procedure_help)
    env.define(interface_clear, procedure_clear)
    env.define(interface_commands, procedure_commands)
    env.define(interface_operators, procedure_operators)
    env.define(interface_quit, procedure_quit)
    env.define(interface_read_prompt, procedure_read_prompt)
    env.define(interface_pp_value, procedure_pp_value)
    env.define(interface_spp_value, procedure_spp_value)
}
