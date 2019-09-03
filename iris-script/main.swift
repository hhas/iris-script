//
//  main.swift


import Foundation


let env = Environment()

stdlib_loadHandlers(into: env)
stdlib_loadConstants(into: env)

let operatorRegistry = OperatorRegistry()
stdlib_loadOperators(into: operatorRegistry)
stdlib_loadKeywords(into: operatorRegistry) // temporary while we bootstrap stdlib + gluelib
let operatorReader = newOperatorReader(for: operatorRegistry)



func test() {
    
    // TO DO: need underscore reader
    
    var script:String = "1 + 1"
    //script = "foo [1, 2,\n3\n [:]] arg: “yes” um: false."
    //script = "1 + 2 / 4.6" // TO DO: operator parsing is still buggy
    //script = "foo bar baz: fub zim: bip {dob} nag: 0"
    
    //    script = "tell app “TextEdit” to make new: #document at: end of documents with_properties: {name: “Test”, text: “blah”}"
    
    
    //
    script = "[1, 2, 3, 4, 5, 6], 7."
    
    script = "1, [2, 3]! 4, 5."
    
    script = "Foo, bar; baz to: bip; fub, bim." //     Foo, fub {baz {bar, to: bip}}, bim

    
    script = "make new: #document at: end of documents with_properties: {name: “Test”, text: “blah”}."
    
    script = "get name of file at 1 of home"
    
    
    
    script = "1, do 2, 3, 4, 5 done \n 6" // note: no separator between `done` and `6` ends parsing prematurely; hopefully table-driven parser will be better at autocorrecting punctuation
    
    script = "if 1 + 1 = 2 then beep, write “ok”! 5, 6, 7, 8, 9! 000."
    
    script = "tell app “TextEdit” to make new: #document at: end of documents with_properties: {name: “Test”, text: “blah”}."
    
    
    script = "to foo: write “ok”, bar. baz, gub, guf."
    
    script = "To say_hello to: name: write “Hello, ” & name & “!”. Say_hello to: “World”."
    
    script = "write 2 + 2"
    
    script = "document at 1"
    
    script = "1 + 1 = 2" // -> true
    
    script = "if 1 + 2 = 5 then write “ok”."
    script = "set Bob to: “Tim”. if 1 + 2 = 3 then write 6, write bob, write 9 ÷ 2." // TO DO: make sure operator definition + handler interface describes right-hand operand as an expr sequence ('sentence'?), esp. in documentation
    
    script = "Set name to: “Bob”. If 1 + 2 = 3 then write true, write name, write [9 ÷ 2]."
    
    script = "if 1 + 1 = 5 then “BOO!”"
    
    script = "tell app “iTunes” to get name of current_track" // TO DO: readCommand should return on encountering `to` keyword but throws instead
    
    script = "if 1+1=4 then 1 else -1"
    
    //script = "write true"

    //script = "if 1 + 2 = 3, 4 then 6, 8, 9." // this (correctly) reports parse error on unexpected `then` keyword
    //script = "if 1 + 2 = 3, 4, 5, 6." // this does parse successfully (parser treats first comma as equivalent to `then` separator); PP should probably convert to canonical form
    //script = "if (1 + 2 = 5, true) then write “ok”." // this also parses successfully; Q. should parser/pp have the smarts to flag the parensed sequence as "suspect", given that the `1+2=5` is effectively a no-op (bear in mind it's also a way to accidentally/deliberately hide effectful operations)
   // script = "map {foo, using: {i}: bar}; fub" // this works and is unambiguous
  //  script = "foo; map using: {i}: bar; fub" // this works [as long as proc has explicit label], but the right-side of colon pair captures `bar; fub` whereas the user may reasonably expect both colons to be top-level, as they are in `foo; bar; baz` (i.e. semicolons should probably terminate nested sentences)
    //script = "foo; map {i}: bar; fub" // TO DO: reject this syntax as ambiguous? it parses as `((‘map’ {‘foo’, ‘i’}: ‘fub’ {‘bar’}))`, which isn't what's intended (left side of colon pair within a block expr should always be a literal name; thus any form of `cmd, name{…}:…` or `cmd; name:…` should be rejected due to existence of argument record)
    //script = "foo; map ({i}: bar); fub" // this works: `(‘fub’ {‘map’ {‘foo’, ({‘i’}: ‘bar’)}})`
    //script = "foo; map {{i}: bar}; fub" // TO DO: this needs to provide better error description (the procedure Pair needs to be parensed to distinguish it from a record field Pair [albeit one with an invalid label type])
    //script = "foo; map {({i}: bar)}; fub" // TO DO: this fails due to parser bug (probably readRecord being unaware of parens)
    //script = "if t1 then if t2 then a1 else a2 else a3" // TO DO: this doesn't parse correctly
    
    let doc = EditableScript(script) { NumericReader(operatorReader(NameReader($0))) }
    
    /*
    var ts: BlockReader = QuoteReader(doc.tokenStream)
    while ts.token.form != .endOfScript { print(ts.token); ts = ts.next() }
    print()
    */
    
    let p = Parser(tokenStream: QuoteReader(doc.tokenStream), operatorRegistry: operatorRegistry)
    do {
        let script = try p.parseScript()
        print("PARSED:", script)
        print("RESULT:", try script.eval(in: env, as: asAnything))
    } catch {
        print(error)
    }
}


