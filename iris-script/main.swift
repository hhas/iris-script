//
//  main.swift

// iris-script recapitulates sylvia-lang, which recapitulates entoli

// syntactically, the final language should be primarily word-based with the minimum punctuation necessary to ensure unambiguous parsing (for discussion purposes, assume a word is any single word, or multiple words separated by underscores, or operator symbol)

// “everything is a command”; there is no distinction between a “variable” and a command with zero arguments. Conceptually, `set foo to 3` is storing the value `3` in the environment's 'foo' slot as if it was simple closure: { ()->Value in return value } (where 'value' is 3). Thus `foo` will always operate as a command; similar to Ruby, there is no distinction between `foo` (name only) or `foo {}` (name + empty arguments record), as there is in Swift/Python/JavaScript/etc.

// all commands behave as right-associative prefix 'operators'; where the right operand may be omitted (in which case it is null). For practical purposes, the operand when given is always treated as a record of zero or more fields, where each field has a value and is optionally labeled. (A record is effectively a tuple/struct hybrid.)

// Q. to what extent could optimization be achieved by eval-ing script against meta-libraries? (i.e. libraries that define the same set of handler interfaces as standard libraries, but whose handlers perform transformations on the initial AST in order to yield a more efficient equivalent)

import Foundation


// Q. what about dead code detection? (e.g. given the script `1, 2, 3.`, `1` and `2` [being side-effectless] are no-ops, while `3` is only relevant if the evaluator is connected to an output console); flagging 'useless' or 'suspect' code may be most useful in parenthesized groups, e.g. `(1,2+3)` will discard the 1 and return 5, but `(foo,2+3)` will return 5 while also performing a potentially effectful `foo` command; being parenthesized, that expr could be buried deep in a much larger expr (while the same effect can be achieved if a `foo` handler is defined that returns its input parameter as output while also performing its side-effect, that requires an explicit definition of `foo` whereas a parenthesized expr sequence works with any existing handler)


var script = """

123, 4.56, 789.
-1.2345e7
[4,55,6]


to wibble {message, times: n as integer} returning nothing do
    repeat n with: frogblast_the_ventcore message
done

«To call `wibble` using canonical[?] ‘low-punctuation’ command syntax:»

wibble “hello” times: 5

«The above command can also be written as:»

wibble message: “hello” times: 5
wibble {message: “hello”, times: 5}
wibble {“hello”, 5}

"""


// TO DO: how would lexer adapter for multiline strings/annotations work? (upon detecting opening quote, it would return a lexer (or lexer adapter?) that knows how to find the end of that quote [Q. what token would it return in meantime?]) challenge is how to carry that reader forward from end of one line to process next, and finally swap out the quote reader for the standard token reader when done (TBH, it may not be worth the effort when parsing for editing; while slower, having everything tokenized regardless of whether it's code or quoted text gives the auto3cs lots more data to analyze, particularly when best-guessing where missing quotes/closing braces should appear)


script = "‘foo’ -1*-2+a3" // note that `a3` is two tokens: <.letters "a"><.value(3) "3">; this'll require reducing to something like `.value(Command("a3"))` or `.identifier("a3")` [or should that be .commandName("a3")? this reduction should probably be performed as CoreLexer]

//script = " “blah blah”"

//script = "3𝓍²＋5𝓎－1" // this requires some custom lexing


let operatorRegistry = OperatorRegistry()
operatorRegistry.add(OperatorDefinition("true", .atom, precedence: 0))
operatorRegistry.add(OperatorDefinition("false", .atom, precedence: 0))
operatorRegistry.add(OperatorDefinition("\u{FF0B}", .prefix, precedence: 800, aliases: ["+"])) // full-width plus
operatorRegistry.add(OperatorDefinition("\u{2212}", .prefix, precedence: 800, aliases: ["-", "\u{FF0D}", "\u{FE63}"])) // full-width minus
operatorRegistry.add(OperatorDefinition("×", .infix, precedence: 600, aliases: ["*"]))
operatorRegistry.add(OperatorDefinition("÷", .infix, precedence: 600, aliases: ["/"]))
operatorRegistry.add(OperatorDefinition("\u{FF0B}", .infix, precedence: 590, aliases: ["+"])) // full-width plus
operatorRegistry.add(OperatorDefinition("\u{2212}", .infix, precedence: 590, aliases: ["-", "\u{FF0D}", "\u{FE63}"])) // full-width minus
operatorRegistry.add(OperatorDefinition("of", .infix, precedence: 900))

//operatorRegistry.add(OperatorDefinition("at", .infix, precedence: 910)) // by index/range
operatorRegistry.add(OperatorDefinition("thru", .infix, precedence: 920)) // range clause
operatorRegistry.add(OperatorDefinition("named", .infix, precedence: 910)) // by name
operatorRegistry.add(OperatorDefinition("id", .infix, precedence: 910)) // by ID // TO DO: what about `id` properties? either we define an "id" .atom, or we need some way to tell parser that only infix `id` should be treated as an operator and other forms should be treated as ordinary [command] name
operatorRegistry.add(OperatorDefinition("where", .infix, precedence: 910, aliases: ["whose"])) // by test
operatorRegistry.add(OperatorDefinition("first", .prefix, precedence: 930)) // absolute ordinal
operatorRegistry.add(OperatorDefinition("middle", .prefix, precedence: 930))
operatorRegistry.add(OperatorDefinition("last", .prefix, precedence: 930))
operatorRegistry.add(OperatorDefinition("any", .prefix, precedence: 930))
operatorRegistry.add(OperatorDefinition("every", .prefix, precedence: 930))
operatorRegistry.add(OperatorDefinition("before", .infix, precedence: 930)) // relative
operatorRegistry.add(OperatorDefinition("after", .infix, precedence: 930))
operatorRegistry.add(OperatorDefinition("before", .prefix, precedence: 930)) // insertion
operatorRegistry.add(OperatorDefinition("after", .prefix, precedence: 930))
operatorRegistry.add(OperatorDefinition("beginning", .atom, precedence: 930))
operatorRegistry.add(OperatorDefinition("end", .atom, precedence: 930))
operatorRegistry.add(OperatorDefinition("tell", .prefix, precedence: 100))
 
