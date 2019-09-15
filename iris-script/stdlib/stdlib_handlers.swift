//
//  stdlib_handlers.swift
//
//  Bridging code for primitive handlers. This file is auto-generated; do not edit directly.
//

import Foundation

// ^ {left, right}
private let type_exponent_left_right = (
    param_0: (Symbol("left"), AsNumber()),
    param_1: (Symbol("right"), AsNumber()),
    result: AsNumber()
)
private let interface_exponent_left_right = HandlerInterface(
    name: "^",
    parameters: [
        (type_exponent_left_right.param_0.0, "left", type_exponent_left_right.param_0.1),
        (type_exponent_left_right.param_1.0, "right", type_exponent_left_right.param_1.1),
    ],
    result: type_exponent_left_right.result
)
private func procedure_exponent_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_exponent_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_exponent_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try exponent(
        left: arg_0,
        right: arg_1
    )
    return type_exponent_left_right.result.box(value: result, in: handlerEnv)
}

// positive {right}
private let type_positive_right = (
    param_0: (Symbol("right"), AsNumber()),
    result: AsNumber()
)
private let interface_positive_right = HandlerInterface(
    name: "positive",
    parameters: [
        (type_positive_right.param_0.0, "right", type_positive_right.param_0.1),
    ],
    result: type_positive_right.result
)
private func procedure_positive_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_positive_right.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try positive(
        right: arg_0
    )
    return type_positive_right.result.box(value: result, in: handlerEnv)
}

// negative {right}
private let type_negative_right = (
    param_0: (Symbol("right"), AsNumber()),
    result: AsNumber()
)
private let interface_negative_right = HandlerInterface(
    name: "negative",
    parameters: [
        (type_negative_right.param_0.0, "right", type_negative_right.param_0.1),
    ],
    result: type_negative_right.result
)
private func procedure_negative_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_negative_right.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try negative(
        right: arg_0
    )
    return type_negative_right.result.box(value: result, in: handlerEnv)
}

// * {left, right}
private let type_multiply_left_right = (
    param_0: (Symbol("left"), AsNumber()),
    param_1: (Symbol("right"), AsNumber()),
    result: AsNumber()
)
private let interface_multiply_left_right = HandlerInterface(
    name: "*",
    parameters: [
        (type_multiply_left_right.param_0.0, "left", type_multiply_left_right.param_0.1),
        (type_multiply_left_right.param_1.0, "right", type_multiply_left_right.param_1.1),
    ],
    result: type_multiply_left_right.result
)
private func procedure_multiply_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_multiply_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_multiply_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try multiply(
        left: arg_0,
        right: arg_1
    )
    return type_multiply_left_right.result.box(value: result, in: handlerEnv)
}

// / {left, right}
private let type_divide_left_right = (
    param_0: (Symbol("left"), AsNumber()),
    param_1: (Symbol("right"), AsNumber()),
    result: AsNumber()
)
private let interface_divide_left_right = HandlerInterface(
    name: "/",
    parameters: [
        (type_divide_left_right.param_0.0, "left", type_divide_left_right.param_0.1),
        (type_divide_left_right.param_1.0, "right", type_divide_left_right.param_1.1),
    ],
    result: type_divide_left_right.result
)
private func procedure_divide_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_divide_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_divide_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try divide(
        left: arg_0,
        right: arg_1
    )
    return type_divide_left_right.result.box(value: result, in: handlerEnv)
}

// div {left, right}
private let type_div_left_right = (
    param_0: (Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), AsDouble()),
    result: AsDouble()
)
private let interface_div_left_right = HandlerInterface(
    name: "div",
    parameters: [
        (type_div_left_right.param_0.0, "left", type_div_left_right.param_0.1),
        (type_div_left_right.param_1.0, "right", type_div_left_right.param_1.1),
    ],
    result: type_div_left_right.result
)
private func procedure_div_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_div_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_div_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try div(
        left: arg_0,
        right: arg_1
    )
    return type_div_left_right.result.box(value: result, in: handlerEnv)
}

// mod {left, right}
private let type_mod_left_right = (
    param_0: (Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), AsDouble()),
    result: AsDouble()
)
private let interface_mod_left_right = HandlerInterface(
    name: "mod",
    parameters: [
        (type_mod_left_right.param_0.0, "left", type_mod_left_right.param_0.1),
        (type_mod_left_right.param_1.0, "right", type_mod_left_right.param_1.1),
    ],
    result: type_mod_left_right.result
)
private func procedure_mod_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_mod_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_mod_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try mod(
        left: arg_0,
        right: arg_1
    )
    return type_mod_left_right.result.box(value: result, in: handlerEnv)
}

// + {left, right}
private let type_add_left_right = (
    param_0: (Symbol("left"), AsNumber()),
    param_1: (Symbol("right"), AsNumber()),
    result: AsNumber()
)
private let interface_add_left_right = HandlerInterface(
    name: "+",
    parameters: [
        (type_add_left_right.param_0.0, "left", type_add_left_right.param_0.1),
        (type_add_left_right.param_1.0, "right", type_add_left_right.param_1.1),
    ],
    result: type_add_left_right.result
)
private func procedure_add_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_add_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_add_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try add(
        left: arg_0,
        right: arg_1
    )
    return type_add_left_right.result.box(value: result, in: handlerEnv)
}

// - {left, right}
private let type_subtract_left_right = (
    param_0: (Symbol("left"), AsNumber()),
    param_1: (Symbol("right"), AsNumber()),
    result: AsNumber()
)
private let interface_subtract_left_right = HandlerInterface(
    name: "-",
    parameters: [
        (type_subtract_left_right.param_0.0, "left", type_subtract_left_right.param_0.1),
        (type_subtract_left_right.param_1.0, "right", type_subtract_left_right.param_1.1),
    ],
    result: type_subtract_left_right.result
)
private func procedure_subtract_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_subtract_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_subtract_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try subtract(
        left: arg_0,
        right: arg_1
    )
    return type_subtract_left_right.result.box(value: result, in: handlerEnv)
}

