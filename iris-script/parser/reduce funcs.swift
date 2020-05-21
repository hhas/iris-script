//
//  reduce funcs.swift
//  iris-script
//

import Foundation

// caution: endIndex is non-inclusive (i.e. use i<endIndex, stack[startIndex..<endIndex]) // TO DO: should endIndex be inclusive? (probably; easier when selecting first/last stack indices)


// TO DO: allow LF after colon in record/kv-list?

// TO DO: how to preserve user's line breaks? (and when should PP apply its own choice of linebreaking/indents?)

// TO DO: punctuation hooks should probably only be applied when reducing blocks/top-level exprs (currently they apply to any punctuation, including lists and records) (we would presumably need to pass Parser to reduce funcs, and since we'll need different parser classes for per-line vs whole-script it'll have to be ABC-/protocol-based, with a public API that presents uniform representation of stack[s])

// TO DO: would be better if parser managed stack's remove()/append() operations; currently, reduce funcs assume they are operating at end of stack, which should hold for whole script parsing but won't work when stitching lines where multiple passes may be needed to complete all matches (e.g. operators can't reduce until all of their operands are reduced)

// TO DO: how to trigger LH reduction on conjunctions/suffixes? e.g. `if 1 + 2 * 3 then action` needs to reduce the first expr upon reaching `then` keyword


func show(_ stack: Parser.Stack, _ start: Int, _ end: Int) {
    print()
    print("STACK DUMP [\(start)..<\(end)]:")
    for f in stack[start..<end] { print(" -", f.reduction, "\t\t", f.matches) }
    print()
}


// caution: skip functions step over specific tokens if found; they do not check if tokens exist (pattern matchers are responsible for checking punctuation)

func skipSeparator(_ stack: Parser.Stack, _ i: inout Int) {
    if case .separator(_) = stack[i].reduction { i += 1 }
}
func skipLineBreaks(_ stack: Parser.Stack, _ i: inout Int) {
    while case .lineBreak = stack[i].reduction { i += 1 }
}

extension Array where Element == Parser.StackItem {

    func expression(at i: Int) -> Value {
        guard case .value(let expr) = self[i].reduction else { fatalError("Bad reduction.") }
        return expr
    }
        
}

// custom reducers for unary `+`/`-` optimize away command if operand is literal number, e.g. `-5.5`

