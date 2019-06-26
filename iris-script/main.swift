//
//  main.swift

import Foundation


let e = Environment()

try stdlib_loadHandlers(into: e)


try e.addNativeHandler(
    HandlerInterface(name: "foo", parameters: [("number", nullSymbol, AsEditable(asNumber))], result: asNothing),
    [Command("show", [(nil, Command("bar"))])])

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
    
    // TO DO: does 'editable parameter' need to be different to 'editable value'? i.e. AsEditableValue evals the input value and outputs it in a mutable box; whereas AsEditableParameter requires its input to be an editable value, evals the value using the intersection of its original and parameter types, stores the result back in the box and adds that box to the handler scope (Q. does this mean the editable box's constrained type also needs updated to the intersection? Remember, all changes to that box made by/within the handler are shared with the calling scope [c.f. pass-by-reference]).

    print("c=", try v2.eval(in: e, as: AsList(asString))) // this modifies the contents of `bar` slot, causing d= to fail, which is not right; eval should not write coerced value back, except when coercing an editable value passed as editable argument (equivalent to Swift's var+pass-by-reference semantics); even then, the coercion must be rejected if the editable value's constrained type doesn't allow it; only time a coercion should be applied like this is when evaling command argument to parameter type (`to foo {bar as editable list of text}…`)

    print("d=", try v2.eval(in: e, as: AsEditable(asString))) // bear in mind asString only coerces to scalar; it won't quote number

} catch {
    print(error)
}

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
    
    func swiftCall<T: BridgingCoercion>(with command: Command, in dynamicScope: Scope, as coercion: T) throws -> T.SwiftType {
        throw NotYetImplementedError()
    }
    
    //
    
    func eval(in scope: Scope, as coercion: Coercion) throws -> Value {
        return try coercion.coerce(value: self, in: scope)
    }
    
    func swiftEval<T: BridgingCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
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
