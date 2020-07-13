//
//  main.swift
//  iris-shell
//

import Foundation
import libIris




func readInput() -> String {
  let data = FileHandle.standardInput.availableData
  return String(data: data, encoding: String.Encoding.utf8)!.trimmingCharacters(in: CharacterSet.newlines)
}

func writeOutput(_ value: String) {
    print(value)
}

func writeError(_ error: Error) {
    fputs("☹︎ \(error)\n", stderr)
}


let env = Environment()
stdlib_loadHandlers(into: env)
stdlib_loadConstants(into: env)
let operatorRegistry = OperatorRegistry()
stdlib_loadOperators(into: operatorRegistry)
let operatorReader = newOperatorReader(for: operatorRegistry)

// the previous line’s result is stored under the name `_`
let previousValue = EditableValue(nullValue, as: asAnything)
try! env.set("_", to: previousValue)



env.define(interface_help, procedure_help)
env.define(interface_commands, procedure_commands)
env.define(interface_quit, procedure_quit)


func runREPL() {
    writeOutput("Welcome to the iris runtime’s interactive shell. Type `help` for assistance.")
    while isRunning {
        fputs("✎ ", stderr)
        let code = readInput()
        
        if !code.isEmpty {
            let doc = EditableScript(code) { NumericReader(operatorReader(NameModifierReader(NameReader($0)))) }
            let p = Parser(tokenStream: QuoteReader(doc.tokenStream), operatorRegistry: operatorRegistry)
            
            do {
                let ast = try p.parseScript()
                //print("PARSED:", ast)
                let result = try ast.eval(in: env, as: asAnything)
                previousValue.set(to: result)
                writeOutput("☺︎ \(result)")
            } catch {
                writeError(error)
            }
        }
    }
}

runREPL()

