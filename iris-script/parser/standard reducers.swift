//
//  reduce funcs.swift
//  iris-script
//

import Foundation

// TO DO: these matchers assume leading/trailing/interstitial EXPRs have been non-partially-matched and reduced to .value(…); need to make sure that parser does perform final full match of reduced EXPRs to confirm, and that these reduction funcs are either not called or respond to unsuccessful reductions gracefully (e.g. `TokenStack.value(at:)` currently exits with fatalError exception upon encountering unreduced tokens)

// caution: endIndex is non-inclusive (i.e. use i<endIndex, stack[startIndex..<endIndex]) // TO DO: should endIndex be inclusive? (probably; easier when selecting first/last stack indices)


// TO DO: pass ArraySlice<StackItem> rather than full stack? this has advantage of raising out-of-bounds error if a reducefunc tries to access any elements except those it is responsible for reducing (caution: reducefuncs would still need to use original indexes to access elements as ArraySlice methods do not apply an offset to start of slice, so probably best to continue passing start+end indexes as parameters)


// TO DO: how to preserve user's line breaks? (and when should PP apply its own choice of linebreaking/indents?)

// TO DO: punctuation hooks should probably only be applied when reducing blocks/top-level exprs (currently they apply to any punctuation, including lists and records) (we would presumably need to pass Parser to reduce funcs, and since we'll need different parser classes for per-line vs whole-script it'll have to be ABC-/protocol-based, with a public API that presents uniform representation of stack[s])

// TO DO: would be better if parser managed stack's remove()/append() operations; currently, reduce funcs assume they are operating at end of stack, which should hold for whole script parsing but won't work when stitching lines where multiple passes may be needed to complete all matches (e.g. operators can't reduce until all of their operands are reduced)

// TO DO: how to trigger LH reduction on conjunctions/suffixes? e.g. `if 1 + 2 * 3 then action` needs to reduce the first expr upon reaching `then` keyword

// TO DO: custom reducefunc for `as` operator could treat RH list/record literal as visual shorthand for `list{of:}` and `record{…}`, and convert to corresponding commands (note that this shorthand wouldn't be available when written as `‘as’{…}` command, unless we want to perform extra run-time tests)


// supporting functions

// caution: skip functions step over specific tokens if found; they do not check if tokens exist (pattern matchers are responsible for checking punctuation)

func skipSeparator(_ stack: Parser.TokenStack, _ i: inout Int) {
    if i < stack.count, case .separator(_) = stack[i].form { i += 1 }
}
func skipLineBreaks(_ stack: Parser.TokenStack, _ i: inout Int) {
    while i < stack.count, case .lineBreak = stack[i].form { i += 1 }
}

extension Array where Element == Parser.TokenInfo {

    func label(at i: Int) -> Symbol {
        if case .label(let name) = self[i].form { return name }
        self.show()
        fatalError("Bad reduction; expected token \(i) to be .label but found: \(self[i])")
    }

    func value(at i: Int) -> Value {
     //   self.show()
        if case .value(let expr) = self[i].form { return expr }
        self.show()
        fatalError("Bad reduction; expected token \(i) to be .value but found unreduced: \(self[i])")
    }
        
}


// reducers for built-in patterns

// note: literal list/record/group reduce funcs will ignore a trailing comma after last item (c.f. Python lists),