// < {left, right}
private let type_isLess_left_right = (
    param_0: (Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), AsDouble()),
    result: asBool
)
private let interface_isLess_left_right = HandlerInterface(
    name: "<",
    parameters: [
        (type_isLess_left_right.param_0.0, "left", type_isLess_left_right.param_0.1),
        (type_isLess_left_right.param_1.0, "right", type_isLess_left_right.param_1.1),
    ],
    result: type_isLess_left_right.result
)
private func procedure_isLess_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_isLess_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isLess_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = isLess(
        left: arg_0,
        right: arg_1
    )
    return type_isLess_left_right.result.box(value: result, in: handlerEnv)
}

// ≤ {left, right}
private let type_isLessOrEqual_left_right = (
    param_0: (Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), AsDouble()),
    result: asBool
)
private let interface_isLessOrEqual_left_right = HandlerInterface(
    name: "≤",
    parameters: [
        (type_isLessOrEqual_left_right.param_0.0, "left", type_isLessOrEqual_left_right.param_0.1),
        (type_isLessOrEqual_left_right.param_1.0, "right", type_isLessOrEqual_left_right.param_1.1),
    ],
    result: type_isLessOrEqual_left_right.result
)
private func procedure_isLessOrEqual_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_isLessOrEqual_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isLessOrEqual_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = isLessOrEqual(
        left: arg_0,
        right: arg_1
    )
    return type_isLessOrEqual_left_right.result.box(value: result, in: handlerEnv)
}

// = {left, right}
private let type_isEqual_left_right = (
    param_0: (Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), AsDouble()),
    result: asBool
)
private let interface_isEqual_left_right = HandlerInterface(
    name: "=",
    parameters: [
        (type_isEqual_left_right.param_0.0, "left", type_isEqual_left_right.param_0.1),
        (type_isEqual_left_right.param_1.0, "right", type_isEqual_left_right.param_1.1),
    ],
    result: type_isEqual_left_right.result
)
private func procedure_isEqual_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_isEqual_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isEqual_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = isEqual(
        left: arg_0,
        right: arg_1
    )
    return type_isEqual_left_right.result.box(value: result, in: handlerEnv)
}

// ≠ {left, right}
private let type_isNotEqual_left_right = (
    param_0: (Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), AsDouble()),
    result: asBool
)
private let interface_isNotEqual_left_right = HandlerInterface(
    name: "≠",
    parameters: [
        (type_isNotEqual_left_right.param_0.0, "left", type_isNotEqual_left_right.param_0.1),
        (type_isNotEqual_left_right.param_1.0, "right", type_isNotEqual_left_right.param_1.1),
    ],
    result: type_isNotEqual_left_right.result
)
private func procedure_isNotEqual_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_isNotEqual_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isNotEqual_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = isNotEqual(
        left: arg_0,
        right: arg_1
    )
    return type_isNotEqual_left_right.result.box(value: result, in: handlerEnv)
}

// > {left, right}
private let type_isGreater_left_right = (
    param_0: (Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), AsDouble()),
    result: asBool
)
private let interface_isGreater_left_right = HandlerInterface(
    name: ">",
    parameters: [
        (type_isGreater_left_right.param_0.0, "left", type_isGreater_left_right.param_0.1),
        (type_isGreater_left_right.param_1.0, "right", type_isGreater_left_right.param_1.1),
    ],
    result: type_isGreater_left_right.result
)
private func procedure_isGreater_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_isGreater_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isGreater_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = isGreater(
        left: arg_0,
        right: arg_1
    )
    return type_isGreater_left_right.result.box(value: result, in: handlerEnv)
}

// ≥ {left, right}
private let type_isGreaterOrEqual_left_right = (
    param_0: (Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), AsDouble()),
    result: asBool
)
private let interface_isGreaterOrEqual_left_right = HandlerInterface(
    name: "≥",
    parameters: [
        (type_isGreaterOrEqual_left_right.param_0.0, "left", type_isGreaterOrEqual_left_right.param_0.1),
        (type_isGreaterOrEqual_left_right.param_1.0, "right", type_isGreaterOrEqual_left_right.param_1.1),
    ],
    result: type_isGreaterOrEqual_left_right.result
)
private func procedure_isGreaterOrEqual_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_isGreaterOrEqual_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isGreaterOrEqual_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = isGreaterOrEqual(
        left: arg_0,
        right: arg_1
    )
    return type_isGreaterOrEqual_left_right.result.box(value: result, in: handlerEnv)
}

// NOT {right}
private let type_NOT_right = (
    param_0: (Symbol("right"), asBool),
    result: asBool
)
private let interface_NOT_right = HandlerInterface(
    name: "NOT",
    parameters: [
        (type_NOT_right.param_0.0, "right", type_NOT_right.param_0.1),
    ],
    result: type_NOT_right.result
)
private func procedure_NOT_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_NOT_right.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = NOT(
        right: arg_0
    )
    return type_NOT_right.result.box(value: result, in: handlerEnv)
}

// AND {left, right}
private let type_AND_left_right = (
    param_0: (Symbol("left"), asBool),
    param_1: (Symbol("right"), asBool),
    result: asBool
)
private let interface_AND_left_right = HandlerInterface(
    name: "AND",
    parameters: [
        (type_AND_left_right.param_0.0, "left", type_AND_left_right.param_0.1),
        (type_AND_left_right.param_1.0, "right", type_AND_left_right.param_1.1),
    ],
    result: type_AND_left_right.result
)
private func procedure_AND_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_AND_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_AND_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = AND(
        left: arg_0,
        right: arg_1
    )
    return type_AND_left_right.result.box(value: result, in: handlerEnv)
}

// OR {left, right}
private let type_OR_left_right = (
    param_0: (Symbol("left"), asBool),
    param_1: (Symbol("right"), asBool),
    result: asBool
)
private let interface_OR_left_right = HandlerInterface(
    name: "OR",
    parameters: [
        (type_OR_left_right.param_0.0, "left", type_OR_left_right.param_0.1),
        (type_OR_left_right.param_1.0, "right", type_OR_left_right.param_1.1),
    ],
    result: type_OR_left_right.result
)
private func procedure_OR_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_OR_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_OR_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = OR(
        left: arg_0,
        right: arg_1
    )
    return type_OR_left_right.result.box(value: result, in: handlerEnv)
}

