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




func test() {
    
    runScript("foo * bar") // ‘*’ {‘foo’, ‘bar’}
    runScript("foo - 1") // TO DO: determine if `-` operator is prefix or infix/postfix based on whitespace before/after (currently defaults here to prefix)
    
    runScript("get name of file at 1 of home")
    

  //  return;
    
    runScript("1 + 1")
    
    runScript(" [] ")
    runScript(" [:] ")
    runScript(" () ")
    runScript(" {} ")
    
    runScript(" [1] ")
    runScript(" [2:3] ")
    runScript(" (4) ")
    runScript(" {5} ")
    
    runScript(" {foo: 1} ")
    runScript(" {foo: 1, bar: 2, baz: fub zim bim zub} ")
    runScript(" {foo: 1, bar: 2, baz: fub zim bim: zub} ")
    runScript(" {foo: 1, bar: 2, baz: fub zim: bim zub} ")
    runScript(" {mod: 1, div: 2} ")

  //  return;
    

  //  runScript("foo [1, 2,\n3\n [:]] arg: “yes” um: false.")

    runScript("1 + 2 / 4.6") // TO DO: operator parsing is still buggy

    runScript("foo bar baz: fub zim: bip {dob} nag: 0")

    runScript("tell app “TextEdit” to make new: #document at: end of documents with_properties: {name: “Test”, text: “blah”}")

    runScript("[1, 2, 3, 4, 5, 6], 7.")

    runScript("1, [2, 3]! 4, 5.")

    runScript("Foo, bar; baz to: bip; fub, bim.") //     Foo, fub {baz {bar, to: bip}}, bim

    runScript("make new: #document at: end of documents with_properties: {name: “Test”, text: “blah”}.")

    runScript("get name of file at 1 of home")

 //   runScript("1, do, 2, 3, 4, 5, done \n 6") // note: no separator between `done` and `6` ends parsing prematurely; hopefully table-driven parser will be better at autocorrecting punctuation // TO DO: this currently fails in reduce(conjunction:…), mostly likely a bug when parsing `do…done`

    runScript("if 1 + 1 = 2 then beep, write “ok”! 5, 6, 7, 8, 9! 000.")

    runScript("tell app “TextEdit” to make new: #document at: end of documents with_properties: {name: “Test”, text: “blah”}.")

    runScript("to foo: write “ok”, bar. baz, gub, guf.")

    runScript("To say_hello to: name: write “Hello, ” & name & “!”. Say_hello to: “World”.")

    runScript("write 2 + 2")

    runScript("document at 1")

    runScript("1 + 1 = 2") // -> true

    runScript("if 1 + 2 = 5 then write “ok”.")

    runScript("set Bob to: “Tim”. if 1 + 2 = 3 then write 6, write bob, write 9 ÷ 2.") // TO DO: make sure operator definition + handler interface describes right-hand operand as an expr sequence ('sentence'?), esp. in documentation

    runScript("Set name to: “Bob”. If 1 + 2 = 3 then write true, write name, write [9 ÷ 2].")

    runScript("if 1 + 1 = 5 then “BOO!”")

    runScript("tell app “iTunes” to get name of current_track") // TO DO: readCommand should return on encountering `to` keyword but throws instead

    runScript("if 1+1=4 then 1 else -1")

    runScript("document at 1")

    runScript("tell app “com.apple.TextEdit” to get every word of text of document at 1")
        // ["hello", "again"]

    /*
    runScript("""
        tell app “com.apple.TextEdit” to do
            make new: #document at: end of documents with_properties: {
                name: “Test”,
                text: “hello again”
            }
        done
        """)
    */
    runScript("tell app “com.apple.TextEdit” to get first document whose text is “” and name begins_with “Untitled”")
    
        // TO DO: problem is that 'thru' binds tighter than 'at'; we could make 'thru' bind looser than [inner] at if we change outer 'at' to different operator, e.g. 'documents from document at 2 thru document at 3'; Q. would it be practical/wise to define infix 'to' operator for constructing ranges, e.g. `1 to 10`? Q. how does `to` know when to clear left? e.g. `a to b` is ambiguous, as it could read as `a {'to' {b}}`

    runScript("tell app “com.apple.TextEdit” to get documents from (document at 2) thru (document at 3)")
    
        // TO DO: `tell` parsefunc needs to match `to` keyword, but defining an infix `to` operator causes that to match instead, resulting in failed parse
        //
        // alternative is to give up on `from…to…` and use `in…thru…` (though ideally we want a generalized solution that will use same rules regardless of i18n)

    runScript("tell app “com.apple.TextEdit” to get documents from 2 thru -1")
    
    
        // TO DO: period/LF needs higher 'precedence' than `else`; might need to change how ExpressionSequence is constructed (e.g. split into ExpressionSeq vs BlockSeq, with the former limited to single sentences; maybe rename `Sentence` and `Paragraph`)

    runScript("""
        Set a to: 3, set b to: true. If 3 + a = 4 then "A" else if b then "B" else "C".
        """)

    runScript(" if a then (b, c, d) else (e, f). ") // TO DO: sentence blocks (multiple comma-separated exprs) in `then clause` are problematic as punctuation has lower precedence than operators; would need to special-case parsing of block operands

    runScript(" if a then (b, c, d) else (e, f). ")

    runScript(" a + - b ")

    runScript(" [1:2, 3:4, 5:6] ")

    runScript(" 1 + 2 * -3 ")

    runScript(" a 1 b: 2 c: 3")

    runScript(" [1,2,4] ")

    runScript(" [1:2, 3:4, 5:6], [1,3,6], (7), (), (8,9), {a:0, b:3} ")

    runScript(" 1 + [2,4] * 3 ")

    runScript(" 1 + 2 * -3 ")

    runScript(" 1 = 2 + 3 ")

    runScript(" 1 + 2 = 3 ")

    runScript(" 1 + 2 * 3 = 4 ")

    runScript(" if -1 * 2 + -3 = -4 then 5 + 6 else -7 ÷ -8 ")
    
        // full punctuation command syntax

    runScript("  {1, bar: 2, baz: fub, mod: 3} ")

    runScript(" foo {1} ")

    runScript(" foo ")
    
        // low-punctuation command syntax

    runScript(" foo ")

    runScript(" foo 1 ")

    runScript(" foo baz: 2 ")

    runScript(" foo baz: 2 mod: 3 ")

    runScript(" foo 1 baz: 2 mod: 3 ")

    runScript(" foo baz: 2 mod: 3 of 4 + bar fub: 5 ") // ‘+’ {‘foo’ {baz: 2, mod: ‘of’ {3, 4}}, ‘bar’ {fub: 5}}

        // low-punctuation command syntax with nested commands (commands nested within an LP command can have record argument, non-record direct argument, or no argument only; i.e. labeled arguments after a nested command belong to the outer LP command)

    runScript(" foo fub: bar baz: 2") // ‘foo’ {fub: ‘bar’, baz: 2}

    runScript(" foo fub: bar 3 baz: 2") // ‘foo’ {fub: ‘bar’ {3}, baz: 2}

    runScript(" foo fub: bar zim boo 3 baz: 2") // ‘foo’ {fub: ‘bar’ {3}, baz: 2}

    runScript(" foo fub: bar zim boo baz: 2")

    runScript(" foo fub: bar baz: 2")

    runScript(" foo baz: bar")

    runScript(" foo bar baz")

    runScript(" foo bar ")
    
        // TO DO: where an operator is both infix and prefix, need to decide if it's an argument to left command or if the left command is the left operand to the operator; currently these all parse `-` as infix operator

    runScript(" foo - bar ") // infix `-`

    runScript(" foo -bar ") // assuming this follows WS rule and parses as `foo {'-' {bar}}`, we may want the PP to parenthesize the argument as `foo {-bar}` to make clear to user how it has interpreted that code

    runScript(" foo - 1 ") // infix `-`

    runScript(" foo -1 ") // PP might not need to parenthesize the argument here as `-1` is fairly obviously a number literal, and thus clearly intended by the user(?) as an argument to `foo`

    runScript(" document at 1 ") // `document at 1` *must* take `document` as the left operand to `at`, regardless of precedence, since `at` has no prefix form (infix only)

    runScript(" get document at 1 ") // should reduce to `get{'at'{document{}, 1}}`

    runScript(" foo of bar ") // here the infix `of` operator MUST terminate `foo` command, regardless of precedence (command precedence only comes into play if there is an expr inbetween `foo` and `of`, e.g. `foo 1 of 2`)

    runScript(" foo 1 bar: 2 ")

    runScript(" foo 1 ")

    runScript(" foo 1 bar: 2 mod: 3 ") // ‘foo’ {1, bar: 2, mod: 3}

    runScript(" foo 1 bar: baz mod: 3 ") // ‘foo’ {1, bar: ‘baz’, mod: 3}

    runScript(" foo 1 bar: baz fub 4 mod: 3 ") // ‘foo’ {1, bar: ‘baz’ {‘fub’ {4}}, mod: 3}

    runScript(" foo -1 bar: 2 ") // TO DO: still breaks (need to work on ambiguous operator)

    runScript(" if -1 * - 2 + ---3 = -4 then -5 + -6 else -7 ÷ -8 ") // ‘else’ {‘if’ {‘=’ {‘+’ {‘*’ {-1, -2}, -3}, -4}, ‘+’ {-5, -6}}, ‘/’ {-7, -8}}

    runScript("To say_hello {to: name} run write “Hello, ” & name & “!”. Say_hello to: “World”.") // TO DO: buggy parse omits `write “Hello, ” &`

    runScript("tell app “com.apple.TextEdit” to get documents at 2 thru -1")

    runScript("if (a) + b = c then get documents at 2 thru -1 ") // TO DO: still got problems with disambiguating `+`/`-` when it appears at start of direct argument

    runScript("  documents at 2 thru -3  ") // ‘at’ {‘documents’, ‘thru’ {2, -3}}

    runScript("  get documents at 2 thru 3  ") // ‘get’ {‘at’ {‘documents’, ‘thru’ {2, 3}}}

    runScript("  get documents at 2 thru -3  ") // this explodes as it's treating `-` as infix even though it must be prefix (since it follows infix operator)

    runScript("bim {foo: bar} ")

    runScript(" -1 else - 2 + 3 ")

    runScript(" 1 + 2 * - 3 ") // note: `-` must match as unary operator; `*` match as binary operator even though its right operand is only partially matched as `-`, i.e. it *could* be the start of an EXPR [but isn't yet known for sure]

    runScript(" if 1 * 2 - 3 = 4 then 5 ")

    runScript(" if 1 + 2 = 3 then 4 ")

    runScript(" a -1 ")

    runScript(" nothing ")

    runScript(" 1 + -2 ")

    runScript(" foo 1 bar: 2 baz: 3 ")

    runScript(" foo 1 + a bar: 3 ")

    runScript(" (8,9) ")

    runScript(" f x - 1") // this should parse as `-{f{x},1}`

    runScript(" f a: b - 1") //

    runScript(" f a: b of c - 1 ") // `of` needs to bind more tightly than arg label, i.e. `-{f{a:of{b,c}},1}`

    runScript(" a b c ") // this throws parsing error as inner commands can't be LP, but could do with better error message (currently 'expected label in ‘a’ command but found <.unquotedName("c") _"c"_>'); Q. how to suggest corrections? e.g. `a {b {c}}`, `a {b, c}`, `a {b, c: …}`
    
        // TO DO: "a + 1" mis-parses as `a {+1}`
    
        // TO DO: name arg is currently limited to AsLiteralName, but also needs to accept a reference

    runScript("set a of b to: 3")

    runScript("set n to app “com.apple.TextEdit”, tell n to get document 1") // TO DO: parser prematurely exits after the 1st `n`; how to match `to` as stop word here? might pass closure thru parser that performs all stop-word/boundary checks; alternatively, leave it for now and address in table-driven parser

    runScript("tell app “com.apple.Finder” to get document_files from 2 thru -1 of home")

    
        // TO DO: need decision on whether or not to overload `set` command to perform local assignment; within a `tell app…` block it current sends an AE (or tries to); one option is to define `me`/`my` atom for use in references, e.g.:
        //
        //  tell app “com.apple.TextEdit” to set my foo to: get document 1"
        //
        // we could describe the problem in terms of dispatch-on-first-argument-type, e.g. when first operand is a reference to a target object (e.g. `set end of documents to…` invokes application-defined `set` handler), vs a reference to a local slot (`set end of bars to…` invokes stdlib-defined `set` handler); however, we should also consider that `get`/`set` remote application state is clean simple unambiguous behavior, whereas overloading `set` but not `get` is inconsistent while overloading `get` is redundant (assuming local refs, unlike remote queries, self-resolve on eval)
        //
        // on reflection, looks like `set` should be app-only, or reference-only [if get/set apply to local refs, that is arguably more consistent with remote messaging than with local name binding]
        //
        // Q. if local queries require explicit `get` to resolve, e.g. `get B of A`, then how should dot-form/superglobals behave, e.g. `@A.B`/`A.B`/`B of @A`?

    runScript("Set Bob to: “Tim”. Write Bob.")

    runScript("foo 1 as (editable integer)") // TO DO: possible to treat `editable integer` as non-nested command, given it appears as an operand to `as` operator?

    runScript("x: 1")

    runScript("x: 1 as editable integer, y: 2")
    
        // colon pair for assignment is simplest [within an expr sequence]; is it sufficient for it to implement eval? // one caution: `foo: bar, baz` will bind result of baz, not bar; use period/linebreak to terminate colon's right operand
    
        // TO DO: this still leaves question on how to assign when a reference, not identifier, is given; e.g. `set end of bars to…`

    runScript("tell app “com.apple.TextEdit” to get text of documents")

    runScript("write true")

    runScript("if 1 + 2 = 3, 4 then 6, 8, 9.") // this (correctly) reports parse error on unexpected `then` keyword

    runScript("if 1 + 2 = 3, 4, 5, 6.") // this does parse successfully (parser treats first comma as equivalent to `then` separator); PP should probably convert to canonical form

    runScript("if (1 + 2 = 5, true) then write “ok”.") // this also parses successfully; Q. should parser/pp have the smarts to flag the parensed sequence as "suspect", given that the `1+2=5` is effectively a no-op (bear in mind it's also a way to accidentally/deliberately hide effectful operations)

    
    // TO DO: changes to colon rules mean that `{i}:bar` is no longer legal structure; the [nested/parent?] record subsequently fails to reduce and parser aborts complaining about unreduced the .endToken
 //   runScript("map {foo, using: {i}: bar}; fub") // this works and is unambiguous
  //  runScript("foo; map using: {i}: bar; fub") // this works [as long as proc has explicit label], but the right-side of colon pair captures `bar; fub` whereas the user may reasonably expect both colons to be top-level, as they are in `foo; bar; baz` (i.e. semicolons should probably terminate nested sentences)

    
    //runScript("foo; map {i}: bar; fub") // TO DO: reject this syntax as ambiguous? it parses as `((‘map’ {‘foo’, ‘i’}: ‘fub’ {‘bar’}))`, which isn't what's intended (left side of colon pair within a block expr should always be a literal name; thus any form of `cmd, name{…}:…` or `cmd; name:…` should be rejected due to existence of argument record)

    //runScript("foo; map ({i}: bar); fub") // this works: `(‘fub’ {‘map’ {‘foo’, ({‘i’}: ‘bar’)}})`

    //runScript("foo; map {{i}: bar}; fub") // TO DO: this needs to provide better error description (the procedure Pair needs to be parensed to distinguish it from a record field Pair [albeit one with an invalid label type])

    //runScript("foo; map {({i}: bar)}; fub") // TO DO: this fails due to parser bug (probably readRecord being unaware of parens)

    runScript("if t1 then if t2 then a1 else a2 else a3") // TO DO: this doesn't parse correctly

}
    
  
func runScript(_ script: String) {

    print("PARSE: \(script.debugDescription)")

    let doc = EditableScript(script) { NumericReader(operatorReader(NameReader($0))) }
    
    /*
    var ts: BlockReader = QuoteReader(doc.tokenStream)
    while ts.token.form != .endOfScript { print(ts.token); ts = ts.next() }
    print()
    */
    
    let p = Parser(tokenStream: QuoteReader(doc.tokenStream), operatorRegistry: operatorRegistry)
    do {
        let ast = try p.parseScript()
        //print("PARSED:", ast)
        //print("RESULT:", try ast.eval(in: env, as: asAnything))
        let _ = ast
    } catch {
        print(error)
    }
    //print(script)
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