test()

/*
 
 
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
*/


/*
let scriptLines = script.split(omittingEmptySubsequences: false, whereSeparator: linebreakCharacters.contains)

print(scriptLines)

for line in scriptLines {
    if let lineReader = CoreLexer(String(line)) {
        var lexer: LineReader = NumericReader(lineReader)
        var token: Token
        repeat {
            (token, lexer) = lexer.next()
            print(token)
        } while !token.isEndOfLine
    } else {
        print("blank line")
    }
    print("--")
}
*/



/*
try env.define(
    HandlerInterface(name: "foo", parameters: [("number", nullSymbol, AsEditable(asNumber))], result: asNothing),
    Block([Command("show", [(nil, Command("bar"))])]))

let v = Text("313.0")



//let _ = try Command("foo", [(nil, v)]).eval(in: env, as: asAnything)

do {

    try env.set("bar", to: EditableValue(123, as: asNumber))

    let r = try Command("foo", [(nil, Command("bar"))]).eval(in: env, as: asAnything)

    print(r)
    
    let v2 = env.get("bar") as! EditableValue

    print("a=", v2)

    try v2.set(nullSymbol, to: 6)

    print("b=", v2)
    
    try env.set(Symbol("bar"), to: 7)
    
    print("b2=", v2)
    
    // TO DO: does 'editable parameter' need to be different to 'editable value'? i.e. AsEditableValue evals the input value and outputs it in a mutable box; whereas AsEditableParameter requires its input to be an editable value, evals the value using the intersection of its original and parameter types, stores the result back in the box and adds that box to the handler scope (Q. does this mean the editable box's constrained type also needs updated to the intersection? Remember, all changes to that box made by/within the handler are shared with the calling scope [c.f. pass-by-reference]).

    print("c=", try v2.eval(in: env, as: AsList(asString)))

    print("d=", try v2.eval(in: env, as: AsEditable(asString))) // (bear in mind asString only coerces to scalar; it won't convert Number to String so the number will still appear unquoted, which is fine)

} catch {
    print(error)
}


*/