// XOR {left, right}
private let type_XOR_left_right = (
    param_0: (Symbol("left"), asBool),
    param_1: (Symbol("right"), asBool),
    result: asBool
)
private let interface_XOR_left_right = HandlerInterface(
    name: "XOR",
    parameters: [
        (type_XOR_left_right.param_0.0, "left", type_XOR_left_right.param_0.1),
        (type_XOR_left_right.param_1.0, "right", type_XOR_left_right.param_1.1),
    ],
    result: type_XOR_left_right.result
)
private func procedure_XOR_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_XOR_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_XOR_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = XOR(
        left: arg_0,
        right: arg_1
    )
    return type_XOR_left_right.result.box(value: result, in: handlerEnv)
}

// is_before {left, right}
private let type_isBefore_left_right = (
    param_0: (Symbol("left"), AsString()),
    param_1: (Symbol("right"), AsString()),
    result: asBool
)
private let interface_isBefore_left_right = HandlerInterface(
    name: "is_before",
    parameters: [
        (type_isBefore_left_right.param_0.0, "left", type_isBefore_left_right.param_0.1),
        (type_isBefore_left_right.param_1.0, "right", type_isBefore_left_right.param_1.1),
    ],
    result: type_isBefore_left_right.result
)
private func procedure_isBefore_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_isBefore_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isBefore_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try isBefore(
        left: arg_0,
        right: arg_1
    )
    return type_isBefore_left_right.result.box(value: result, in: handlerEnv)
}

// is_not_after {left, right}
private let type_isNotAfter_left_right = (
    param_0: (Symbol("left"), AsString()),
    param_1: (Symbol("right"), AsString()),
    result: asBool
)
private let interface_isNotAfter_left_right = HandlerInterface(
    name: "is_not_after",
    parameters: [
        (type_isNotAfter_left_right.param_0.0, "left", type_isNotAfter_left_right.param_0.1),
        (type_isNotAfter_left_right.param_1.0, "right", type_isNotAfter_left_right.param_1.1),
    ],
    result: type_isNotAfter_left_right.result
)
private func procedure_isNotAfter_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_isNotAfter_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isNotAfter_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try isNotAfter(
        left: arg_0,
        right: arg_1
    )
    return type_isNotAfter_left_right.result.box(value: result, in: handlerEnv)
}

// is {left, right}
private let type_isSameAs_left_right = (
    param_0: (Symbol("left"), AsString()),
    param_1: (Symbol("right"), AsString()),
    result: asBool
)
private let interface_isSameAs_left_right = HandlerInterface(
    name: "is",
    parameters: [
        (type_isSameAs_left_right.param_0.0, "left", type_isSameAs_left_right.param_0.1),
        (type_isSameAs_left_right.param_1.0, "right", type_isSameAs_left_right.param_1.1),
    ],
    result: type_isSameAs_left_right.result
)
private func procedure_isSameAs_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_isSameAs_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isSameAs_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try isSameAs(
        left: arg_0,
        right: arg_1
    )
    return type_isSameAs_left_right.result.box(value: result, in: handlerEnv)
}

// is_not {left, right}
private let type_isNotSameAs_left_right = (
    param_0: (Symbol("left"), AsString()),
    param_1: (Symbol("right"), AsString()),
    result: asBool
)
private let interface_isNotSameAs_left_right = HandlerInterface(
    name: "is_not",
    parameters: [
        (type_isNotSameAs_left_right.param_0.0, "left", type_isNotSameAs_left_right.param_0.1),
        (type_isNotSameAs_left_right.param_1.0, "right", type_isNotSameAs_left_right.param_1.1),
    ],
    result: type_isNotSameAs_left_right.result
)
private func procedure_isNotSameAs_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_isNotSameAs_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isNotSameAs_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try isNotSameAs(
        left: arg_0,
        right: arg_1
    )
    return type_isNotSameAs_left_right.result.box(value: result, in: handlerEnv)
}

// is_after {left, right}
private let type_isAfter_left_right = (
    param_0: (Symbol("left"), AsString()),
    param_1: (Symbol("right"), AsString()),
    result: asBool
)
private let interface_isAfter_left_right = HandlerInterface(
    name: "is_after",
    parameters: [
        (type_isAfter_left_right.param_0.0, "left", type_isAfter_left_right.param_0.1),
        (type_isAfter_left_right.param_1.0, "right", type_isAfter_left_right.param_1.1),
    ],
    result: type_isAfter_left_right.result
)
private func procedure_isAfter_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_isAfter_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isAfter_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try isAfter(
        left: arg_0,
        right: arg_1
    )
    return type_isAfter_left_right.result.box(value: result, in: handlerEnv)
}

// is_not_before {left, right}
private let type_isNotBefore_left_right = (
    param_0: (Symbol("left"), AsString()),
    param_1: (Symbol("right"), AsString()),
    result: asBool
)
private let interface_isNotBefore_left_right = HandlerInterface(
    name: "is_not_before",
    parameters: [
        (type_isNotBefore_left_right.param_0.0, "left", type_isNotBefore_left_right.param_0.1),
        (type_isNotBefore_left_right.param_1.0, "right", type_isNotBefore_left_right.param_1.1),
    ],
    result: type_isNotBefore_left_right.result
)
private func procedure_isNotBefore_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_isNotBefore_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isNotBefore_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try isNotBefore(
        left: arg_0,
        right: arg_1
    )
    return type_isNotBefore_left_right.result.box(value: result, in: handlerEnv)
}

// begins_with {left, right}
private let type_beginsWith_left_right = (
    param_0: (Symbol("left"), AsString()),
    param_1: (Symbol("right"), AsString()),
    result: asBool
)
private let interface_beginsWith_left_right = HandlerInterface(
    name: "begins_with",
    parameters: [
        (type_beginsWith_left_right.param_0.0, "left", type_beginsWith_left_right.param_0.1),
        (type_beginsWith_left_right.param_1.0, "right", type_beginsWith_left_right.param_1.1),
    ],
    result: type_beginsWith_left_right.result
)
private func procedure_beginsWith_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_beginsWith_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_beginsWith_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try beginsWith(
        left: arg_0,
        right: arg_1
    )
    return type_beginsWith_left_right.result.box(value: result, in: handlerEnv)
}

