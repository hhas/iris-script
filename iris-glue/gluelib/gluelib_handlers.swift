//
//  gluelib_handlers.swift
//  iris-lang
//

// code generator

import Foundation
import iris


// TO DO: get rid of these
let leftOperand   = Symbol("left")
let middleOperand = Symbol("middle")
let rightOperand  = Symbol("right")



// define_handler (name, parameters, return_type, action, is_event_handler)
private let type_defineHandlerGlue_handler_commandEnv = (
    // TO DO: reduce `name+parameters+result` to single parameter of type asHandlerInterface?
    param_0: (Symbol("interface"), Symbol("interface"), asHandlerInterface),
    param_1: (Symbol("action"), Symbol("action"), asIs), // TO DO: Record
    result: asNothing
)
private let interface_defineHandlerGlue_handler_commandEnv = HandlerInterface(
    name: "to",
    parameters: [
        type_defineHandlerGlue_handler_commandEnv.param_0,
        type_defineHandlerGlue_handler_commandEnv.param_1,
        ],
    result: type_defineHandlerGlue_handler_commandEnv.result
)
private func procedure_defineHandlerGlue_handler_commandEnv(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_defineHandlerGlue_handler_commandEnv.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_defineHandlerGlue_handler_commandEnv.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    try defineHandlerGlue(
        interface: arg_0,
        attributes: arg_1,
        commandEnv: commandEnv,
        handlerEnv: handlerEnv
    )
    return nullValue
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
        type_sequence.param_0,
    ],
    result: type_sequence.result
)
private func procedure_sequence(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_sequence.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newSequencePattern(
        for: arg_0
    )
    return type_sequence.result.box(value: result, in: handlerEnv)
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
        type_any.param_0,
    ],
    result: type_any.result
)
private func procedure_any(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_any.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newAnyOfPattern(
        for: arg_0
    )
    return type_any.result.box(value: result, in: handlerEnv)
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
        type_keyword.param_0,
    ],
    result: type_keyword.result
)
private func procedure_keyword(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_keyword.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newKeywordPattern(
        for: arg_0
    )
    return type_keyword.result.box(value: result, in: handlerEnv)
}

// expr {…}
private let type_expr = (
    name: Symbol("EXPR"),
    param_0: (Symbol("named"), Symbol("names"), AsSwiftDefault(AsArray(asString), default: [])), // TO DO: min:1
    result: asPatternValue
)
private let interface_expr = HandlerInterface(
    name: type_expr.name,
    parameters: [
        type_expr.param_0,
    ],
    result: type_expr.result
)
private func procedure_expr(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_expr.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newExpressionPattern(
        named: arg_0
    )
    return type_expr.result.box(value: result, in: handlerEnv)
}

// optional {…}
private let type_optional = (
    name: Symbol("option"),
    param_0: (Symbol("pattern"), Symbol("pattern"), asPatternValue),
    result: asPatternValue
)
private let interface_optional = HandlerInterface(
    name: type_optional.name,
    parameters: [
        type_optional.param_0
    ],
    result: type_optional.result
)
private func procedure_optional(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_optional.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newOptionalPattern(
        pattern: arg_0
    )
    return type_optional.result.box(value: result, in: handlerEnv)
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
        type_zero_or_more.param_0
    ],
    result: type_zero_or_more.result
)
private func procedure_zero_or_more(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_zero_or_more.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newZeroOrMorePattern(
        pattern: arg_0
    )
    return type_zero_or_more.result.box(value: result, in: handlerEnv)
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
        type_one_or_more.param_0
    ],
    result: type_one_or_more.result
)
private func procedure_one_or_more(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_one_or_more.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newOneOrMorePattern(
        pattern: arg_0
    )
    return type_one_or_more.result.box(value: result, in: handlerEnv)
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
        type_atom.param_0
    ],
    result: type_atom.result
)
private func procedure_atom(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_atom.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newAtomPattern(
        named: arg_0
    )
    return type_atom.result.box(value: result, in: handlerEnv)
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
        type_prefix.param_0
    ],
    result: type_prefix.result
)
private func procedure_prefix(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_prefix.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newPrefixPattern(
        named: arg_0
    )
    return type_prefix.result.box(value: result, in: handlerEnv)
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
        type_infix.param_0
    ],
    result: type_infix.result
)
private func procedure_infix(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_infix.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newInfixPattern(
        named: arg_0
    )
    return type_infix.result.box(value: result, in: handlerEnv)
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
        type_postfix.param_0
    ],
    result: type_postfix.result
)
private func procedure_postfix(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_postfix.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = newPostfixPattern(
        named: arg_0
    )
    return type_postfix.result.box(value: result, in: handlerEnv)
}






func gluelib_loadHandlers(into env: Environment) {
    
    env.define(interface_defineHandlerGlue_handler_commandEnv, procedure_defineHandlerGlue_handler_commandEnv)

    env.define(interface_sequence, procedure_sequence)
    env.define(interface_any, procedure_any)
    env.define(interface_keyword, procedure_keyword)
    env.define(interface_expr, procedure_expr)
    env.define(interface_optional, procedure_optional)
    env.define(interface_zero_or_more, procedure_zero_or_more)
    env.define(interface_one_or_more, procedure_one_or_more)
    
    env.define(interface_atom, procedure_atom)
    env.define(interface_prefix, procedure_prefix)
    env.define(interface_infix, procedure_infix)
    env.define(interface_postfix, procedure_postfix)
    
}
