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

// TO DO: custom reducefunc for `as` operator could treat RH list/record literal as visual shorthand for `list{of:}` and `record{…}`, and convert to corresponding commands (note that this shorthand wouldn't be available when written as `‘as’{…}` command, unless we want to perform extra run-time tests)


// caution: skip functions step over specific tokens if found; they do not check if tokens exist (pattern matchers are responsible for checking punctuation)

func skipSeparator(_ stack: Parser.Stack, _ i: inout Int) {
    if case .separator(_) = stack[i].reduction { i += 1 }
}
func skipLineBreaks(_ stack: Parser.Stack, _ i: inout Int) {
    while case .lineBreak = stack[i].reduction { i += 1 }
}

extension Array where Element == Parser.StackItem {

    func name(at i: Int) -> Symbol {
        switch self[i].reduction {
        case .quotedName(let n), .unquotedName(let n): return n
        default: fatalError("Bad name") // should never happen
        }
    }
    func label(at i: Int) -> Symbol {
        guard case .label(let name) = self[i].reduction else { fatalError("Bad label") }
        return name
    }
    func value(at i: Int) -> Value {
        guard case .value(let expr) = self[i].reduction else { fatalError("Bad reduction; expected token \(i) to be Value but found unreduced \(self[i]).") }
        return expr
    }
        
}

// custom reducers for unary `+`/`-` optimize away command if operand is literal number, e.g. `-5.5`

func reducePositiveOperator(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value {
    assert(end == start + 2)
    let expr = stack.value(at: end - 1)
    return expr is NumericValue ? expr : Command(definition, right: expr)
}

func reduceNegativeOperator(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value {
    assert(end == start + 2)
    let expr = stack.value(at: end - 1)
    if let n = expr as? NumericValue {
        switch n { // TO DO: bit clumsy
        case let n as Int:    return -n // TO DO: doesn't handle edge case where n is Int.min
        case let n as Double: return -n
        case let n as Number: if let n = try? -n { return n }
        default: ()
        }
    }
    return Command(definition, right: expr)
}


// standard operator reduce funcs

func reducePrefixOperator(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value {
    assert(end == start + 2)
    return Command(definition, right: stack.value(at: end - 1))
}

func reduceInfixOperator(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value { // TO DO: need to pass operator definition? or can we pick up from stack? (problem is when two matchers complete on same frame, but again that's an SR conflict problem which parser needs to solve in order to decide which reduce func to call); if we pass Parser, could set var on Parser to hold the opdef for the duration
    assert(end == start + 3)
    return Command(definition, left: stack.value(at: start), right: stack.value(at: end - 1))
}

func reducePostfixOperator(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value {
    assert(end == start + 2)
    return Command(definition, left: stack.value(at: end - 1))
}

// TO DO: optimize away commands in favor of returning Symbol directly (caveat: safest way to do that is by getting symbols from populated env, but that'd require libraries to be loaded first)

func reduceAtomOperator(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value {
    assert(end == start + 1) // TO DO: check this
    return Command(definition)
}

func reducePrefixOperatorWithConjunction(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value {
    assert(end == start + 4) // TO DO: check this
    return Command(definition, left: stack.value(at: start + 1), right: stack.value(at: end - 1)) // TO DO: this uses convenience initializer
}

func reducePrefixOperatorWithSuffix(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value {
    // TO DO: this is typically keyword-based block (`do…done`) and probably not much use for anything else, in which case custom reducer is more appropriate
    // TO DO: start and end are keywords; any number of exprs with delimiters (and optional LFs) inbetween
    throw NotYetImplementedError()
}

func reduceInfixOperatorWithConjunction(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value { // trinary operator (c.f. Swift's `…?…:…`)
    assert(end == start + 5)
    return Command(definition, left: stack.value(at: start),
                             middle: stack.value(at: start + 2),
                              right: stack.value(at: start + 4))
}

// TO DO: can we guarantee reduce always applies to end of stack (probably not, e.g. when stitching per-line)

// note: literal list/record/group reduce funcs will ignore a trailing comma after last item (c.f. Python lists),

func reduceOrderedListLiteral(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value {
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

func reduceKeyedListLiteral(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value {
    //show(stack: stack, from: index)
    // TO DO: how to preserve key order in literals?
    var items = [KeyedList.Key: Value]()
    var i = start + 1 // ignore `[`
    skipLineBreaks(stack, &i)
    while i < end - 1 { // ignore `]`
        let key = (stack.value(at: i) as! HashableValue).dictionaryKey
        i += 2 // step over key + colon
        skipLineBreaks(stack, &i)
        let value = stack.value(at: i)
        items[key] = value
        print(key, value)
        i += 1 // step over value
        skipSeparator(stack, &i)
        skipLineBreaks(stack, &i)
    }
    return KeyedList(items)
}

func reduceRecordLiteral(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value {
    var items = Record.Fields()
    var i = start + 1 // ignore `{`
    skipLineBreaks(stack, &i)
    while i < end - 1 { // ignore `}`
        let label: Symbol
        if case .label(let n) = stack[i].reduction {
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

func reduceGroupLiteral(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value { // `( LF* EXPR LF* )`
    var i = start + 1
    skipLineBreaks(stack, &i)
    let expr = stack.value(at: i)
    skipLineBreaks(stack, &i)
    return expr // TO DO: how to annotate expr with elective parens/LFs
}

func reduceParenthesizedBlockLiteral(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value {
    //show(stack, start, end)
    //print(stack[start..<end].map{$0.reduction})
    var items = [Value]()
    var i = start + 1 // ignore `(`
    skipLineBreaks(stack, &i)
    while i < stack.count - 1 { // ignore `)`
        //print(">>>", stack[i].reduction)
        items.append(stack.value(at: i))
        i += 1 // step over value
        skipSeparator(stack, &i)
        skipLineBreaks(stack, &i)
    }
    return Block(items) // TO DO: how to annotate block with separators+LFs

}

func reduceCommandLiteral(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value { // used to reduce nested commands (`NAME EXPR?`) which have optional direct argument only
    let name = stack.name(at: start)
    //print("reduceCommandLiteral:", name)
    //stack.show(start, end)
    //print()
    if start == end - 1 {
        return Command(name) // no argument
    } else if start == end - 2 {
        let expr = stack.value(at: start + 1)
        if let record = expr as? Record {
            return Command(name, record) // FP syntax
        } else {
            return Command(name, [(nullSymbol, expr)]) // direct param only
        }
    } else { // this should never happen
        fatalError("reduceCommandLiteral() does not support LP command syntax")
    }
}

/*
func reducePairLiteral(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value {
    print("REDUCE PAIR:")
    stack.show(start, end)
    //assert(start == end - 2) // this only holds if we disallow LFs after colon
    return Pair((stack.label(at: start), stack.value(at: end - 1)))
}*/


func reducePipeOperator(stack: Parser.Stack, definition: OperatorDefinition, start: Int, end: Int) throws -> Value { // pipe (";") is a special case as it transforms its two operands (of which the right-hand operand must be a command) such that `A;B{C,D};E` -> `E{B{A,C,D}}`
    //print("Reduce pipe")
    // TO DO: if RH operand is LP command that already has direct arg (e.g. `foo; bar 1 baz: 2`) return syntax error
    throw NotYetImplementedError()
}