func reductionForOrderedListLiteral(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value {
    //show(stack, start, end)
    var items = [Value]()
    var i = start + 1 // ignore `[`
    skipLineBreaks(stack, &i)
    while i < end - 1 { // ignore `]`
        items.append(stack.value(at: i))
        i += 1 // step over value
        skipSeparator(stack, &i)
        skipLineBreaks(stack, &i)
    }
    return OrderedList(items)
}

func reductionForKeyedListLiteral(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value {
    //show(stack: stack, from: index)
    // TO DO: how to preserve key order in literals?
    var i = start + 1 // ignore `[`
    if case .colon = stack[i].form { return KeyedList([:]) } // `[:]` denotes empty kv-list
    skipLineBreaks(stack, &i)
    var items = [KeyedList.Key: Value]()
    while i < end - 1 { // ignore `]`
        let key = (stack.value(at: i) as! HashableValue).dictionaryKey
        i += 2 // step over key + colon
        skipLineBreaks(stack, &i)
        let value = stack.value(at: i)
        items[key] = value
        i += 1 // step over value
        skipSeparator(stack, &i)
        skipLineBreaks(stack, &i)
    }
    return KeyedList(items)
}

func reductionForRecordLiteral(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value {
    var items = Record.Fields()
    var i = start + 1 // ignore `{`
    skipLineBreaks(stack, &i)
    while i < end - 1 { // ignore `}`
        let label: Symbol
        if case .label(let n) = stack[i].form {
            label = n
            i += 1 // step over label
            skipLineBreaks(stack, &i)
        } else { // unlabeled field
            label = nullSymbol
        }
        let value = stack.value(at: i)
        items.append((label, value))
        i += 1 // step over value
        skipSeparator(stack, &i)
        skipLineBreaks(stack, &i)
    }
    do {
        return try Record(items) // duplicate keys will return MalformedRecordError
    } catch {
        print("Can't parse record:", error)
        throw error
    }
}


func reductionForGroupLiteral(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value {
    //show(stack, start, end)
    //print("reductionForGroupLiteral:\n\t", match, "\n\t",stack[start..<end].map{$0.form})
    var items = [Value]()
    var i = start + 1 // ignore `(`
    skipLineBreaks(stack, &i)
    while i < stack.count - 1 { // ignore `)`
        //print(">>>", stack[i].form)
        items.append(stack.value(at: i))
        i += 1 // step over value
        skipSeparator(stack, &i)
        skipLineBreaks(stack, &i)
    }
    if items.count == 1 {
        return items[0] // TO DO: how to annotate expr with elective parens/LFs (PP should automatically parenthesize as precedence demands, but users may also parenthesize for readability or to flow expr onto another line); may be easiest to use Block to handle elective layout (and make Block, like Command, optionally annotatable with layout and other metadata)
    } else {
        return Block(items) // TO DO: how to annotate block with separators+LFs (i.e. user-defined layout)
    }

}

func reductionForCommandLiteral(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value { // used to reduce nested commands (`NAME EXPR?`) which have optional direct argument only
    guard let name = stack[start].form.asCommandName() else {
        if case .value(let v) = stack[start].form, v is Command { return v } // KLUDGE; TO DO: there is a problem with arg-less command that appears as left operand not being reduced prior to reducing the operation, e.g. `document` in `get document at 1`; there is a nasty hack in `[TokenInfo].value(at:)` to reduce it on the fly, but that causes further problems when reduceCommandLiteral is subsequently called on it; once commands are properly parsing we need to revisit the logic involved; see the reductionOrderFor switch in reductionForOperatorExpression(): there should be a .left reduction for the LH command
        fatalError("Bad name") // should never happen
    }
    //print("reduceCommandLiteral:", name)
    //stack.show(start, end)
    //print()
    switch end - start {
    case 1:
        return Command(name) // no argument
    case 2:
        let expr = stack.value(at: start + 1)
        if let record = expr as? Record {
            return Command(name, record) // FP syntax
        } else {
            return Command(name, [(nullSymbol, expr)]) // direct param only
        }
    default: // LP syntax
        var arguments = [Command.Argument]()
        var index = start + 1
        if case .value(let v) = stack[index].form {
            arguments.append((nullSymbol, v))
            index += 1
        }
        for i in Swift.stride(from: index, to: end, by: 2) {
            arguments.append((stack.label(at: i), stack.value(at: i + 1)))
        }
        return Command(name, arguments)
    }
}

func reductionForPipeOperator(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value { // pipe (";") is a special case as it transforms its two operands (of which the right-hand operand must be a command) such that `A;B{C,D};E` -> `E{B{A,C,D}}`
    print("Reduce pipe")
    assert(end >= start + 3)
    // typecheck RH is a Command here rather than in pattern so we can provide a descriptive error
    guard case .value(let directArgument) = stack[start].form,
        case .value(let v) = stack[end-1].form, let command = v as? Command else {
            print("Expected command after semicolon but found: .\(stack[end-1].form)")
        throw BadSyntax.missingExpression // TO DO: what error? (Q. should we reject non-commands in pattern matcher, or here?)
    }
    // TO DO: if RH operand is LP command that already has direct arg (e.g. `foo; bar 1 baz: 2`) return syntax error? (we'll presumably need PP annotation to determine that); alternative is to leave command with two unlabeled arguments and see if handler objects to that when mapping arguments to labeled parameters
    // TO DO: annotate command so PP formats as `b;a`
    return Command(command.name, [(nullSymbol, directArgument)] + command.arguments)
}


// standard operator reduce funcs

func reductionForPrefixOperator(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value {
    assert(end == start + 2)
    return Command(match.definition, right: stack.value(at: end - 1))
}

func reductionForInfixOperator(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value { // TO DO: need to pass operator match? or can we pick up from stack? (problem is when two matchers complete on same frame, but again that's an SR conflict problem which parser needs to solve in order to decide which reduce func to call); if we pass Parser, could set var on Parser to hold the opdef for the duration
    assert(end == start + 3)
    return Command(match.definition, left: stack.value(at: start), right: stack.value(at: end - 1))
}

func reductionForPostfixOperator(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value {
    assert(end == start + 2)
    return Command(match.definition, left: stack.value(at: end - 1))
}

func reductionForAtomOperator(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value {
    // TO DO: for operators such as `true`, `false`, `π`, etc, can/should we optimize away commands in favor of returning underlying Value directly? (caveat: safest way to do that is by getting symbols from populated env, but that'd require libraries to be loaded first)
    assert(end == start + 1) // TO DO: check this
    return Command(match.definition)
}

func reductionForPrefixOperatorWithConjunction(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value {
    assert(end == start + 4) // TO DO: check this
    return Command(match.definition, left: stack.value(at: start + 1), right: stack.value(at: end - 1)) // TO DO: this uses convenience initializer
}

// for now, we compromise on `if…then…else…`, defining it as one operator with two conjunctive clauses rather than two independent composable operators
func reductionForPrefixOperatorWithConjunctionAndAlternate(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value {
    // the alternate clause is optional, e.g. `if EXPR then EXPR ( else EXPR )?`
    assert(end == start + 4 || end == start + 6)
    let alternate = end == start + 6 ? stack.value(at: start + 5) : nullValue
    return Command(match.definition, left: stack.value(at: start + 1), middle: stack.value(at: start + 3), right: alternate)
}

func reductionForKeywordBlock(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value {
    // TO DO: this is default reducer for OperatorRegistry.prefix(_:suffix:) used to parse a keyword-based block of form `START_KEYWORD DELIMITER (EXPR DELIMITER*) STOP_KEYWORD` (e.g. `do…done`)
    assert(end >= start + 2)
    var items = [Value]()
    var i = start + 1 // ignore opening keyword (e.g. `do`)
    skipSeparator(stack, &i)
    skipLineBreaks(stack, &i)
    while i < end - 1 { // ignore closing keyword (e.g. `done`)
        items.append(stack.value(at: i))
        i += 1 // step over value
        skipSeparator(stack, &i)
        skipLineBreaks(stack, &i)
    }
    return Block(items, patternDefinition: match.definition)
}

func reductionForInfixOperatorWithConjunction(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value { // trinary operator (c.f. Swift's `…?…:…`)
    assert(end == start + 5)
    return Command(match.definition, left: stack.value(at: start),
                                       middle: stack.value(at: start + 2),
                                        right: stack.value(at: start + 4))
}



// custom reducers for unary `+`/`-`; these optimize away command if operand is literal number, e.g. `-5.5` ➞ .value(-5.5)

// TO DO: what if there is whitespace between the operator and number? should we consider that significant?

func reductionForPositiveOperator(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value {
    assert(end == start + 2)
    let expr = stack.value(at: end - 1)
    return expr is NumericValue ? expr : Command(match.definition, right: expr)
}

func reductionForNegativeOperator(stack: Parser.TokenStack, match: PatternMatch, start: Int, end: Int) throws -> Value {
    assert(end == start + 2)
    let expr = stack.value(at: end - 1)
    if let n = expr as? NumericValue {
        switch n { // TO DO: bit clumsy
        case let n as Int:    return n == Int.min ? -Double(n) : -n // Int.max < Int.min so `-Int.min` must return [lossy] Double
        case let n as Double: return -n // // check Double’s behavior at edges of expressible range (c.f. Int.min/.max)
        case let n as Number: if let n = try? -n { return n }
        default: ()
        }
    }
    return Command(match.definition, right: expr)
}