// ends_with {left, right}
private let type_endsWith_left_right = (
    param_0: (Symbol("left"), AsString()),
    param_1: (Symbol("right"), AsString()),
    result: asBool
)
private let interface_endsWith_left_right = HandlerInterface(
    name: "ends_with",
    parameters: [
        (type_endsWith_left_right.param_0.0, "left", type_endsWith_left_right.param_0.1),
        (type_endsWith_left_right.param_1.0, "right", type_endsWith_left_right.param_1.1),
    ],
    result: type_endsWith_left_right.result
)
private func procedure_endsWith_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_endsWith_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_endsWith_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try endsWith(
        left: arg_0,
        right: arg_1
    )
    return type_endsWith_left_right.result.box(value: result, in: handlerEnv)
}

// contains {left, right}
private let type_contains_left_right = (
    param_0: (Symbol("left"), AsString()),
    param_1: (Symbol("right"), AsString()),
    result: asBool
)
private let interface_contains_left_right = HandlerInterface(
    name: "contains",
    parameters: [
        (type_contains_left_right.param_0.0, "left", type_contains_left_right.param_0.1),
        (type_contains_left_right.param_1.0, "right", type_contains_left_right.param_1.1),
    ],
    result: type_contains_left_right.result
)
private func procedure_contains_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_contains_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_contains_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try contains(
        left: arg_0,
        right: arg_1
    )
    return type_contains_left_right.result.box(value: result, in: handlerEnv)
}

// is_in {left, right}
private let type_isIn_left_right = (
    param_0: (Symbol("left"), AsString()),
    param_1: (Symbol("right"), AsString()),
    result: asBool
)
private let interface_isIn_left_right = HandlerInterface(
    name: "is_in",
    parameters: [
        (type_isIn_left_right.param_0.0, "left", type_isIn_left_right.param_0.1),
        (type_isIn_left_right.param_1.0, "right", type_isIn_left_right.param_1.1),
    ],
    result: type_isIn_left_right.result
)
private func procedure_isIn_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_isIn_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isIn_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try isIn(
        left: arg_0,
        right: arg_1
    )
    return type_isIn_left_right.result.box(value: result, in: handlerEnv)
}

// & {left, right}
private let type_joinValues_left_right = (
    param_0: (Symbol("left"), AsString()),
    param_1: (Symbol("right"), AsString()),
    result: AsString()
)
private let interface_joinValues_left_right = HandlerInterface(
    name: "&",
    parameters: [
        (type_joinValues_left_right.param_0.0, "left", type_joinValues_left_right.param_0.1),
        (type_joinValues_left_right.param_1.0, "right", type_joinValues_left_right.param_1.1),
    ],
    result: type_joinValues_left_right.result
)
private func procedure_joinValues_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_joinValues_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_joinValues_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try joinValues(
        left: arg_0,
        right: arg_1
    )
    return type_joinValues_left_right.result.box(value: result, in: handlerEnv)
}

// uppercase {text}
private let type_uppercase_text = (
    param_0: (Symbol("text"), AsString()),
    result: AsString()
)
private let interface_uppercase_text = HandlerInterface(
    name: "uppercase",
    parameters: [
        (type_uppercase_text.param_0.0, "text", type_uppercase_text.param_0.1),
    ],
    result: type_uppercase_text.result
)
private func procedure_uppercase_text(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_uppercase_text.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = uppercase(
        text: arg_0
    )
    return type_uppercase_text.result.box(value: result, in: handlerEnv)
}

// lowercase {text}
private let type_lowercase_text = (
    param_0: (Symbol("text"), AsString()),
    result: AsString()
)
private let interface_lowercase_text = HandlerInterface(
    name: "lowercase",
    parameters: [
        (type_lowercase_text.param_0.0, "text", type_lowercase_text.param_0.1),
    ],
    result: type_lowercase_text.result
)
private func procedure_lowercase_text(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_lowercase_text.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = lowercase(
        text: arg_0
    )
    return type_lowercase_text.result.box(value: result, in: handlerEnv)
}

// format_code {value}
private let type_formatCode_value = (
    param_0: (Symbol("value"), AsOptional(AsValue())),
    result: AsString()
)
private let interface_formatCode_value = HandlerInterface(
    name: "format_code",
    parameters: [
        (type_formatCode_value.param_0.0, "value", type_formatCode_value.param_0.1),
    ],
    result: type_formatCode_value.result
)
private func procedure_formatCode_value(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_formatCode_value.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = formatCode(
        value: arg_0
    )
    return type_formatCode_value.result.box(value: result, in: handlerEnv)
}

// write {value}
private let type_write_value = (
    param_0: (Symbol("value"), AsOptional(AsValue())),
    result: AsNothing()
)
private let interface_write_value = HandlerInterface(
    name: "write",
    parameters: [
        (type_write_value.param_0.0, "value", type_write_value.param_0.1),
    ],
    result: type_write_value.result
)
private func procedure_write_value(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_write_value.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    write(
        value: arg_0
    )
    return nullValue
}

// is_a {left, right}
private let type_isA_left_right = (
    param_0: (Symbol("left"), AsOptional(AsValue())),
    param_1: (Symbol("right"), AsCoercion()),
    result: asBool
)
private let interface_isA_left_right = HandlerInterface(
    name: "is_a",
    parameters: [
        (type_isA_left_right.param_0.0, "value", type_isA_left_right.param_0.1),
        (type_isA_left_right.param_1.0, "coercion", type_isA_left_right.param_1.1),
    ],
    result: type_isA_left_right.result
)
private func procedure_isA_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_isA_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isA_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = isA(
        left: arg_0,
        right: arg_1,
        commandEnv: commandEnv
    )
    return type_isA_left_right.result.box(value: result, in: handlerEnv)
}