let operatorReader = newOperatorReader(for: operatorRegistry)

//print(operatorRegistry)

//let doc = EditableScript(script)
//let doc = EditableScript(script, {NumericReader(operatorReader(NameReader($0)))})



func test(_ operatorRegistry: OperatorRegistry) {
    
    // TO DO: need underscore reader
    
    let script:String
    //script = "foo [1, 2,\n3\n [:]] arg: “yes” um: false."
    //script = "1 + 2 / 4.6" // TO DO: operator parsing is still buggy
    //script = "foo bar baz: fub zim: bip {dob} nag: 0"
    
    // TO DO: this is problematic as it's not clear if colon pair belongs to app{} or tell{}; alternative is not to use colon pairs, and either use `tell EXPR to EXPR`, `if EXPR then EXPR`, `while EXPR repeat EXPR`, etc operators, or leave them as commands and rely on labeled args
    
    
    
    
    // TO DO: think nested lp commands still need to allow unlabeled direct arg
    
    
    // technically `app "TextEdit"` would be `@com.apple.TextEdit` (or however we mount 'application' resources in the superglobal namespace; we might need an extra suffix, e.g. '.file'/'.app'/'.web', or coercion, e.g. `@com.example.foo as file/app/webservice`, to specify the exact service; there's also the question of how to map different namespaces onto the same superglobal root, e.g. UTI vs FS vs WWW; though this is less of an issue if we crosscut resource location with content type negotiation)
//    script = "tell app “TextEdit”: make new: #document at: end of documents with_properties: {name: “Test”, text: “blah”}"
    script = "make new: #document at: end of documents with_properties: {name: “Test”, text: “blah”}"
    
    let doc = EditableScript(script) { NumericReader(operatorReader(NameReader($0))) }
    
    /*
    var ts: BlockReader = QuoteReader(doc.tokenStream)
    while ts.token.form != .endOfScript {
        print(ts.token)
        ts = ts.next()
    }
    print()
    */
    
    let p = Parser(tokenStream: QuoteReader(doc.tokenStream), operatorRegistry: operatorRegistry)
    do {
        let script = try p.parseScript()
        print(script)
    } catch {
        print(error)
    }
    // TO DO: if startMatch/continueMatch are responsible for shifting token to stack, they need to return a Bool indicating when they've done so, so that calling code knows to advance to next token
    
}




test(operatorRegistry)


//while let current = tokenStream { print(current.location, current.token); tokenStream = current.next() }



/*
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
let e = Environment()

stdlib_loadHandlers(into: e)


try e.define(
    HandlerInterface(name: "foo", parameters: [("number", nullSymbol, AsEditable(asNumber))], result: asNothing),
    Block([Command("show", [(nil, Command("bar"))])]))

let v = Text("313.0")



//let _ = try Command("foo", [(nil, v)]).eval(in: e, as: asAnything)

do {

    try e.set("bar", to: EditableValue(123, as: asNumber))

    let r = try Command("foo", [(nil, Command("bar"))]).eval(in: e, as: asAnything)

    print(r)
    
    let v2 = e.get("bar") as! EditableValue

    print("a=", v2)

    try v2.set(nullSymbol, to: 6)

    print("b=", v2)
    
    try e.set(Symbol("bar"), to: 7)
    
    print("b2=", v2)
    
    // TO DO: does 'editable parameter' need to be different to 'editable value'? i.e. AsEditableValue evals the input value and outputs it in a mutable box; whereas AsEditableParameter requires its input to be an editable value, evals the value using the intersection of its original and parameter types, stores the result back in the box and adds that box to the handler scope (Q. does this mean the editable box's constrained type also needs updated to the intersection? Remember, all changes to that box made by/within the handler are shared with the calling scope [c.f. pass-by-reference]).

    print("c=", try v2.eval(in: e, as: AsList(asString)))

    print("d=", try v2.eval(in: e, as: AsEditable(asString))) // (bear in mind asString only coerces to scalar; it won't convert Number to String so the number will still appear unquoted, which is fine)

} catch {
    print(error)
}


*/

/*
struct AddHandler: Handler { // 5x faster than standard implementation (which is to say, still dog-slow)
    
    var isStaticBindable: Bool { return true }
    
    let interface = HandlerInterface(name: "add", parameters: [
        (label: leftParameterLabel, nullSymbol, coercion: asNumber),
        (label: rightParameterLabel, nullSymbol, coercion: asNumber)],
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
try e.set("add", to: AddHandler())



do {
    print(try v.eval(in: e, as: asInt))
    
    print(try v.eval(in: e, as: asString))
    
    do {
        let code = Command("+", [(nil, 4), (nil, 8.5)])
        let d = Date()
        for _ in 0..<100000 {
            let _ = (try code.eval(in: e, as: asNumber))
        }
        print("a =", Date().timeIntervalSince(d))
    }
    do {
        let code = Command("add", [(nil, 4), (nil, 8.5)])
        let d = Date()
        for _ in 0..<100000 {
            let _ = (try code.eval(in: e, as: asNumber))
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
    
    print(try Command("+", [(nil, 4), (nil, 8.5)]).eval(in: e, as: asNumber))
    
    
    print(try Command("&", [(nil, Text("foo")), (nil, Text("bar"))]).eval(in: e, as: asString))
    
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
