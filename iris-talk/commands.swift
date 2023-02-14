//
//  commands.swift
//  iris-talk
//

// TO DO: `help` should take `optional command` argument, e.g. `help write` should print documentation for `write` command

import Foundation
import AVFoundation
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
    
    `help`      – display this Help

    `_`         – (underscore) output the result of the previous line

    `clear`     – clear screen

    `commands`  – list all available commands

    `operators` – list all available operators
    
    `pp {value as optional}`
                – print a value;
                  if value is omitted, print the previous line
    
    `spp {value as optional}`
                – print a value's raw (Swift) description;
                  if value is omitted, print the previous line
    
    `read {prompt as optional string with_default "?"} returning string`
                – read next line of input from stdin, with customizable prompt
    
    `say {message as string} returning string`
                – speak and return the given text
    
    `unset {name as symbol} returning anything`
                – unset a value that was previously stored in the current scope
    
    `quit`      – exit the interactive shell
    
    ## Notes
    
    VT100 codes/Emacs-style key bindings are also supported, e.g. `Ctrl-L` to clear the screen, `Ctrl-C` to exit the shell.
    
    """)
    return nullValue
}


// `unset {name}` – remove from scope

private let type_unset_name = (
    name: Symbol("unset"),
    param_0: (Symbol("name"), Symbol("name"), asLiteralName),
    result: asIs
)

let interface_unset_name = HandlerType(
    name: type_unset_name.name,
    parameters: [
        nativeParameter(type_unset_name.param_0),
    ],
    result: type_unset_name.result.nativeCoercion
)
func procedure_unset_name(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0, value: Value = nullValue
    let arg_0 = try command.value(for: type_unset_name.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    if let env = commandEnv as? Environment {
        value = env.unset(arg_0) ?? nullValue
    }
    return value
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

func printHandlers(in env: Environment) {
    for (name, value) in env.frame.sorted(by: {$0.key < $1.key}) {
        if let handler = value as? Callable {
            writeHelp("\(handler.interface)\n")
        } else {
            writeHelp("‘\(name.label)’ – \(value)\n")
        }
    }
}

func procedure_commands(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    if command.arguments.count > 0 { throw UnknownArgumentError(at: 0, of: command, to: handler) }
    var env = commandEnv as? Environment
    if env == nil {
        print("Current scope is not an Environment so cannot currently be introspected.")
    }
    while let scope = env {
        print("Scope contains \(scope.frame.count) items:\n") // TO DO: how to identify/describe/name each scope? (library/handler/tell/etc)
        printHandlers(in: scope)
        env = scope.readOnlyParent()
        print()
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
    // note: operator registry is shared with sub-scopes so for now there is no need to inspect parent envs
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
    print("\(arg_0)\u{1b}[1m ", terminator: "")
    fflush(stdout)
    let rawInput = String(data: FileHandle.standardInput.availableData, encoding: .utf8) ?? ""
    print("\u{1b}[0m", terminator: "")
    let input = rawInput.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    return type_read_prompt.result.wrap(input, in: commandEnv)
}


// `say {text}` – output

private let type_say = (
    name: Symbol("say"),
    param_0: (Symbol("message"), Symbol("message"), asText),
    result: asText
)

let interface_say = HandlerType(
    name: type_say.name,
    parameters: [
        nativeParameter(type_say.param_0),
    ],
    result: type_say.result.nativeCoercion
)


func getVoice() -> AVSpeechSynthesisVoice? {
    for voice in AVSpeechSynthesisVoice.speechVoices() {
        if voice.name == "Allison" { return voice } // (premium voice can be d/l'd via system Settings)
    }
    return nil
}

func procedure_say(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_say.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let utterance = AVSpeechUtterance(string: arg_0.data)
    utterance.voice = getVoice()
    utterance.rate = 0.2
    AVSpeechSynthesizer().speak(utterance)
    return arg_0
}

// `pp {value}` – pretty-print value/previous input

private let type_pp_value = (
    name: Symbol("pp"),
    param_0: (Symbol("value"), Symbol("value"), AsSwiftOptional(asValue)), // TO DO: this is a bit problematic: the proc below really wants Value, with nullValue rather than nil, but AsOptional doesn't compose with asValue and is in any case not a SwiftCoercion which is what's needed to unpack arguments
    result: asIs
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
    return previousValue.immutableValue
}
// `spp {value}` – print Swift representation of value/previous input; caution this may raise exception for some types (if unsupported the fallback behavior is fatalError)

private let type_spp_value = (
    name: Symbol("spp"),
    param_0: (Symbol("value"), Symbol("value"), AsSwiftOptional(asValue)),
    result: asIs
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
    return previousValue.immutableValue
}



func loadREPLHandlers(_ env: Environment) {
    env.define(interface_help, procedure_help)
    env.define(interface_unset_name, procedure_unset_name)
    env.define(interface_clear, procedure_clear)
    env.define(interface_commands, procedure_commands)
    env.define(interface_operators, procedure_operators)
    env.define(interface_quit, procedure_quit)
    env.define(interface_read_prompt, procedure_read_prompt)
    env.define(interface_say, procedure_say)
    env.define(interface_pp_value, procedure_pp_value)
    env.define(interface_spp_value, procedure_spp_value)
}