/*
struct AddHandler: Handler { // 5x faster than standard implementation (which is to say, still dog-slow)
    
    var isStaticBindable: Bool { return true }
    
    let interface = HandlerInterface(name: "add", parameters: [
        (label: leftOperand, nullSymbol, coercion: asNumber),
        (label: rightOperand, nullSymbol, coercion: asNumber)],
                                     result: asNumber)
    
    func call(with command: Command, in commandScope: Scope, as coercion: Coercion) throws -> Value {
        // caution: this ignores argument labels
        if command.arguments.count != 2 { throw BadArgumentError(at: 0, of: command) }
        let a = command.arguments[0].1
        let b = command.arguments[1].1
        switch (a,b) {
        case (let a as Int, let b as Int):
            let (r, o) = a.addingReportingOverflow(b)
            return o ? Double(a) + Double(b) : r
        case (let a as Int, let b as Double): return Double(a) + b
        case (let a as Double, let b as Int): return a + Double(b)
        case (let a as Double, let b as Double): return a + b
        default:()
        }
        let arg_0 = try a.swiftEval(in: commandScope, as: asNumber)
        let arg_1 = try b.swiftEval(in: commandScope, as: asNumber)
        return try add(left: arg_0, right: arg_1)
    }
    
    func swiftCall<T: SwiftCoercion>(with command: Command, in dynamicScope: Scope, as coercion: T) throws -> T.SwiftType {
        throw NotYetImplementedError()
    }
    
    //
    
    func eval(in scope: Scope, as coercion: Coercion) throws -> Value {
        return try coercion.coerce(value: self, in: scope)
    }
    
    func swiftEval<T: SwiftCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
        return try coercion.unbox(value: self, in: scope)
    }
}
try env.set("add", to: AddHandler())



do {
    print(try v.eval(in: env, as: asInt))
    
    print(try v.eval(in: env, as: asString))
    
    do {
        let code = Command("+", [(nil, 4), (nil, 8.5)])
        let d = Date()
        for _ in 0..<100000 {
            let _ = (try code.eval(in: env, as: asNumber))
        }
        print("a =", Date().timeIntervalSince(d))
    }
    do {
        let code = Command("add", [(nil, 4), (nil, 8.5)])
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
    
    print(try Command("+", [(nil, 4), (nil, 8.5)]).eval(in: env, as: asNumber))
    
    
    print(try Command("&", [(nil, Text("foo")), (nil, Text("bar"))]).eval(in: env, as: asString))
    
} catch {
    print(error)
}

// scalars (atomic values) encapsulate boolean, integer, real, string, date, URL (née file), symbol; Q. which of these should appear as a single datatype? (e.g. numbers are really just degenerate strings, as are dates and URLs; if they look right, they should just work; OTOH, bools are rather awkward and we may prefer to adopt Icon-style success/failure or even kiwi-style empty/non-empty, while symbols must be syntactically distinct from strings to indicate semantic difference); also nothing (null), and possibly specialized did_nothing (c.f. Icon 'fail') for use in composable flow control expressions (e.g. for `TEST_EXPR else EXPR` where TEST_EXPR = `if BOOL EXPR`, multiple-test conditionals can be composed as `TEST_1 else TEST_2 else EXPR`)

// collections encapsulate ordered list (array), key-value list (dictionary), unique list (set)

// Q. what about structures? we can support records (ordered property sets, aka optionally labeled tuples) and/or [script] objects (encapsulated environment scopes); records offer one way to pass unary-command arguments, particularly if optional labels can be inferred by consumer (structural typing, pattern matching; esp if some form of multimethods is provided as alternative to traditional object encapsulation of single-dispatch OO; also bear in mind pattern-matched dispatch on multiple arguments fits far better with AEOM)

// complex values: commands, blocks (expression sequences); handlers (a composition of command-as-interface and expression [sequence], stored in an environment scope); what about identifiers/variables? or should we adopt entoli's everything-is-a-unary-command-that-takes-an-optional-argument instead, which may be conceptually cleaner and easier to explain as it describes everything as concrete behaviors rather than abstract name bindings? (we do need to consider single-assignment, non-maskable names, c.f. sylvia, as these are vital to predictable operator behavior given that operators are merely library-supplied syntactic sugar over library-defined commands)

// homoiconic; while it may lack Lisp’s extreme everything-is-a-list parsimony, all code is data and can be manipulated accordingly; in particular, a Shortcuts-style workflow is trivially encoded as an expression sequence, using pipeline operator when output of one command should be passed as first argument to the next

// handler interfaces must be fully introspectable; this includes parameter and result type constraints (Coercions) and errors throwable, user documentation, and metadata (keywords, categories, targets, etc); in additional to traditional text-based autosuggest, autocomplete, etc. interface introspection enables easy lightweight GUI form generation (auto-populating a window/panel with familiar GUI controls, labels, tooltips, etc into which an end-user can input arguments) and interactive voice input too: 3 UI modes for the price of 1

// chunk exprs? (aka “operator-precedence-is-a-pig-when-everything-is-a-unary-command-by-default”)

// possible block syntax[es]: comma-separated exprs, terminated by linebreak or period; `do…done`; `(…)`, `[…]`, `{…}`

// multi-word names must use underscores, not camelcase or other conventions, as those are easiest to parse as visual/spoken phrases (a code editor can reduce opacity of underscore chars to improve code readability without losing semantic clarity); true whitespace-in-identifiers (c.f. kiwi, entoli) is not desirable due to the tradeoffs that requires [and AppleScript-style parser “magic” is right out]

*/
