//
//  main.swift


import Foundation
import iris


// 'everything is a command' = 'right-hand rule: if a value (expr) appears after a command name, the command will take it as argument' (this is significant as 'variables' are just arg-less commands that retrieve the value stored under that name; this may produce unanticipated behavior, e.g. when the name is followed by an operator name that is available in both prefix/atom and infix/postfix forms; currently the [dumb] parser takes the prefix/atom form as command argument but it would be better/safer/more predictable to favor the infix/postfix form in lp (low-punctuation) commands, requiring the user to explicitly punctuate the command if they want it used as argument instead)



/*
let env = Environment()
let operatorRegistry = OperatorRegistry()

stdlib_loadHandlers(into: env)
stdlib_loadConstants(into: env)

stdlib_loadOperators(into: operatorRegistry)
let operatorReader = newOperatorReader(for: operatorRegistry)




func runScript(_ code: String) {

    print("\nPARSE:\n\(code)\n")

    let doc = EditableScript(code) { NumericReader(operatorReader(NameModifierReader(NameReader($0)))) }
    
    /*
    var ts: DocumentReader = QuoteReader(doc.tokenStream)
    while ts.token.form != .endOfCode { print(ts.token); ts = ts.next() }
    print()
    */
    
    let p = Parser(tokenStream: QuoteReader(doc.tokenStream), operatorRegistry: operatorRegistry)
    
        p.parseScript()
        if let script = p.scriptAST() {
            print("PARSED:", script)
            do {
                let result = try script.eval(in: env, as: asAnything)
                print("\nRESULT:", result)
            } catch {
                print(error)
            }
        } else {
            let errors = p.errors()
            if errors.isEmpty {
                let blocks = p.incompleteBlocks()
                print("\(blocks.count) block(s) need closing: \(blocks)")
            } else {
                print("Found \(errors.count) syntax error(s):")
                for e in errors { print(e) }
            }
        }
}


 */

func runScript(_ code: String) {
    print("SOURCE:" + (code.contains("\n") ? "\n" : ""), code)
    print()
    
    let parser = IncrementalParser()
    parser.read(code)
    
//    parser.parseLine("3/4")
//    parser.parseLine("5-6")
    
    if let script = parser.ast() {
        print("PARSED:", script)
        do {
            let result = try script.eval(in: parser.env, as: asAnything)
            print("\nRESULT:", result)
        } catch {
            print(error)
        }
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
    }

    
}

test()


