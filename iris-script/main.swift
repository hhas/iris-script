//
//  main.swift


import Foundation


// 'everything is a command' = 'right-hand rule: if a value (expr) appears after a command name, the command will take it as argument' (this is significant as 'variables' are just arg-less commands that retrieve the value stored under that name; this may produce unanticipated behavior, e.g. when the name is followed by an operator name that is available in both prefix/atom and infix/postfix forms; currently the [dumb] parser takes the prefix/atom form as command argument but it would be better/safer/more predictable to favor the infix/postfix form in lp (low-punctuation) commands, requiring the user to explicitly punctuate the command if they want it used as argument instead)


let env = Environment()
let operatorRegistry = OperatorRegistry()

stdlib_loadHandlers(into: env)
stdlib_loadConstants(into: env)

stdlib_loadOperators(into: operatorRegistry)
let operatorReader = newOperatorReader(for: operatorRegistry)




func runScript(_ script: String) {

    print("\nPARSE: \(script.debugDescription)")

    let doc = EditableScript(script) { NumericReader(operatorReader(NameReader($0))) }
    
    /*
    var ts: DocumentReader = QuoteReader(doc.tokenStream)
    while ts.token.form != .endOfScript { print(ts.token); ts = ts.next() }
    print()
    */
    
    let p = Parser(tokenStream: QuoteReader(doc.tokenStream), operatorRegistry: operatorRegistry)
    do {
        let ast = try p.parseScript()
        print("PARSED:", ast)
        //print("RESULT:", try ast.eval(in: env, as: asAnything))
        let _ = ast
    } catch {
        print("ERROR:", error)
    }
    //print(script)
}


test()