// as {left, right}
private let type_coerce_left_right = (
    param_0: (Symbol("left"), AsOptional(AsValue())),
    param_1: (Symbol("right"), AsCoercion()),
    result: AsOptional(AsValue())
)
private let interface_coerce_left_right = HandlerInterface(
    name: "as",
    parameters: [
        (type_coerce_left_right.param_0.0, "value", type_coerce_left_right.param_0.1),
        (type_coerce_left_right.param_1.0, "coercion", type_coerce_left_right.param_1.1),
    ],
    result: type_coerce_left_right.result
)
private func procedure_coerce_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_coerce_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_coerce_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try coerce(
        left: arg_0,
        right: arg_1,
        commandEnv: commandEnv
    )
    return type_coerce_left_right.result.box(value: result, in: handlerEnv)
}

// to {right}
private let type_defineCommandHandler_right = (
    param_0: (Symbol("right"), AsHandler()),
    result: AsHandler()
)
private let interface_defineCommandHandler_right = HandlerInterface(
    name: "to",
    parameters: [
        (type_defineCommandHandler_right.param_0.0, "handler", type_defineCommandHandler_right.param_0.1),
    ],
    result: type_defineCommandHandler_right.result
)
private func procedure_defineCommandHandler_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_defineCommandHandler_right.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try defineCommandHandler(
        right: arg_0,
        commandEnv: commandEnv
    )
    return type_defineCommandHandler_right.result.box(value: result, in: handlerEnv)
}

// when {right}
private let type_defineEventHandler_right = (
    param_0: (Symbol("right"), AsHandler()),
    result: AsHandler()
)
private let interface_defineEventHandler_right = HandlerInterface(
    name: "when",
    parameters: [
        (type_defineEventHandler_right.param_0.0, "handler", type_defineEventHandler_right.param_0.1),
    ],
    result: type_defineEventHandler_right.result
)
private func procedure_defineEventHandler_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_defineEventHandler_right.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try defineEventHandler(
        right: arg_0,
        commandEnv: commandEnv
    )
    return type_defineEventHandler_right.result.box(value: result, in: handlerEnv)
}

// set {name, to}
private let type_set_name_to = (
    param_0: (Symbol("name"), AsLiteralName()),
    param_1: (Symbol("to"), AsValue()),
    result: AsOptional(AsValue())
)
private let interface_set_name_to = HandlerInterface(
    name: "set",
    parameters: [
        (type_set_name_to.param_0.0, "name", type_set_name_to.param_0.1),
        (type_set_name_to.param_1.0, "value", type_set_name_to.param_1.1),
    ],
    result: type_set_name_to.result
)
private func procedure_set_name_to(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_set_name_to.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_set_name_to.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try set(
        name: arg_0,
        to: arg_1,
        commandEnv: commandEnv
    )
    return type_set_name_to.result.box(value: result, in: handlerEnv)
}

// if {left, right}
private let type_ifTest_condition_action = (
    param_0: (Symbol("left"), asBool),
    param_1: (Symbol("right"), asIs),
    result: AsOptional(AsValue())
)
private let interface_ifTest_condition_action = HandlerInterface(
    name: "if",
    parameters: [
        (type_ifTest_condition_action.param_0.0, "condition", type_ifTest_condition_action.param_0.1),
        (type_ifTest_condition_action.param_1.0, "action", type_ifTest_condition_action.param_1.1),
    ],
    result: type_ifTest_condition_action.result
)
private func procedure_ifTest_condition_action(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_ifTest_condition_action.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_ifTest_condition_action.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try ifTest(
        condition: arg_0,
        action: arg_1,
        commandEnv: commandEnv
    )
    return type_ifTest_condition_action.result.box(value: result, in: handlerEnv)
}

// else {left, right}
private let type_elseTest_left_right = (
    param_0: (Symbol("left"), asIs),
    param_1: (Symbol("right"), asIs),
    result: AsOptional(AsValue())
)
private let interface_elseTest_left_right = HandlerInterface(
    name: "else",
    parameters: [
        (type_elseTest_left_right.param_0.0, "left", type_elseTest_left_right.param_0.1),
        (type_elseTest_left_right.param_1.0, "right", type_elseTest_left_right.param_1.1),
    ],
    result: type_elseTest_left_right.result
)
private func procedure_elseTest_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_elseTest_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_elseTest_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try elseTest(
        left: arg_0,
        right: arg_1,
        commandEnv: commandEnv
    )
    return type_elseTest_left_right.result.box(value: result, in: handlerEnv)
}

// while {left, right}
private let type_whileRepeat_condition_action = (
    param_0: (Symbol("left"), asBool),
    param_1: (Symbol("right"), asIs),
    result: AsOptional(AsValue())
)
private let interface_whileRepeat_condition_action = HandlerInterface(
    name: "while",
    parameters: [
        (type_whileRepeat_condition_action.param_0.0, "condition", type_whileRepeat_condition_action.param_0.1),
        (type_whileRepeat_condition_action.param_1.0, "action", type_whileRepeat_condition_action.param_1.1),
    ],
    result: type_whileRepeat_condition_action.result
)
private func procedure_whileRepeat_condition_action(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_whileRepeat_condition_action.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_whileRepeat_condition_action.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try whileRepeat(
        condition: arg_0,
        action: arg_1,
        commandEnv: commandEnv
    )
    return type_whileRepeat_condition_action.result.box(value: result, in: handlerEnv)
}

// repeat {left, right}
private let type_repeatWhile_action_condition = (
    param_0: (Symbol("left"), asIs),
    param_1: (Symbol("right"), asBool),
    result: AsOptional(AsValue())
)
private let interface_repeatWhile_action_condition = HandlerInterface(
    name: "repeat",
    parameters: [
        (type_repeatWhile_action_condition.param_0.0, "action", type_repeatWhile_action_condition.param_0.1),
        (type_repeatWhile_action_condition.param_1.0, "condition", type_repeatWhile_action_condition.param_1.1),
    ],
    result: type_repeatWhile_action_condition.result
)
private func procedure_repeatWhile_action_condition(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_repeatWhile_action_condition.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_repeatWhile_action_condition.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try repeatWhile(
        action: arg_0,
        condition: arg_1,
        commandEnv: commandEnv
    )
    return type_repeatWhile_action_condition.result.box(value: result, in: handlerEnv)
}

