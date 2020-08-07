//
//  main.swift
//  iris-shell
//

// TO DO: debug `print()` calls in libiris that write to console between read and print steps will screw up backtracking when applying color formatting to the previously read line (TBH there’s no easy solution to this given limitations of terminal; we'd have to hook stdout and stderr… and pretty soon we’d end up rewriting curses)

// TO DO: given multi-expression group `(1 LF + 2)`, how to clarify that this means `(1, +2)`, not `(1 + 2)` (i.e. the `1` is evaled and discarded, and the `2` is returned as the group expr’s result; in principle, PP could discard side-effect-free exprs whose results are unused, though automatically rewriting code to that extent should only be done after advising/asking the author as they may simply have mistyped in which case correction, not deletion, is required)

// TO DO: CLI should enable experimentation with `!` and `?` modifiers (just need to decide how those are applied in blocks, e.g. should comma-separated exprs ending in !/? be grouped and the modifier attached to entire group/each expr in group, or should it only apply to immediately preceding expr? there is a good argument for treating entire comma sequence as a single modified group—else why bother with comma separators at all?—but need to check how that is scoped)

import Foundation
import iris

// TO DO: `--exclude=stdlib`, `--exclude=stdlib.operators` CLI options


// the previous line’s result will be stored under the name `_`
let previousValue = EditableValue(nullValue, as: asAnything.nativeCoercion) // TO DO: another case of mixing Swift with Native coercions

var previousInput: Value = nullValue

// TO DO: REPL session should probably run in subscope, with a write barrier between session env and the top-level environment containing stdlib (will give this more thought when implementing library loader, as libraries should by default share a single read-only env instance containing stdlib as their parent to avoid unnecessary overheads)


func runREPL() {
    writeHelp("Welcome to the iris runtime’s interactive shell. Type `help` for assistance.")
    EL_init(CommandLine.arguments[0])
    let parser = IncrementalParser()
    loadREPLHandlers(parser.env)
    try! parser.env.set("_", to: previousValue)
    let formatter = VT100TokenFormatter()
    parser.adapterHook = { VT100Reader($0, formatter) } // install extra lexer stage
    var block = "" // captures multi-line input for use in history
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
            EL_rewriteLine(raw, formatter.read()) // replace the plain line input with the VT100-formatted code
            do {
                if let ast = parser.ast() { // parser has accummulated a complete single-/multi-line expression sequence
                    //print("PARSED:", ast)
                    let result = try ast.eval(in: parser.env, as: asAnything)
                    guard let prev = previousValue.get(nullSymbol) else { exit(5) } // bug if get() returns nil
                    let ignoreNullResult = prev is NullValue
                    previousValue.set(to: result)
                    if let error = result as? SyntaxErrorDescription { // TO DO: this is a bit hazy as we decide exactly how to encapsulate and discover syntax errors within AST
                        writeError(error.error)
                    } else if !(ignoreNullResult && result is NullValue) {
                        writeResult(result)
                    }
                    previousInput = ast
                    EL_writeHistory(block)
                    block = ""
                    parser.clear() // once the expression is evaluated, clear it so parser can start reading next one
                } // else the expression is incomplete, e.g. if first line is `[[1]`, will continue reading lines until the closing "]" is received
            } catch {
                previousInput = nullValue
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

