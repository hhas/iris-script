//
//  misc tests.swift
//  iris-script
//

import Foundation
import iris



/*


func test2() {
    
    var script = "nothing"
    
    script = "‘foo’ -1*-2+a3" // note that `a3` is initially two tokens: `.letters "a"` and `.digits "3"`; these are reduced by NameReader to a single `.unquotedName("a3")` token
    
    //script = " “blah blah”"
    
    //script = "3𝓍²＋5𝓎－1" // this requires some custom lexing (needs transformed to `(3 * x ^ 2) + (5 * y) + (1)`; of course, the real question is, once transformed, how to manipulate it symbolically?)
    
    
    //print(operatorRegistry)
    
    //let doc = EditableScript(script)
    //let doc = EditableScript(script, {NumericReader(operatorReader(NameReader($0)))})
    
    
    
    let d1 = Date()
    
    let doc = EditableScript(script, {NumericReader(operatorReader($0))})
    
    //let doc = EditableScript(script)
    let d2 = Date()
    
    print(doc)
    print("parsed in \(String(format: "%0.2f", d2.timeIntervalSince(d1)*1000))ms")
    
    print(doc.debugDescription)
    
    
    
    
    let scriptLines = script.split(separator: "\n", omittingEmptySubsequences: false)
    
    print(scriptLines)
    
    for line in scriptLines {
        if let lineReader = BaseLexer(String(line)) {
            var lexer: LineReader = NumericReader(lineReader)
            var token: Token
            loop: while true {
                (token, lexer) = lexer.next()
                print(token)
                switch token.form {
                case .lineBreak, .endOfCode: break loop
                default: ()
                }
            }
        } else {
            print("blank line")
        }
        print("--")
    }
    
    
    
    do {
        
        
        try env.define(
            HandlerType(name: "foo", parameters: [("number", nullSymbol, AsEditable(asNumber))], result: asNothing),
            Block([Command("show", [(nullSymbol, Command("bar"))])]))
        
        
        //
        
        //let _ = try Command("foo", [(nullSymbol, v)]).eval(in: env, as: asAnything)
        
        
        try env.set("bar", to: EditableValue(123, as: asNumber))
        
        let r = try Command("foo", [(nullSymbol, Command("bar"))]).eval(in: env, as: asAnything)
        
        print(r)
        
        let v2 = env.get("bar") as! EditableValue
        
        print("a=", v2)
        
        try v2.set(nullSymbol, to: 6)
        
        print("b=", v2)
        
        try env.set(Symbol("bar"), to: 7)
        
        print("b2=", v2)
        
        // TO DO: does 'editable parameter' need to be different to 'editable value'? i.e. AsEditableValue evals the input value and outputs it in a mutable box; whereas AsEditableParameter requires its input to be an editable value, evals the value using the intersection of its original and parameter types, stores the result back in the box and adds that box to the handler scope (Q. does this mean the editable box's constrained type also needs updated to the intersection? Remember, all changes to that box made by/within the handler are shared with the calling scope [c.f. pass-by-reference]).
        
        print("c=", try v2.eval(in: env, as: AsOrderedList(asString)))
        
        print("d=", try v2.eval(in: env, as: AsEditable(asString))) // (bear in mind asString only coerces to scalar; it won't convert Number to String so the number will still appear unquoted, which is fine)
        
    } catch {
        print(error)
    }
}



func test3() {
    
    do {
        
        try env.set("add", to: AddHandler())
        
        let v = Text("313.0")
        
        
        print(try v.eval(in: env, as: asInt))
        
        print(try v.eval(in: env, as: asString))
        
        do {
            let code = Command("+", [(nullSymbol, 4), (nullSymbol, 8.5)])
            let d = Date()
            for _ in 0..<100000 {
                let _ = (try code.eval(in: env, as: asNumber))
            }
            print("a =", Date().timeIntervalSince(d))
        }
        do {
            let code = Command("add", [(nullSymbol, 4), (nullSymbol, 8.5)])
            let d = Date()
            for _ in 0..<100000 {
                let _ = (try code.eval(in: env, as: asNumber))
            }
            print("b =", Date().timeIntervalSince(d))
        }
        do {
            let a = Number(4.5)
            let b = Number(6)
            let d = Date()
            for _ in 0..<100000 {
                let _ = try add(left: a, right: b)
            }
            print("c1=", Date().timeIntervalSince(d))
        }
        do {
            let a = Number(4.5) // boxing as Number is 20x slower than Int/Double
            let b = Number(6)
            let d = Date()
            for _ in 0..<100000 {
                let _ = try a + b
            }
            print("c2=", Date().timeIntervalSince(d))
        }
        do {
            let a = 4
            let b = 6
            let d = Date()
            for _ in 0..<100000 {
                let _ = a.addingReportingOverflow(b)
            }
            print("d1=", Date().timeIntervalSince(d))
        }
        do {
            let a = 4.5
            var b = 6
            b += 1
            let d = Date()
            for _ in 0..<100000 {
                let _ = a + Double(b)
            }
            print("d2=", Date().timeIntervalSince(d))
        }
        do {
            let a = 4.5
            let b = 6.0
            let d = Date()
            for _ in 0..<100000 {
                let _ = a + b
            }
            print("e =", Date().timeIntervalSince(d))
        }
        do {
            let a = 4.5
            let b = 6
            let d = Date()
            for _ in 0..<100000 {
                let _ = a + Double(b)
            }
            print("f =", Date().timeIntervalSince(d))
        }
        
        print(try Command("+", [(nullSymbol, 4), (nullSymbol, 8.5)]).eval(in: env, as: asNumber))
        
        
        print(try Command("&", [(nullSymbol, Text("foo")), (nullSymbol, Text("bar"))]).eval(in: env, as: asString))
        
    } catch {
        print(error)
    }
}


*/

