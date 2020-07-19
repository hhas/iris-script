//
//  main.swift
//  iris-shell
//

// TO DO: how to handle multi-line strings? (currently typing LF within a string literal breaks input)

// TO DO: better history support for multi-line input (currently history captures single lines only)

// TO DO: given multi-expression group `(1 LF + 2)`, how to clarify that this means `(1, +2)`, not `(1 + 2)` (i.e. the `1` is evaled and discarded, and the `2` is returned as the group expr’s result; in principle, PP could discard side-effect-free exprs whose results are unused, though automatically rewriting code to that extent should only be done after advising/asking the author as they may simply have mistyped in which case correction, not deletion, is required)

import Foundation
import iris

// TO DO: `--exclude=stdlib`, `--exclude=stdlib.operators` CLI options


// the previous line’s result will be stored under the name `_`
let previousValue = EditableValue(nullValue, as: asAnything)


// load REPL-specific handlers into environment
func loadSessionState(_ env: Environment) {
    // load REPL-specific commands
    env.define(interface_help, procedure_help)
    env.define(interface_commands, procedure_commands)
    env.define(interface_quit, procedure_quit)
    try! env.set("_", to: previousValue)
}

// TO DO: REPL session should probably run in subscope, with a read-only barrier between that and the top-level environment


func runREPL() {
    writeHelp("Welcome to the iris runtime’s interactive shell. Type `help` for assistance.")
    EL_init(CommandLine.arguments[0])
    let parser = IncrementalParser()
    let formatter = VT100Formatter()
    parser.adapterHook = { VT100Reader($0, formatter) } // install extra lexer stage
    var block = "" // captures multi-line input for use in history
    loadSessionState(parser.env)
    while isRunning {
        let indent = parser.incompleteBlocks().count
        block += String(repeating: " ", count: indent)
        EL_setIndent(Int32(indent))
        let raw = (EL_readLine().takeRetainedValue() as String)
        if raw.isEmpty { break }
        let code = raw.trimmingCharacters(in: CharacterSet.newlines)
        if !code.isEmpty {
            block += code + "\n"
            parser.read(code) // modified lexer chain writes VT100-annotated code to VT100Formatter as a side-effect
            EL_rewriteLine(raw, formatter.read()); // re-print code, this time in color
            do {
                if let ast = parser.ast() { // parser has a complete single-/multi-line expression, so evaluate it
                    //print("PARSED:", ast)
                    let result = try ast.eval(in: parser.env, as: asAnything)
                    previousValue.set(to: result)
                    if let error = result as? SyntaxErrorDescription {
                        writeError(error.error)
                    } else {
                        writeResult(result)
                    }
                    EL_writeHistory(block)
                    block = ""
                    parser.clear() // once the expression is evaluated, clear it so parser can start reading next one
                } // else expression is incomplete, e.g. "[[1]" will continue reading lines until the closing "]" is received, allowing parser to complete the AST
            } catch {
                EL_writeHistory(block)
                block = ""
                writeError(error)
                parser.clear()
            }
        }
    }
    EL_dispose()
}

runREPL()