// tell {left, right}
private let type_tell_target_action = (
    param_0: (Symbol("left"), AsValue()),
    param_1: (Symbol("right"), asIs),
    result: AsOptional(AsValue())
)
private let interface_tell_target_action = HandlerInterface(
    name: "tell",
    parameters: [
        (type_tell_target_action.param_0.0, "target", type_tell_target_action.param_0.1),
        (type_tell_target_action.param_1.0, "action", type_tell_target_action.param_1.1),
    ],
    result: type_tell_target_action.result
)
private func procedure_tell_target_action(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_tell_target_action.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_tell_target_action.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try tell(
        target: arg_0,
        action: arg_1,
        commandEnv: commandEnv
    )
    return type_tell_target_action.result.box(value: result, in: handlerEnv)
}

// of {left, right}
private let type_ofClause_attribute_target = (
    param_0: (Symbol("left"), asIs),
    param_1: (Symbol("right"), AsValue()),
    result: asIs
)
private let interface_ofClause_attribute_target = HandlerInterface(
    name: "of",
    parameters: [
        (type_ofClause_attribute_target.param_0.0, "attribute", type_ofClause_attribute_target.param_0.1),
        (type_ofClause_attribute_target.param_1.0, "value", type_ofClause_attribute_target.param_1.1),
    ],
    result: type_ofClause_attribute_target.result
)
private func procedure_ofClause_attribute_target(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_ofClause_attribute_target.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_ofClause_attribute_target.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try ofClause(
        attribute: arg_0,
        target: arg_1,
        commandEnv: commandEnv,
        handlerEnv: handlerEnv
    )
    return type_ofClause_attribute_target.result.box(value: result, in: handlerEnv)
}

// app {bundle_identifier}
private let type_AEApplication_bundleID = (
    param_0: (Symbol("bundle_identifier"), AsString()),
    result: AsValue()
)
private let interface_AEApplication_bundleID = HandlerInterface(
    name: "app",
    parameters: [
        (type_AEApplication_bundleID.param_0.0, "bundle_identifier", type_AEApplication_bundleID.param_0.1),
    ],
    result: type_AEApplication_bundleID.result
)
private func procedure_AEApplication_bundleID(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_AEApplication_bundleID.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try Application(
        bundleIdentifier: arg_0
    )
    return type_AEApplication_bundleID.result.box(value: result, in: handlerEnv)
}

// at {left, right}
private let type_atSelector_elementType_selectorData = (
    param_0: (Symbol("left"), AsLiteralName()),
    param_1: (Symbol("right"), asIs),
    result: asIs
)
private let interface_atSelector_elementType_selectorData = HandlerInterface(
    name: "at",
    parameters: [
        (type_atSelector_elementType_selectorData.param_0.0, "element_type", type_atSelector_elementType_selectorData.param_0.1),
        (type_atSelector_elementType_selectorData.param_1.0, "selector_data", type_atSelector_elementType_selectorData.param_1.1),
    ],
    result: type_atSelector_elementType_selectorData.result
)
private func procedure_atSelector_elementType_selectorData(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_atSelector_elementType_selectorData.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_atSelector_elementType_selectorData.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try atSelector(
        elementType: arg_0,
        selectorData: arg_1,
        commandEnv: commandEnv,
        handlerEnv: handlerEnv
    )
    return type_atSelector_elementType_selectorData.result.box(value: result, in: handlerEnv)
}

// named {left, right}
private let type_nameSelector_elementType_selectorData = (
    param_0: (Symbol("left"), AsLiteralName()),
    param_1: (Symbol("right"), asIs),
    result: asIs
)
private let interface_nameSelector_elementType_selectorData = HandlerInterface(
    name: "named",
    parameters: [
        (type_nameSelector_elementType_selectorData.param_0.0, "element_type", type_nameSelector_elementType_selectorData.param_0.1),
        (type_nameSelector_elementType_selectorData.param_1.0, "selector_data", type_nameSelector_elementType_selectorData.param_1.1),
    ],
    result: type_nameSelector_elementType_selectorData.result
)
private func procedure_nameSelector_elementType_selectorData(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_nameSelector_elementType_selectorData.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_nameSelector_elementType_selectorData.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try nameSelector(
        elementType: arg_0,
        selectorData: arg_1,
        commandEnv: commandEnv
    )
    return type_nameSelector_elementType_selectorData.result.box(value: result, in: handlerEnv)
}

// id {left, right}
private let type_idSelector_elementType_selectorData = (
    param_0: (Symbol("left"), AsLiteralName()),
    param_1: (Symbol("right"), asIs),
    result: asIs
)
private let interface_idSelector_elementType_selectorData = HandlerInterface(
    name: "id",
    parameters: [
        (type_idSelector_elementType_selectorData.param_0.0, "element_type", type_idSelector_elementType_selectorData.param_0.1),
        (type_idSelector_elementType_selectorData.param_1.0, "selector_data", type_idSelector_elementType_selectorData.param_1.1),
    ],
    result: type_idSelector_elementType_selectorData.result
)
private func procedure_idSelector_elementType_selectorData(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_idSelector_elementType_selectorData.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_idSelector_elementType_selectorData.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try idSelector(
        elementType: arg_0,
        selectorData: arg_1,
        commandEnv: commandEnv
    )
    return type_idSelector_elementType_selectorData.result.box(value: result, in: handlerEnv)
}

// where {left, right}
private let type_whereSelector_elementType_selectorData = (
    param_0: (Symbol("left"), AsLiteralName()),
    param_1: (Symbol("right"), asIs),
    result: asIs
)
private let interface_whereSelector_elementType_selectorData = HandlerInterface(
    name: "where",
    parameters: [
        (type_whereSelector_elementType_selectorData.param_0.0, "element_type", type_whereSelector_elementType_selectorData.param_0.1),
        (type_whereSelector_elementType_selectorData.param_1.0, "selector_data", type_whereSelector_elementType_selectorData.param_1.1),
    ],
    result: type_whereSelector_elementType_selectorData.result
)
private func procedure_whereSelector_elementType_selectorData(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_whereSelector_elementType_selectorData.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_whereSelector_elementType_selectorData.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try testSelector(
        elementType: arg_0,
        selectorData: arg_1,
        commandEnv: commandEnv,
        handlerEnv: handlerEnv
    )
    return type_whereSelector_elementType_selectorData.result.box(value: result, in: handlerEnv)
}

