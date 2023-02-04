//
//  main.swift
//  iris-talk
//

// TO DO: debug `print()` calls in libiris that write to console between read and print steps will screw up backtracking when applying color formatting to the previously read line (TBH there’s no easy solution to this given limitations of terminal; we'd have to hook stdout and stderr… and pretty soon we’d end up rewriting curses)

// TO DO: given multi-expression group `(1 LF + 2)`, how to clarify that this means `(1, +2)`, not `(1 + 2)` (i.e. the `1` is evaled and discarded, and the `2` is returned as the group expr’s result; in principle, PP could discard side-effect-free exprs whose results are unused, though automatically rewriting code to that extent should only be done after advising/asking the author as they may simply have mistyped in which case correction, not deletion, is required)

// TO DO: CLI should enable experimentation with `!` and `?` modifiers (just need to decide how those are applied in blocks, e.g. should comma-separated exprs ending in !/? be grouped and the modifier attached to entire group/each expr in group, or should it only apply to immediately preceding expr? there is a good argument for treating entire comma sequence as a single modified group—else why bother with comma separators at all?—but need to check how that is scoped)

import Foundation
import iris

// TO DO: `--exclude=stdlib`, `--exclude=stdlib.operators` CLI options


// the previous line’s result will be stored under the name `_`
let previousValue = EditableValue(nullValue, as: asOptional) // TO DO: another case of mixing Swift with Native coercions

var previousInput: Value = nullValue

// TO DO: REPL session should probably run in subscope, with a write barrier between session env and the top-level environment containing stdlib (will give this more thought when implementing library loader, as libraries should by default share a single read-only env instance containing stdlib as their parent to avoid unnecessary overheads)


func runREPL(parser: IncrementalParser) {
    writeHelp("Welcome to the iris interactive shell. Please type `help` for assistance.")
    EL_init(CommandLine.arguments[0])
    try! parser.env.set("_", to: previousValue)
    let subenv = parser.env.subscope(withWriteBarrier: true) as! Environment
    let formatter = VT100TokenFormatter(env: subenv)
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
                if let ast = parser.ast() { // parser has accumulated a complete single-/multi-line expression sequence
                    //print("PARSED:", ast)
                    let result = try ast.eval(in: subenv, as: asAnything)
                    guard let prev = previousValue.get(nullSymbol) else {
                        print("Expected previous value but got nil")
                        exit(5)
                    } // bug if get() returns nil
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


//


func parseScript(_ code: String, parser: IncrementalParser) -> AbstractSyntaxTree? {
    //print("SOURCE:" + (code.contains("\n") ? "\n" : ""), code)
    //print()
    parser.read(code)
    if let script = parser.ast() {
        print("PARSED:", script)
        return script
    } else {
        let errors = parser.errors()
        if errors.isEmpty {
            let blocks = parser.incompleteBlocks()
            if !blocks.isEmpty {
                print("Incomplete script: \(blocks.count) block(s) need closing: \(blocks)")
            }
        } else {
            print("Found \(errors.count) syntax error(s):")
            for e in errors { print(e) }
        }
        return nil
    }
}

func runScript(_ script: AbstractSyntaxTree, env: Environment) {
    do {
        let result = try script.eval(in: env, as: asAnything)
        print("\nRESULT:", result)
    } catch {
        print(error)
    }
}



//

var argCount = 1
var willRun = true
var useOperators = true
var useStdlib = true // if disabled, REPL handlers are still loaded; allows non-standard libraries to be used instead (e.g. for code generation or documentation) or, if no libraries are loaded, "data-only" behavior analogous to JSON

// TO DO: pretty-print option

func readOptions() { // TO DO: move to UserDefaults?
    while argCount < CommandLine.arguments.count && CommandLine.arguments[argCount].hasPrefix("-") {
        switch CommandLine.arguments[argCount] {
        case "-h":
            print("iris [ -h -k -n -N ] [-] [ FILE ... ]")
            print()
            print("Options:")
            print()
            print("-h -- print this help")
            print()
            print("-k -- check .iris files' syntax")
            print()
            print("-n -- do not load operator syntax")
            print()
            print("-N -- do not load standard library")
            print()
            print("If one or more FILE is given, each is run in a new sub-context.")
            print()
            print("In no FILE is given, starts an interactive session.")
            exit(0)
        case "-k":
            willRun = false
        case "-n":
            useOperators = false
        case "-N":
            useStdlib = false
        case "-": // end of options list
            argCount += 1
            return
        default:
            print("Unknown option \(CommandLine.arguments[argCount])")
        }
        argCount += 1
    }
}
   

//
// TO DO: parser's env should be pre-initialized and passed to parser's constructor

let parser = IncrementalParser(withStdLib: false)

readOptions()


if useStdlib {
    stdlib_loadHandlers(into: parser.env)
    stdlib_loadConstants(into: parser.env)
    if useOperators {
        stdlib_loadOperators(into: parser.env.operatorRegistry)
    } else {
       // print("operators disabled")
    }
} else {
   // print("stdlib disabled")
}

loadREPLHandlers(parser.env) // for now, these are loaded in non-interactive mode as well


if argCount == CommandLine.arguments.count {
    runREPL(parser: parser)
} else {
    
    while argCount < CommandLine.arguments.count {
        let path = (CommandLine.arguments[argCount] as NSString).expandingTildeInPath
        let url = NSURL.fileURL(withPath: path)
        if let code = try? String(contentsOf: url, encoding: .utf8) {
            if (!willRun) { print("Checking file: \(path)") }
            if let script = parseScript(code, parser: parser) {
                if willRun {
                    runScript(script, env: parser.env)
                } else {
                    print("Syntax OK")
                }
            } else {
                print("Syntax error.")
            }
        } else {
            print("Can't read file: \(path)")
        }
        argCount += 1
    }
}