func reducePositiveOperator(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction {
    assert(end == start + 2)
    let expr = stack.expression(at: end - 1)
    return .value(expr is NumericValue ? expr : Command(definition, right: expr))
}

func reduceNegativeOperator(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction {
    assert(end == start + 2)
    let expr = stack.expression(at: end - 1)
    if let n = expr as? NumericValue {
        switch n { // TO DO: bit clumsy
        case let n as Int:    return .value(-n) // TO DO: doesn't handle edge case where n is Int.min
        case let n as Double: return .value(-n)
        case let n as Number: if let n = try? -n { return .value(n) }
        default: ()
        }
    }
    return .value(Command(definition, right: expr))
}


// standard operator reduce funcs

func reducePrefixOperator(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction {
    assert(end == start + 2)
    return .value(Command(definition, right: stack.expression(at: end - 1)))
}

func reduceInfixOperator(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction { // TO DO: need to pass operator definition? or can we pick up from stack? (problem is when two matchers complete on same frame, but again that's an SR conflict problem which parser needs to solve in order to decide which reduce func to call); if we pass Parser, could set var on Parser to hold the opdef for the duration
    assert(end == start + 3)
    return .value(Command(definition, left: stack.expression(at: start), right: stack.expression(at: end - 1)))
}

func reducePostfixOperator(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction {
    assert(end == start + 2)
    return .value(Command(definition, left: stack.expression(at: end - 1)))
}

// TO DO: optimize away commands in favor of returning Symbol directly (caveat: safest way to do that is by getting symbols from populated env, but that'd require libraries to be loaded first)

func reduceAtomOperator(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction {
    assert(end == start + 1)
    return .value(Command(definition))
}

func reducePrefixOperatorWithConjunction(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction {
    assert(end == start + 3)
    return .value(Command(definition, left: stack.expression(at: start), right: stack.expression(at: end - 1)))
}

func reducePrefixOperatorWithSuffix(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction {
    // TO DO: this is typically keyword-based block (`do…done`) and probably not much use for anything else, in which case custom reducer is more appropriate
    // TO DO: start and end are keywords; any number of exprs with delimiters (and optional LFs) inbetween
    return .error(NotYetImplementedError())
}

func reduceInfixOperatorWithConjunction(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction { // trinary operator (c.f. Swift's `…?…:…`)
    assert(end == start + 5)
    return .value(Command(definition, left: stack.expression(at: start),
                                    middle: stack.expression(at: start + 2),
                                     right: stack.expression(at: start + 4)))
}

// TO DO: can we guarantee reduce always applies to end of stack (probably not, e.g. when stitching per-line)

// note: these reduce funcs will ignore a trailing comma after last item (c.f. Python lists), although the literal patterns currently do not permit that

func reduceOrderedListLiteral(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction {
    //show(stack, start, end)
    var items = [Value]()
    var i = start + 1 // ignore `[`
    skipLineBreaks(stack, &i)
    while i < end - 1 { // ignore `]`
        guard case .value(let value) = stack[i].reduction else {
            fatalError("Bad Value") // should never happen
        }
        items.append(value)
        i += 1 // step over value
        skipSeparator(stack, &i)
        skipLineBreaks(stack, &i)
    }
    return Parser.Reduction(OrderedList(items))
}

func reduceKeyedListLiteral(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction {
    //show(stack: stack, from: index)
    // TO DO: how to preserve key order in literals?
    var items = [KeyedList.Key: Value]()
    var i = start + 1 // ignore `[`
    skipLineBreaks(stack, &i)
    while i < end - 1 { // ignore `]`
        guard case .value(let k) = stack[i].reduction, let key = (k as? HashableValue)?.dictionaryKey else {
            fatalError("Bad Key") // should never happen
        }
        i += 2 // step over key + colon
        skipLineBreaks(stack, &i)
        guard case .value(let value) = stack[i].reduction else {
            fatalError("Bad Value") // should never happen
        }
        items[key] = value
        print(key, value)
        i += 1 // step over value
        skipSeparator(stack, &i)
        skipLineBreaks(stack, &i)
    }
    return Parser.Reduction(KeyedList(items))
}

func reduceRecordLiteral(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction {
    var items = Record.Fields()
    var i = start + 1 // ignore `[`
    skipLineBreaks(stack, &i)
    while i < end - 1 { // ignore `]`
        // TO DO: support unlabeled fields
        let label: Symbol
        switch stack[i].reduction {
        case .quotedName(let n), .unquotedName(let n): label = Symbol(n)
        case .operatorName(let operatorClass): label = operatorClass.name
        default: fatalError("Bad label") // should never happen
        }
        i += 2 // step over label + colon
        skipLineBreaks(stack, &i)
        guard case .value(let value) = stack[i].reduction else {
            fatalError("Bad Value") // should never happen
        }
        items.append((label, value))
        i += 1 // step over value
        skipSeparator(stack, &i)
        skipLineBreaks(stack, &i)
    }
    do {
        let record = try Record(items) // duplicate keys will return MalformedRecordError
        return Parser.Reduction(record)
    } catch {
        print("Can't parse record:", error)
        return Parser.Reduction(error)
    }
}

func reduceGroupLiteral(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction { // `( LF* EXPR LF* )`
    var i = start + 1
    skipLineBreaks(stack, &i)
    guard case .value(let expr) = stack[i].reduction else { fatalError("Bad Expr") }
    return Parser.Reduction(expr) // TO DO: how to annotate expr with elective parens/LFs
}

func reduceParenthesizedBlockLiteral(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction {
    show(stack, start, end)
    print(stack[start..<end].map{$0.reduction})
    var items = [Value]()
    var i = start + 1 // ignore `(`
    skipLineBreaks(stack, &i)
    while i < stack.count - 1 { // ignore `)`
        print(">>>", stack[i].reduction)
        guard case .value(let expr) = stack[i].reduction else { fatalError("Bad Expr") }
        items.append(expr)
        i += 1 // step over value
        skipSeparator(stack, &i)
        skipLineBreaks(stack, &i)
    }
    return Parser.Reduction(Block(items)) // TO DO: how to annotate block with separators+LFs

}

func reduceCommandLiteral(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction {
    return .error(NotYetImplementedError())
}



func reducePipeOperator(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) -> Parser.Reduction { // pipe (";") is a special case as it transforms its two operands (of which the right-hand operand must be a command) such that `A;B{C,D};E` -> `E{B{A,C,D}}`
    print("Reduce pipe")
    return .error(NotYetImplementedError())
}