// thru {left, right}
private let type_ElementRange_from_to = (
    param_0: (Symbol("left"), asIs),
    param_1: (Symbol("right"), asIs),
    result: asIs
)
private let interface_ElementRange_from_to = HandlerInterface(
    name: "thru",
    parameters: [
        (type_ElementRange_from_to.param_0.0, "startSelector", type_ElementRange_from_to.param_0.1),
        (type_ElementRange_from_to.param_1.0, "endSelector", type_ElementRange_from_to.param_1.1),
    ],
    result: type_ElementRange_from_to.result
)
private func procedure_ElementRange_from_to(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_ElementRange_from_to.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_ElementRange_from_to.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = ElementRange(
        from: arg_0,
        to: arg_1
    )
    return type_ElementRange_from_to.result.box(value: result, in: handlerEnv)
}

// first {right}
private let type_firstElement_right = (
    param_0: (Symbol("right"), AsLiteralName()),
    result: asIs
)
private let interface_firstElement_right = HandlerInterface(
    name: "first",
    parameters: [
        (type_firstElement_right.param_0.0, "element_type", type_firstElement_right.param_0.1),
    ],
    result: type_firstElement_right.result
)
private func procedure_firstElement_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_firstElement_right.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = firstElement(
        right: arg_0,
        commandEnv: commandEnv
    )
    return type_firstElement_right.result.box(value: result, in: handlerEnv)
}

// middle {right}
private let type_middleElement_right = (
    param_0: (Symbol("right"), AsLiteralName()),
    result: asIs
)
private let interface_middleElement_right = HandlerInterface(
    name: "middle",
    parameters: [
        (type_middleElement_right.param_0.0, "element_type", type_middleElement_right.param_0.1),
    ],
    result: type_middleElement_right.result
)
private func procedure_middleElement_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_middleElement_right.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = middleElement(
        right: arg_0
    )
    return type_middleElement_right.result.box(value: result, in: handlerEnv)
}

// last {right}
private let type_lastElement_right = (
    param_0: (Symbol("right"), AsLiteralName()),
    result: asIs
)
private let interface_lastElement_right = HandlerInterface(
    name: "last",
    parameters: [
        (type_lastElement_right.param_0.0, "element_type", type_lastElement_right.param_0.1),
    ],
    result: type_lastElement_right.result
)
private func procedure_lastElement_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_lastElement_right.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = lastElement(
        right: arg_0
    )
    return type_lastElement_right.result.box(value: result, in: handlerEnv)
}

// any {right}
private let type_randomElement_right = (
    param_0: (Symbol("right"), AsLiteralName()),
    result: asIs
)
private let interface_randomElement_right = HandlerInterface(
    name: "any",
    parameters: [
        (type_randomElement_right.param_0.0, "element_type", type_randomElement_right.param_0.1),
    ],
    result: type_randomElement_right.result
)
private func procedure_randomElement_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_randomElement_right.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = randomElement(
        right: arg_0
    )
    return type_randomElement_right.result.box(value: result, in: handlerEnv)
}

// every {right}
private let type_allElements_right = (
    param_0: (Symbol("right"), AsLiteralName()),
    result: asIs
)
private let interface_allElements_right = HandlerInterface(
    name: "every",
    parameters: [
        (type_allElements_right.param_0.0, "element_type", type_allElements_right.param_0.1),
    ],
    result: type_allElements_right.result
)
private func procedure_allElements_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_allElements_right.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = allElements(
        right: arg_0
    )
    return type_allElements_right.result.box(value: result, in: handlerEnv)
}

// before {left, right}
private let type_beforeElement_left_right = (
    param_0: (Symbol("left"), AsLiteralName()),
    param_1: (Symbol("right"), asIs),
    result: asIs
)
private let interface_beforeElement_left_right = HandlerInterface(
    name: "before",
    parameters: [
        (type_beforeElement_left_right.param_0.0, "element_type", type_beforeElement_left_right.param_0.1),
        (type_beforeElement_left_right.param_1.0, "expression", type_beforeElement_left_right.param_1.1),
    ],
    result: type_beforeElement_left_right.result
)
private func procedure_beforeElement_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_beforeElement_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_beforeElement_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = beforeElement(
        left: arg_0,
        right: arg_1
    )
    return type_beforeElement_left_right.result.box(value: result, in: handlerEnv)
}

// after {left, right}
private let type_afterElement_left_right = (
    param_0: (Symbol("left"), AsLiteralName()),
    param_1: (Symbol("right"), asIs),
    result: asIs
)
private let interface_afterElement_left_right = HandlerInterface(
    name: "after",
    parameters: [
        (type_afterElement_left_right.param_0.0, "element_type", type_afterElement_left_right.param_0.1),
        (type_afterElement_left_right.param_1.0, "expression", type_afterElement_left_right.param_1.1),
    ],
    result: type_afterElement_left_right.result
)
private func procedure_afterElement_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_afterElement_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_afterElement_left_right.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = afterElement(
        left: arg_0,
        right: arg_1
    )
    return type_afterElement_left_right.result.box(value: result, in: handlerEnv)
}

// before {right}
private let type_insertBefore_right = (
    param_0: (Symbol("right"), asIs),
    result: asIs
)
private let interface_insertBefore_right = HandlerInterface(
    name: "before",
    parameters: [
        (type_insertBefore_right.param_0.0, "expression", type_insertBefore_right.param_0.1),
    ],
    result: type_insertBefore_right.result
)
private func procedure_insertBefore_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_insertBefore_right.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = insertBefore(
        right: arg_0
    )
    return type_insertBefore_right.result.box(value: result, in: handlerEnv)
}

