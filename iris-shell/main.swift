//
//  main.swift
//  iris-shell
//

// TO DO: better history support for multi-line input (currently history captures single lines only)

// TO DO: given multi-expression group `(1 LF + 2)`, how to clarify that this means `(1, +2)`, not `(1 + 2)` (i.e. the `1` is evaled and discarded, and the `2` is returned as the group expr’s result; in principle, PP could discard side-effect-free exprs whose results are unused, though automatically rewriting code to that extent should only be done after advising/asking the author as they may simply have mistyped in which case correction, not deletion, is required)

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
    let parser = IncrementalParser()
    while isRunning {
        EL_setIndent(Int32(parser.incompleteBlocks().count))
        let raw = (EL_read().takeRetainedValue() as String)
        if raw.isEmpty { break }
        let code = raw.trimmingCharacters(in: CharacterSet.newlines)
        if !code.isEmpty {
            parser.read(code)
            do {
                if let ast = parser.ast() {
                    //print("PARSED:", ast)
                    let result = try ast.eval(in: env, as: asAnything)
                    previousValue.set(to: result)
                    if let error = result as? SyntaxErrorDescription {
                        writeError(error.error)
                    } else {
                        writeResult(result)
                    }
                    parser.clear()
                }
            } catch {
                writeError(error)
                parser.clear()
            }
        }
    }
    EL_dispose()
}

runREPL()

