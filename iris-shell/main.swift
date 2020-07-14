//
//  main.swift
//  iris-shell
//

import Foundation
import iris


// load standard library into an Environment instance // TO DO: `--exclude=stdlib`, `--exclude=stdlib.operators` CLI options
let env = Environment()
stdlib_loadHandlers(into: env)
stdlib_loadConstants(into: env)
let operatorRegistry = OperatorRegistry()
stdlib_loadOperators(into: operatorRegistry)
let operatorReader = newOperatorReader(for: operatorRegistry)

// the previous line’s result will be stored under the name `_`
let previousValue = EditableValue(nullValue, as: asAnything)
try! env.set("_", to: previousValue)

// load REPL-specific commands
env.define(interface_help, procedure_help)
env.define(interface_commands, procedure_commands)
env.define(interface_quit, procedure_quit)

// TO DO: REPL session should probably run in subscope, with a read-only barrier between that and the top-level environment

func newLineReader(_ source: LineReader) -> LineReader {
    return NumericReader(operatorReader(NameModifierReader(NameReader(source))))
}


func runREPL() {
    writeHelp("Welcome to the iris runtime’s interactive shell. Type `help` for assistance.")
    EL_init(CommandLine.arguments[0])
    while isRunning {
        let raw = (EL_read().takeRetainedValue() as String)
        if raw.isEmpty { break }
        let code = raw.trimmingCharacters(in: CharacterSet.newlines)
        if !code.isEmpty {
            let doc = EditableScript(code, newLineReader)
            let p = Parser(tokenStream: QuoteReader(doc.tokenStream), operatorRegistry: operatorRegistry)
            do {
                let ast = try p.parseScript()
                //print("PARSED:", ast)
                let result = try ast.eval(in: env, as: asAnything)
                previousValue.set(to: result)
                writeResult(result)
            } catch {
                writeError(error)
            }
        }
    }
    EL_dispose()
}

runREPL()