// after {right}
private let type_insertAfter_right = (
    param_0: (Symbol("right"), asIs),
    result: asIs
)
private let interface_insertAfter_right = HandlerInterface(
    name: "after",
    parameters: [
        (type_insertAfter_right.param_0.0, "expression", type_insertAfter_right.param_0.1),
    ],
    result: type_insertAfter_right.result
)
private func procedure_insertAfter_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_insertAfter_right.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = insertAfter(
        right: arg_0
    )
    return type_insertAfter_right.result.box(value: result, in: handlerEnv)
}

// beginning {}
private let type_insertAtBeginning_ = (
    _: (),
    result: asIs
)
private let interface_insertAtBeginning_ = HandlerInterface(
    name: "beginning",
    parameters: [
    ],
    result: type_insertAtBeginning_.result
)
private func procedure_insertAtBeginning_(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    if !command.arguments.isEmpty { throw UnknownArgumentError(at: 0, of: command) }
    let result = insertAtBeginning(
    )
    return type_insertAtBeginning_.result.box(value: result, in: handlerEnv)
}

// end {}
private let type_insertAtEnd_ = (
    _: (),
    result: asIs
)
private let interface_insertAtEnd_ = HandlerInterface(
    name: "end",
    parameters: [
    ],
    result: type_insertAtEnd_.result
)
private func procedure_insertAtEnd_(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    if !command.arguments.isEmpty { throw UnknownArgumentError(at: 0, of: command) }
    let result = insertAtEnd(
    )
    return type_insertAtEnd_.result.box(value: result, in: handlerEnv)
}



public func stdlib_loadHandlers(into env: Environment) {
    env.define(interface_exponent_left_right, procedure_exponent_left_right)
    env.define(interface_positive_right, procedure_positive_right)
    env.define(interface_negative_right, procedure_negative_right)
    env.define(interface_multiply_left_right, procedure_multiply_left_right)
    env.define(interface_divide_left_right, procedure_divide_left_right)
    env.define(interface_div_left_right, procedure_div_left_right)
    env.define(interface_mod_left_right, procedure_mod_left_right)
    env.define(interface_add_left_right, procedure_add_left_right)
    env.define(interface_subtract_left_right, procedure_subtract_left_right)
    env.define(interface_isLess_left_right, procedure_isLess_left_right)
    env.define(interface_isLessOrEqual_left_right, procedure_isLessOrEqual_left_right)
    env.define(interface_isEqual_left_right, procedure_isEqual_left_right)
    env.define(interface_isNotEqual_left_right, procedure_isNotEqual_left_right)
    env.define(interface_isGreater_left_right, procedure_isGreater_left_right)
    env.define(interface_isGreaterOrEqual_left_right, procedure_isGreaterOrEqual_left_right)
    env.define(interface_NOT_right, procedure_NOT_right)
    env.define(interface_AND_left_right, procedure_AND_left_right)
    env.define(interface_OR_left_right, procedure_OR_left_right)
    env.define(interface_XOR_left_right, procedure_XOR_left_right)
    env.define(interface_isBefore_left_right, procedure_isBefore_left_right)
    env.define(interface_isNotAfter_left_right, procedure_isNotAfter_left_right)
    env.define(interface_isSameAs_left_right, procedure_isSameAs_left_right)
    env.define(interface_isNotSameAs_left_right, procedure_isNotSameAs_left_right)
    env.define(interface_isAfter_left_right, procedure_isAfter_left_right)
    env.define(interface_isNotBefore_left_right, procedure_isNotBefore_left_right)
    env.define(interface_beginsWith_left_right, procedure_beginsWith_left_right)
    env.define(interface_endsWith_left_right, procedure_endsWith_left_right)
    env.define(interface_contains_left_right, procedure_contains_left_right)
    env.define(interface_isIn_left_right, procedure_isIn_left_right)
    env.define(interface_joinValues_left_right, procedure_joinValues_left_right)
    env.define(interface_uppercase_text, procedure_uppercase_text)
    env.define(interface_lowercase_text, procedure_lowercase_text)
    env.define(interface_formatCode_value, procedure_formatCode_value)
    env.define(interface_write_value, procedure_write_value)
    env.define(interface_isA_left_right, procedure_isA_left_right)
    env.define(interface_coerce_left_right, procedure_coerce_left_right)
    env.define(interface_defineCommandHandler_right, procedure_defineCommandHandler_right)
    env.define(interface_defineEventHandler_right, procedure_defineEventHandler_right)
    env.define(interface_set_name_to, procedure_set_name_to)
    env.define(interface_ifTest_condition_action, procedure_ifTest_condition_action)
    env.define(interface_elseTest_left_right, procedure_elseTest_left_right)
    env.define(interface_whileRepeat_condition_action, procedure_whileRepeat_condition_action)
    env.define(interface_repeatWhile_action_condition, procedure_repeatWhile_action_condition)
    env.define(interface_tell_target_action, procedure_tell_target_action)
    env.define(interface_ofClause_attribute_target, procedure_ofClause_attribute_target)
    env.define(interface_AEApplication_bundleID, procedure_AEApplication_bundleID)
    env.define(interface_atSelector_elementType_selectorData, procedure_atSelector_elementType_selectorData)
    env.define(interface_nameSelector_elementType_selectorData, procedure_nameSelector_elementType_selectorData)
    env.define(interface_idSelector_elementType_selectorData, procedure_idSelector_elementType_selectorData)
    env.define(interface_whereSelector_elementType_selectorData, procedure_whereSelector_elementType_selectorData)
    env.define(interface_ElementRange_from_to, procedure_ElementRange_from_to)
    env.define(interface_firstElement_right, procedure_firstElement_right)
    env.define(interface_middleElement_right, procedure_middleElement_right)
    env.define(interface_lastElement_right, procedure_lastElement_right)
    env.define(interface_randomElement_right, procedure_randomElement_right)
    env.define(interface_allElements_right, procedure_allElements_right)
    env.define(interface_beforeElement_left_right, procedure_beforeElement_left_right)
    env.define(interface_afterElement_left_right, procedure_afterElement_left_right)
    env.define(interface_insertBefore_right, procedure_insertBefore_right)
    env.define(interface_insertAfter_right, procedure_insertAfter_right)
    env.define(interface_insertAtBeginning_, procedure_insertAtBeginning_)
    env.define(interface_insertAtEnd_, procedure_insertAtEnd_)
}
