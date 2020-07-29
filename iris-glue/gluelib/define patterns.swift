//
//  define patterns.swift
//  iris-glue
//

import Foundation
import iris



    
func keyword(for names: [String]) -> Keyword {
    return Keyword(Symbol(names[0]), aliases: names.dropFirst().map{Symbol($0)})
}


func newSequencePattern(for patterns: [PatternValue]) -> PatternValue {
    return PatternValue(Pattern.sequence(patterns.map{$0.data}))
}

func newAnyOfPattern(for patterns: [PatternValue]) -> PatternValue {
    return PatternValue(Pattern.anyOf(patterns.map{$0.data}))
}

func newKeywordPattern(for names: [String]) -> PatternValue {
    return PatternValue(.keyword(keyword(for: names)))
}

func newExpressionPattern(binding: String?, handlerEnv: Scope) -> PatternValue {
    if let binding = binding {
        let interface = (handlerEnv.get(currentHandlerInterfaceKey) as! OpaqueHandlerInterface).data!
        guard let label = interface.labelForBinding(Symbol(binding)) else {
            fatalError("TODO: Can’t find argument label for \(binding) operand in \(handlerEnv)")
        }
        return PatternValue(.expressionLabeled(label))
    } else {
        return PatternValue(.expression)
    }
}

func newOptionalPattern(pattern: PatternValue) -> PatternValue {
    return PatternValue(.optional(pattern.data))
}

func newZeroOrMorePattern(pattern: PatternValue) -> PatternValue {
    return PatternValue(.zeroOrMore(pattern.data))
}

func newOneOrMorePattern(pattern: PatternValue) -> PatternValue {
    return PatternValue(.oneOrMore(pattern.data))
}

func newAtomPattern(named names: [String]) -> PatternValue {
    return PatternValue(.keyword(keyword(for: names)))
}

func newPrefixPattern(named names: [String]) -> PatternValue {
    return PatternValue([.keyword(keyword(for: names)), .expression])
}

func newInfixPattern(named names: [String]) -> PatternValue {
    return PatternValue([.expression, .keyword(keyword(for: names)), .expression])
}

func newPostfixPattern(named names: [String]) -> PatternValue {
    return PatternValue([.expression, .keyword(keyword(for: names))])
}



// sequence {…}
private let type_sequence = (
name: Symbol("sequence"),
    param_0: (Symbol("patterns"), Symbol("patterns"), AsArray(asPatternValue)), // TO DO: min:1
    result: asPatternValue
)
private let interface_sequence = HandlerInterface(
    name: type_sequence.name,
    parameters: [
        nativeParameter(type_sequence.param_0),
    ],
    result: type_sequence.result.nativeCoercion
)
private func procedure_sequence(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_sequence.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newSequencePattern(
        for: arg_0
    )
    return type_sequence.result.wrap(result, in: handlerEnv)
}

// any {…}
private let type_any = (
    name: Symbol("any"),
    param_0: (Symbol("patterns"), Symbol("patterns"), AsArray(asPatternValue)), // TO DO: min:1
    result: asPatternValue
)
private let interface_any = HandlerInterface(
    name: type_any.name,
    parameters: [
        nativeParameter(type_any.param_0),
    ],
    result: type_any.result.nativeCoercion
)
private func procedure_any(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_any.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newAnyOfPattern(
        for: arg_0
    )
    return type_any.result.wrap(result, in: handlerEnv)
}

// keyword {…}
private let type_keyword = (
    name: Symbol("keyword"),
    param_0: (Symbol("named"), Symbol("names"), AsArray(asString)), // TO DO: min:1
    result: asPatternValue
)
private let interface_keyword = HandlerInterface(
    name: type_keyword.name,
    parameters: [
        nativeParameter(type_keyword.param_0),
    ],
    result: type_keyword.result.nativeCoercion
)
private func procedure_keyword(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_keyword.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newKeywordPattern(
        for: arg_0
    )
    return type_keyword.result.wrap(result, in: handlerEnv)
}

// expr {…}
private let type_expression = (
    name: Symbol("expression"),
    param_0: (Symbol("binding"), Symbol("binding"), AsSwiftOptional(asString)),
    result: asPatternValue
)
private let interface_expression = HandlerInterface(
    name: type_expression.name,
    parameters: [
        nativeParameter(type_expression.param_0),
    ],
    result: type_expression.result.nativeCoercion
)
private func procedure_expression(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_expression.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newExpressionPattern(
        binding: arg_0,
        handlerEnv: handlerEnv
    )
    return type_expression.result.wrap(result, in: handlerEnv)
}

