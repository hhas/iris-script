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

// positive {left}
private let type_positive_left = (
    param_0: (Symbol("left"), AsNumber()),
    result: AsNumber()
)
private let interface_positive_left = HandlerInterface(
    name: "positive",
    parameters: [
        (type_positive_left.param_0.0, "left", type_positive_left.param_0.1),
    ],
    result: type_positive_left.result
)
private func procedure_positive_left(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_positive_left.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try positive(
        left: arg_0
    )
    return type_positive_left.result.box(value: result, in: handlerEnv)
}

// negative {left}
private let type_negative_left = (
    param_0: (Symbol("left"), AsNumber()),
    result: AsNumber()
)
private let interface_negative_left = HandlerInterface(
    name: "negative",
    parameters: [
        (type_negative_left.param_0.0, "left", type_negative_left.param_0.1),
    ],
    result: type_negative_left.result
)
private func procedure_negative_left(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_negative_left.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try negative(
        left: arg_0
    )
    return type_negative_left.result.box(value: result, in: handlerEnv)
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

// is_same_as {left, right}
private let type_isSameAs_left_right = (
    param_0: (Symbol("left"), AsString()),
    param_1: (Symbol("right"), AsString()),
    result: asBool
)
private let interface_isSameAs_left_right = HandlerInterface(
    name: "is_same_as",
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

// is_not_same_as {left, right}
private let type_isNotSameAs_left_right = (
    param_0: (Symbol("left"), AsString()),
    param_1: (Symbol("right"), AsString()),
    result: asBool
)
private let interface_isNotSameAs_left_right = HandlerInterface(
    name: "is_not_same_as",
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

// is_a {value, coercion}
private let type_isA_value_coercion = (
    param_0: (Symbol("value"), AsOptional(AsValue())),
    param_1: (Symbol("coercion"), AsCoercion()),
    result: asBool
)
private let interface_isA_value_coercion = HandlerInterface(
    name: "is_a",
    parameters: [
        (type_isA_value_coercion.param_0.0, "value", type_isA_value_coercion.param_0.1),
        (type_isA_value_coercion.param_1.0, "coercion", type_isA_value_coercion.param_1.1),
    ],
    result: type_isA_value_coercion.result
)
private func procedure_isA_value_coercion(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_isA_value_coercion.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isA_value_coercion.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = isA(
        value: arg_0,
        coercion: arg_1,
        commandEnv: commandEnv
    )
    return type_isA_value_coercion.result.box(value: result, in: handlerEnv)
}

// as {value, to}
private let type_coerce_value_to = (
    param_0: (Symbol("value"), AsOptional(AsValue())),
    param_1: (Symbol("to"), AsCoercion()),
    result: AsOptional(AsValue())
)
private let interface_coerce_value_to = HandlerInterface(
    name: "as",
    parameters: [
        (type_coerce_value_to.param_0.0, "value", type_coerce_value_to.param_0.1),
        (type_coerce_value_to.param_1.0, "coercion", type_coerce_value_to.param_1.1),
    ],
    result: type_coerce_value_to.result
)
private func procedure_coerce_value_to(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_coerce_value_to.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_coerce_value_to.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try coerce(
        value: arg_0,
        to: arg_1,
        commandEnv: commandEnv
    )
    return type_coerce_value_to.result.box(value: result, in: handlerEnv)
}

// to {handler}
private let type_defineCommandHandler_handler = (
    param_0: (Symbol("handler"), AsHandler()),
    result: AsHandler()
)
private let interface_defineCommandHandler_handler = HandlerInterface(
    name: "to",
    parameters: [
        (type_defineCommandHandler_handler.param_0.0, "handler", type_defineCommandHandler_handler.param_0.1),
    ],
    result: type_defineCommandHandler_handler.result
)
private func procedure_defineCommandHandler_handler(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_defineCommandHandler_handler.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try defineCommandHandler(
        handler: arg_0,
        commandEnv: commandEnv
    )
    return type_defineCommandHandler_handler.result.box(value: result, in: handlerEnv)
}

// when {handler}
private let type_defineEventHandler_handler = (
    param_0: (Symbol("handler"), AsHandler()),
    result: AsHandler()
)
private let interface_defineEventHandler_handler = HandlerInterface(
    name: "when",
    parameters: [
        (type_defineEventHandler_handler.param_0.0, "handler", type_defineEventHandler_handler.param_0.1),
    ],
    result: type_defineEventHandler_handler.result
)
private func procedure_defineEventHandler_handler(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_defineEventHandler_handler.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try defineEventHandler(
        handler: arg_0,
        commandEnv: commandEnv
    )
    return type_defineEventHandler_handler.result.box(value: result, in: handlerEnv)
}

// set {name, to}
private let type_set_name_to = (
    param_0: (Symbol("name"), AsSymbol()),
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

// if {condition, action}
private let type_ifTest_condition_action = (
    param_0: (Symbol("condition"), asBool),
    param_1: (Symbol("action"), asIs),
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

// while {condition, action}
private let type_whileRepeat_condition_action = (
    param_0: (Symbol("condition"), asBool),
    param_1: (Symbol("action"), asIs),
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

// repeat {action, condition}
private let type_repeatWhile_action_condition = (
    param_0: (Symbol("action"), asIs),
    param_1: (Symbol("condition"), asBool),
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

// tell {target, action}
private let type_tell_target_action = (
    param_0: (Symbol("target"), AsValue()),
    param_1: (Symbol("action"), asIs),
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



public func stdlib_loadHandlers(into env: Environment) {
    env.define(interface_exponent_left_right, procedure_exponent_left_right)
    env.define(interface_positive_left, procedure_positive_left)
    env.define(interface_negative_left, procedure_negative_left)
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
    env.define(interface_joinValues_left_right, procedure_joinValues_left_right)
    env.define(interface_uppercase_text, procedure_uppercase_text)
    env.define(interface_lowercase_text, procedure_lowercase_text)
    env.define(interface_formatCode_value, procedure_formatCode_value)
    env.define(interface_isA_value_coercion, procedure_isA_value_coercion)
    env.define(interface_coerce_value_to, procedure_coerce_value_to)
    env.define(interface_defineCommandHandler_handler, procedure_defineCommandHandler_handler)
    env.define(interface_defineEventHandler_handler, procedure_defineEventHandler_handler)
    env.define(interface_set_name_to, procedure_set_name_to)
    env.define(interface_ifTest_condition_action, procedure_ifTest_condition_action)
    env.define(interface_elseTest_left_right, procedure_elseTest_left_right)
    env.define(interface_whileRepeat_condition_action, procedure_whileRepeat_condition_action)
    env.define(interface_repeatWhile_action_condition, procedure_repeatWhile_action_condition)
    env.define(interface_tell_target_action, procedure_tell_target_action)
}