// optional {…}
private let type_optional = (
    name: Symbol("is_optional"), // TO DO: there are problems with overriding existing `optional` handler as it also has operator syntax that for some reason refuses to parse; look into this later; for now, workaround by renaming the Pattern.optional(…) constructor so it doesn't class
    param_0: (Symbol("pattern"), Symbol("pattern"), asPatternValue),
    result: asPatternValue
)
private let interface_optional = HandlerInterface(
    name: type_optional.name,
    parameters: [
        nativeParameter(type_optional.param_0),
    ],
    result: type_optional.result.nativeCoercion
)
private func procedure_optional(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_optional.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newOptionalPattern(
        pattern: arg_0
    )
    return type_optional.result.wrap(result, in: handlerEnv)
}

// zero_or_more {…}
private let type_zero_or_more = (
    name: Symbol("zero_or_more"),
    param_0: (Symbol("pattern"), Symbol("pattern"), asPatternValue),
    result: asPatternValue
)
private let interface_zero_or_more = HandlerInterface(
    name: type_zero_or_more.name,
    parameters: [
        nativeParameter(type_zero_or_more.param_0),
    ],
    result: type_zero_or_more.result.nativeCoercion
)
private func procedure_zero_or_more(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_zero_or_more.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newZeroOrMorePattern(
        pattern: arg_0
    )
    return type_zero_or_more.result.wrap(result, in: handlerEnv)
}

// one_or_more {…}
private let type_one_or_more = (
    name: Symbol("one_or_more"),
    param_0: (Symbol("pattern"), Symbol("pattern"), asPatternValue),
    result: asPatternValue
)
private let interface_one_or_more = HandlerInterface(
    name: type_one_or_more.name,
    parameters: [
        nativeParameter(type_one_or_more.param_0),
    ],
    result: type_one_or_more.result.nativeCoercion
)
private func procedure_one_or_more(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_one_or_more.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newOneOrMorePattern(
        pattern: arg_0
    )
    return type_one_or_more.result.wrap(result, in: handlerEnv)
}



// atom {…}
private let type_atom = (
    name: Symbol("atom"),
    param_0: (Symbol("named"), Symbol("names"), AsArray(asString)),
    result: asPatternValue
)
private let interface_atom = HandlerInterface(
    name: type_atom.name,
    parameters: [
        nativeParameter(type_atom.param_0),
    ],
    result: type_atom.result.nativeCoercion
)
private func procedure_atom(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_atom.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newAtomPattern(
        named: arg_0
    )
    return type_atom.result.wrap(result, in: handlerEnv)
}

// prefix {…}
private let type_prefix = (
    name: Symbol("prefix"),
    param_0: (Symbol("named"), Symbol("names"), AsArray(asString)),
    result: asPatternValue
)
private let interface_prefix = HandlerInterface(
    name: type_prefix.name,
    parameters: [
        nativeParameter(type_prefix.param_0),
    ],
    result: type_prefix.result.nativeCoercion
)
private func procedure_prefix(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_prefix.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newPrefixPattern(
        named: arg_0
    )
    return type_prefix.result.wrap(result, in: handlerEnv)
}

// infix {…}
private let type_infix = (
    name: Symbol("infix"),
    param_0: (Symbol("named"), Symbol("names"), AsArray(asString)),
    result: asPatternValue
)
private let interface_infix = HandlerInterface(
    name: type_infix.name,
    parameters: [
        nativeParameter(type_infix.param_0),
    ],
    result: type_infix.result.nativeCoercion
)
private func procedure_infix(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_infix.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newInfixPattern(
        named: arg_0
    )
    return type_infix.result.wrap(result, in: handlerEnv)
}

// postfix {…}
private let type_postfix = (
    name: Symbol("postfix"),
    param_0: (Symbol("named"), Symbol("names"), AsArray(asString)),
    result: asPatternValue
)
private let interface_postfix = HandlerInterface(
    name: type_postfix.name,
    parameters: [
        nativeParameter(type_postfix.param_0),
    ],
    result: type_postfix.result.nativeCoercion
)
private func procedure_postfix(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_postfix.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newPostfixPattern(
        named: arg_0
    )
    return type_postfix.result.wrap(result, in: handlerEnv)
}




class PatternDialect: Scope {

    private let parent: Scope
    private var frame = [Symbol: Value]()
    
    init(parent: Scope) {
        self.parent = parent
        for (interface, action) in [
            // primitive pattern constructors
            (interface_sequence, procedure_sequence),
            (interface_any, procedure_any),
            (interface_keyword, procedure_keyword),
            (interface_expression, procedure_expression),
            (interface_optional, procedure_optional),
            (interface_zero_or_more, procedure_zero_or_more),
            (interface_one_or_more, procedure_one_or_more),
            // convenience constructors for common operator forms
            (interface_atom, procedure_atom),
            (interface_prefix, procedure_prefix),
            (interface_infix, procedure_infix),
            (interface_postfix, procedure_postfix)] {
                self.frame[interface.name] = PrimitiveHandler(interface: interface, action: action, in: self)
        }
    }
    
    func get(_ name: Symbol) -> Value? {
        // print("opt", name, self.frame[name] as Any)
        return self.frame[name] ?? self.parent.get(name)
    }
    
    func subscope() -> Scope {
        return self
    }
}

