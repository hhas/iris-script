//
//  stdlib_handlers.swift
//  iris-lang
//

// code-generated bridge

import Foundation


let leftParameterLabel = Name("left")
let rightParameterLabel = Name("right")



// exponent (left, right)
let type_exponent_left_right = (
    param_0: (leftParameterLabel, asNumber),
    param_1: (rightParameterLabel, asNumber),
    result: asNumber
)
let interface_exponent_left_right = HandlerInterface(
    name: "exponent",
    parameters: [
        (type_exponent_left_right.param_0.0, nullSymbol, type_exponent_left_right.param_0.1),
        (type_exponent_left_right.param_1.0, nullSymbol, type_exponent_left_right.param_1.1),
    ],
    result: type_exponent_left_right.result
)
func function_exponent_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    // TO DO: separate matching from unboxing? [yes] (otherwise, an unknown argument label in middle of argument list will cause subsequent parameters to be assigned nullValue, typically causing handler to throw a type error rather than an unknown argument error); furthermore, how do we decompose these wrapper functions to enable argument matching and partial memoization on first use? (bear in mind that some optimizations will be easier to do via native->swiftc)
    let arg_0 = try command.swiftValue(at: &index, for: type_exponent_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_exponent_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try exponent(
        left: arg_0,
        right: arg_1
    )
    return type_exponent_left_right.result.box(value: result, in: handlerEnv)
}


// positive (left)
let type_positive_left = (
    param_0: (label: leftParameterLabel, coercion: asNumber),
    result: asNumber
)
let interface_positive_left = HandlerInterface(
    name: "positive",
    parameters: [
        (type_positive_left.param_0.label, nullSymbol, type_positive_left.param_0.coercion),
    ],
    result: type_positive_left.result
)
func function_positive_left(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_positive_left.param_0, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try positive(
        left: arg_0
    )
    return type_positive_left.result.box(value: result, in: handlerEnv)
}


// negative (left)
let type_negative_left = (
    param_0: (label: leftParameterLabel, coercion: asNumber),
    result: asNumber
)
let interface_negative_left = HandlerInterface(
    name: "negative",
    parameters: [
        (type_negative_left.param_0.label, nullSymbol, type_negative_left.param_0.coercion),
    ],
    result: type_negative_left.result
)
func function_negative_left(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_negative_left.param_0, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try negative(
        left: arg_0
    )
    return type_negative_left.result.box(value: result, in: handlerEnv)
}




// + (left, right)
let type_add_left_right = (
    param_0: (label: leftParameterLabel, coercion: asNumber),
    param_1: (label: rightParameterLabel, coercion: asNumber),
    result: asNumber
)
let interface_add_left_right = HandlerInterface(
    name: "+",
    parameters: [
        (type_add_left_right.param_0.label, nullSymbol, type_add_left_right.param_0.coercion),
        (type_add_left_right.param_1.label, nullSymbol, type_add_left_right.param_1.coercion),
    ],
    result: type_add_left_right.result
)
func function_add_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_add_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_add_left_right.param_1, in: commandEnv)
    if index + 1 < command.arguments.count { throw UnknownArgumentError(at: index, of: command) }
    let result = try add(
        left: arg_0,
        right: arg_1
    )
    return type_add_left_right.result.box(value: result, in: handlerEnv)
}


// - (left, right)
let type_subtract_left_right = (
    param_0: (label: leftParameterLabel, coercion: asNumber),
    param_1: (label: rightParameterLabel, coercion: asNumber),
    result: asNumber
)
let interface_subtract_left_right = HandlerInterface(
    name: "-",
    parameters: [
        (type_subtract_left_right.param_0.label, nullSymbol, type_subtract_left_right.param_0.coercion),
        (type_subtract_left_right.param_1.label, nullSymbol, type_subtract_left_right.param_1.coercion),
    ],
    result: type_subtract_left_right.result
)
func function_subtract_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_subtract_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_subtract_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try subtract(
        left: arg_0,
        right: arg_1
    )
    return type_subtract_left_right.result.box(value: result, in: handlerEnv)
}


// * (left, right)
let type_multiply_left_right = (
    param_0: (label: leftParameterLabel, coercion: asNumber),
    param_1: (label: rightParameterLabel, coercion: asNumber),
    result: asNumber
)
let interface_multiply_left_right = HandlerInterface(
    name: "*",
    parameters: [
        ("left", nullSymbol, type_multiply_left_right.param_0.coercion),
        ("right", nullSymbol, type_multiply_left_right.param_1.coercion),
    ],
    result: type_multiply_left_right.result
)
func function_multiply_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_multiply_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_multiply_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try multiply(
        left: arg_0,
        right: arg_1
    )
    return type_multiply_left_right.result.box(value: result, in: handlerEnv)
}


// / (left, right)
let type_divide_left_right = (
    param_0: (label: leftParameterLabel, coercion: asNumber),
    param_1: (label: rightParameterLabel, coercion: asNumber),
    result: asNumber
)
let interface_divide_left_right = HandlerInterface(
    name: "/",
    parameters: [
        ("left", nullSymbol, type_divide_left_right.param_0.coercion),
        ("right", nullSymbol, type_divide_left_right.param_1.coercion),
    ],
    result: type_divide_left_right.result
)
func function_divide_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_divide_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_divide_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try divide(
        left: arg_0,
        right: arg_1
    )
    return type_divide_left_right.result.box(value: result, in: handlerEnv)
}


// div (left, right)
let type_div_left_right = (
    param_0: (label: leftParameterLabel, coercion: asDouble),
    param_1: (label: rightParameterLabel, coercion: asDouble),
    result: asDouble
)
let interface_div_left_right = HandlerInterface(
    name: "div",
    parameters: [
        ("left", nullSymbol, type_div_left_right.param_0.coercion),
        ("right", nullSymbol, type_div_left_right.param_1.coercion),
    ],
    result: type_div_left_right.result
)
func function_div_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_div_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_div_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try div(
        left: arg_0,
        right: arg_1
    )
    return type_div_left_right.result.box(value: result, in: handlerEnv)
}


// mod (left, right)
let type_mod_left_right = (
    param_0: (label: leftParameterLabel, coercion: asDouble),
    param_1: (label: rightParameterLabel, coercion: asDouble),
    result: asDouble
)
let interface_mod_left_right = HandlerInterface(
    name: "mod",
    parameters: [
        ("left", nullSymbol, type_mod_left_right.param_0.coercion),
        ("right", nullSymbol, type_mod_left_right.param_1.coercion),
    ],
    result: type_mod_left_right.result
)
func function_mod_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_mod_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_mod_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try mod(
        left: arg_0,
        right: arg_1
    )
    return type_mod_left_right.result.box(value: result, in: handlerEnv)
}


// < (left, right)
let type_isLessThan_left_right = (
    param_0: (label: leftParameterLabel, coercion: asDouble),
    param_1: (label: rightParameterLabel, coercion: asDouble),
    result: asBool
)
let interface_isLessThan_left_right = HandlerInterface(
    name: "<",
    parameters: [
        ("left", nullSymbol, type_isLessThan_left_right.param_0.coercion),
        ("right", nullSymbol, type_isLessThan_left_right.param_1.coercion),
    ],
    result: type_isLessThan_left_right.result
)
func function_isLessThan_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_isLessThan_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isLessThan_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = isLessThan(
        left: arg_0,
        right: arg_1
    )
    return type_isLessThan_left_right.result.box(value: result, in: handlerEnv)
}


// <= (left, right)
let type_isLessThanOrEqualTo_left_right = (
    param_0: (label: leftParameterLabel, coercion: asDouble),
    param_1: (label: rightParameterLabel, coercion: asDouble),
    result: asBool
)
let interface_isLessThanOrEqualTo_left_right = HandlerInterface(
    name: "<=",
    parameters: [
        ("left", nullSymbol, type_isLessThanOrEqualTo_left_right.param_0.coercion),
        ("right", nullSymbol, type_isLessThanOrEqualTo_left_right.param_1.coercion),
    ],
    result: type_isLessThanOrEqualTo_left_right.result
)
func function_isLessThanOrEqualTo_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_isLessThanOrEqualTo_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isLessThanOrEqualTo_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = isLessThanOrEqualTo(
        left: arg_0,
        right: arg_1
    )
    return type_isLessThanOrEqualTo_left_right.result.box(value: result, in: handlerEnv)
}


// == (left, right)
let type_isEqualTo_left_right = (
    param_0: (label: leftParameterLabel, coercion: asDouble),
    param_1: (label: rightParameterLabel, coercion: asDouble),
    result: asBool
)
let interface_isEqualTo_left_right = HandlerInterface(
    name: "==",
    parameters: [
        ("left", nullSymbol, type_isEqualTo_left_right.param_0.coercion),
        ("right", nullSymbol, type_isEqualTo_left_right.param_1.coercion),
    ],
    result: type_isEqualTo_left_right.result
)
func function_isEqualTo_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_isEqualTo_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isEqualTo_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = isEqualTo(
        left: arg_0,
        right: arg_1
    )
    return type_isEqualTo_left_right.result.box(value: result, in: handlerEnv)
}


// != (left, right)
let type_isNotEqualTo_left_right = (
    param_0: (label: leftParameterLabel, coercion: asDouble),
    param_1: (label: rightParameterLabel, coercion: asDouble),
    result: asBool
)
let interface_isNotEqualTo_left_right = HandlerInterface(
    name: "!=",
    parameters: [
        ("left", nullSymbol, type_isNotEqualTo_left_right.param_0.coercion),
        ("right", nullSymbol, type_isNotEqualTo_left_right.param_1.coercion),
    ],
    result: type_isNotEqualTo_left_right.result
)
func function_isNotEqualTo_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_isNotEqualTo_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isNotEqualTo_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = isNotEqualTo(
        left: arg_0,
        right: arg_1
    )
    return type_isNotEqualTo_left_right.result.box(value: result, in: handlerEnv)
}


// > (left, right)
let type_isGreaterThan_left_right = (
    param_0: (label: leftParameterLabel, coercion: asDouble),
    param_1: (label: rightParameterLabel, coercion: asDouble),
    result: asBool
)
let interface_isGreaterThan_left_right = HandlerInterface(
    name: ">",
    parameters: [
        ("left", nullSymbol, type_isGreaterThan_left_right.param_0.coercion),
        ("right", nullSymbol, type_isGreaterThan_left_right.param_1.coercion),
    ],
    result: type_isGreaterThan_left_right.result
)
func function_isGreaterThan_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_isGreaterThan_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isGreaterThan_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = isGreaterThan(
        left: arg_0,
        right: arg_1
    )
    return type_isGreaterThan_left_right.result.box(value: result, in: handlerEnv)
}


// >= (left, right)
let type_isGreaterThanOrEqualTo_left_right = (
    param_0: (label: leftParameterLabel, coercion: asDouble),
    param_1: (label: rightParameterLabel, coercion: asDouble),
    result: asBool
)
let interface_isGreaterThanOrEqualTo_left_right = HandlerInterface(
    name: ">=",
    parameters: [
        (type_isGreaterThanOrEqualTo_left_right.param_0.label, nullSymbol, type_isGreaterThanOrEqualTo_left_right.param_0.coercion),
        (type_isGreaterThanOrEqualTo_left_right.param_1.label, nullSymbol, type_isGreaterThanOrEqualTo_left_right.param_1.coercion),
    ],
    result: type_isGreaterThanOrEqualTo_left_right.result
)
func function_isGreaterThanOrEqualTo_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_isGreaterThanOrEqualTo_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isGreaterThanOrEqualTo_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = isGreaterThanOrEqualTo(
        left: arg_0,
        right: arg_1
    )
    return type_isGreaterThanOrEqualTo_left_right.result.box(value: result, in: handlerEnv)
}


// NOT (right)
let type_NOT_right = (
    param_0: (label: rightParameterLabel, coercion: asBool),
    result: asBool
)
let interface_NOT_right = HandlerInterface(
    name: "NOT",
    parameters: [
        ("right", nullSymbol, type_NOT_right.param_0.coercion),
    ],
    result: type_NOT_right.result
)
func function_NOT_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_NOT_right.param_0, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = NOT(
        right: arg_0
    )
    return type_NOT_right.result.box(value: result, in: handlerEnv)
}


// AND (left, right)
let type_AND_left_right = (
    param_0: (label: leftParameterLabel, coercion: asBool),
    param_1: (label: rightParameterLabel, coercion: asBool),
    result: asBool
)
let interface_AND_left_right = HandlerInterface(
    name: "AND",
    parameters: [
        (type_AND_left_right.param_0.label, nullSymbol, type_AND_left_right.param_0.coercion),
        (type_AND_left_right.param_1.label, nullSymbol, type_AND_left_right.param_1.coercion),
    ],
    result: type_AND_left_right.result
)
func function_AND_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_AND_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_AND_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = AND(
        left: arg_0,
        right: arg_1
    )
    return type_AND_left_right.result.box(value: result, in: handlerEnv)
}


// OR (left, right)
let type_OR_left_right = (
    param_0: (label: leftParameterLabel, coercion: asBool),
    param_1: (label: rightParameterLabel, coercion: asBool),
    result: asBool
)
let interface_OR_left_right = HandlerInterface(
    name: "OR",
    parameters: [
        (type_OR_left_right.param_0.label, nullSymbol, type_OR_left_right.param_0.coercion),
        (type_OR_left_right.param_1.label, nullSymbol, type_OR_left_right.param_1.coercion),
    ],
    result: type_OR_left_right.result
)
func function_OR_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_OR_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_OR_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = OR(
        left: arg_0,
        right: arg_1
    )
    return type_OR_left_right.result.box(value: result, in: handlerEnv)
}


// XOR (left, right)
let type_XOR_left_right = (
    param_0: (label: leftParameterLabel, coercion: asBool),
    param_1: (label: rightParameterLabel, coercion: asBool),
    result: asBool
)
let interface_XOR_left_right = HandlerInterface(
    name: "XOR",
    parameters: [
        (type_XOR_left_right.param_0.label, nullSymbol, type_XOR_left_right.param_0.coercion),
        (type_XOR_left_right.param_1.label, nullSymbol, type_XOR_left_right.param_1.coercion),
    ],
    result: type_XOR_left_right.result
)
func function_XOR_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_XOR_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_XOR_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = XOR(
        left: arg_0,
        right: arg_1
    )
    return type_XOR_left_right.result.box(value: result, in: handlerEnv)
}




// TO DO: following need renamed (isBefore, isSameAs, etc)

// lt (left, right)
private let type_lt_left_right = (
    param_0: (label: leftParameterLabel, coercion: asString),
    param_1: (label: rightParameterLabel, coercion: asString),
    result: asBool
)
private let interface_lt_left_right = HandlerInterface(
    name: "lt",
    parameters: [
        (type_lt_left_right.param_0.label, nullSymbol, type_lt_left_right.param_0.coercion),
        (type_lt_left_right.param_1.label, nullSymbol, type_lt_left_right.param_1.coercion),
    ],
    result: type_lt_left_right.result
)
private func function_lt_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_lt_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_lt_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try lt(
        left: arg_0,
        right: arg_1
    )
    return type_lt_left_right.result.box(value: result, in: handlerEnv)
}


// le (left, right)
private let type_le_left_right = (
    param_0: (label: leftParameterLabel, coercion: asString),
    param_1: (label: rightParameterLabel, coercion: asString),
    result: asBool
)
private let interface_le_left_right = HandlerInterface(
    name: "le",
    parameters: [
        (type_le_left_right.param_0.label, nullSymbol, type_le_left_right.param_0.coercion),
        (type_le_left_right.param_1.label, nullSymbol, type_le_left_right.param_1.coercion),
    ],
    result: type_le_left_right.result
)
private func function_le_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_le_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_le_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try le(
        left: arg_0,
        right: arg_1
    )
    return type_le_left_right.result.box(value: result, in: handlerEnv)
}


// eq (left, right)
private let type_eq_left_right = (
    param_0: (label: leftParameterLabel, coercion: asString),
    param_1: (label: rightParameterLabel, coercion: asString),
    result: asBool
)
private let interface_eq_left_right = HandlerInterface(
    name: "eq",
    parameters: [
        ("left", nullSymbol, type_eq_left_right.param_0.coercion),
        ("right", nullSymbol, type_eq_left_right.param_1.coercion),
    ],
    result: type_eq_left_right.result
)
private func function_eq_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_eq_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_eq_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try eq(
        left: arg_0,
        right: arg_1
    )
    return type_eq_left_right.result.box(value: result, in: handlerEnv)
}


// ne (left, right)
private let type_ne_left_right = (
    param_0: (label: leftParameterLabel, coercion: asString),
    param_1: (label: rightParameterLabel, coercion: asString),
    result: asBool
)
private let interface_ne_left_right = HandlerInterface(
    name: "ne",
    parameters: [
        ("left", nullSymbol, type_ne_left_right.param_0.coercion),
        ("right", nullSymbol, type_ne_left_right.param_1.coercion),
    ],
    result: type_ne_left_right.result
)
private func function_ne_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_ne_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_ne_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try ne(
        left: arg_0,
        right: arg_1
    )
    return type_ne_left_right.result.box(value: result, in: handlerEnv)
}


// gt (left, right)
private let type_gt_left_right = (
    param_0: (label: leftParameterLabel, coercion: asString),
    param_1: (label: rightParameterLabel, coercion: asString),
    result: asBool
)
private let interface_gt_left_right = HandlerInterface(
    name: "gt",
    parameters: [
        ("left", nullSymbol, type_gt_left_right.param_0.coercion),
        ("right", nullSymbol, type_gt_left_right.param_1.coercion),
    ],
    result: type_gt_left_right.result
)
private func function_gt_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_gt_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_gt_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try gt(
        left: arg_0,
        right: arg_1
    )
    return type_gt_left_right.result.box(value: result, in: handlerEnv)
}


// ge (left, right)
private let type_ge_left_right = (
    param_0: (label: leftParameterLabel, coercion: asString),
    param_1: (label: rightParameterLabel, coercion: asString),
    result: asBool
)
private let interface_ge_left_right = HandlerInterface(
    name: "ge",
    parameters: [
        (type_ge_left_right.param_0.label, nullSymbol, type_ge_left_right.param_0.coercion),
        (type_ge_left_right.param_1.label, nullSymbol, type_ge_left_right.param_1.coercion),
    ],
    result: type_ge_left_right.result
)
private func function_ge_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_ge_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_ge_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try ge(
        left: arg_0,
        right: arg_1
    )
    return type_ge_left_right.result.box(value: result, in: handlerEnv)
}


// is_a (value, of_type)
private let type_isA_value_ofType = (
    param_0: (label: Name("value"), coercion: asValue),
    param_1: (label: Name("of_type"), coercion: asCoercion),
    result: asBool
)
private let interface_isA_value_ofType = HandlerInterface(
    name: "is_a",
    parameters: [
        (type_isA_value_ofType.param_0.label, nullSymbol, type_isA_value_ofType.param_0.coercion),
        (type_isA_value_ofType.param_1.label, nullSymbol, type_isA_value_ofType.param_1.coercion),
    ],
    result: type_isA_value_ofType.result
)
private func function_isA_value_ofType(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_isA_value_ofType.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_isA_value_ofType.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = isA(
        value: arg_0,
        ofType: arg_1
    )
    return type_isA_value_ofType.result.box(value: result, in: handlerEnv)
}


// & (left, right)
private let type_joinValues_left_right = (
    param_0: (label: leftParameterLabel, coercion: asString),
    param_1: (label: rightParameterLabel, coercion: asString),
    result: asString
)
private let interface_joinValues_left_right = HandlerInterface(
    name: "&",
    parameters: [
        (type_joinValues_left_right.param_0.label, nullSymbol, type_joinValues_left_right.param_0.coercion),
        (type_joinValues_left_right.param_1.label, nullSymbol, type_joinValues_left_right.param_1.coercion),
    ],
    result: type_joinValues_left_right.result
)
private func function_joinValues_left_right(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_joinValues_left_right.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_joinValues_left_right.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try joinValues(
        left: arg_0,
        right: arg_1
    )
    return type_joinValues_left_right.result.box(value: result, in: handlerEnv)
}


// show (value)
private let type_show_value = (
    param_0: (label: Name("value"), coercion: asValue),
    result: asNothing
)
let interface_show_value = HandlerInterface(
    name: "show",
    parameters: [
        (type_show_value.param_0.label, nullSymbol, type_show_value.param_0.coercion),
    ],
    result: type_show_value.result
)
func function_show_value(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_show_value.param_0, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    show(
        value: arg_0
    )
    return nullValue
}




// define_handler (name, parameters, return_type, action, is_event_handler)
let type_defineHandler_interface_action_commandEnv = (
    // TO DO: reduce `name+parameters+result` to single parameter of type asHandlerInterface?
    param_0: (label: Name("interface"), coercion: asHandlerInterface),
    param_1: (label: Name("action"), coercion: asBlock),
    result: asNothing
)
let interface_defineHandler_interface_action_commandEnv = HandlerInterface(
    name: "define_handler",
    parameters: [
        (type_defineHandler_interface_action_commandEnv.param_0.label, nullSymbol, type_defineHandler_interface_action_commandEnv.param_0.coercion),
        (type_defineHandler_interface_action_commandEnv.param_1.label, nullSymbol, type_defineHandler_interface_action_commandEnv.param_1.coercion),
 
    ],
    result: type_defineHandler_interface_action_commandEnv.result
)
func function_defineHandler_interface_action_commandEnv(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_defineHandler_interface_action_commandEnv.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_defineHandler_interface_action_commandEnv.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    try defineHandler(
        interface: arg_0,
        action: arg_1,
        commandEnv: commandEnv
    )
    return nullValue
}




func stdlib_loadHandlers(into env: Environment) {
    
    //
    
    // caution: this creates refcycles between environment and its handlers, but this shouldn't be an issue as libraries are never unloaded (while refcycles can be broken by emptying environment's frame dictionary prior to discarding it, unloading assumes none of the library's handlers have been captured elsewhere in runtime's current state; if they have, that'll 1. prevent complete unloading and 2. result in undefined behavior if those handlers are subsequently invoked); this could be a problem if in future we want to implement hot reloading of libraries in long-running processes (though that is a Hard Problem in any language)
    env.define(interface_exponent_left_right, function_exponent_left_right)
    env.define(interface_positive_left, function_positive_left)
    env.define(interface_negative_left, function_negative_left)
    env.define(interface_add_left_right, function_add_left_right)
    env.define(interface_subtract_left_right, function_subtract_left_right)
    env.define(interface_multiply_left_right, function_multiply_left_right)
    env.define(interface_divide_left_right, function_divide_left_right)
    env.define(interface_div_left_right, function_div_left_right)
    env.define(interface_mod_left_right, function_mod_left_right)
    env.define(interface_isLessThan_left_right, function_isLessThan_left_right)
    env.define(interface_isLessThanOrEqualTo_left_right, function_isLessThanOrEqualTo_left_right)
    env.define(interface_isEqualTo_left_right, function_isEqualTo_left_right)
    env.define(interface_isNotEqualTo_left_right, function_isNotEqualTo_left_right)
    env.define(interface_isGreaterThan_left_right, function_isGreaterThan_left_right)
    env.define(interface_isGreaterThanOrEqualTo_left_right, function_isGreaterThanOrEqualTo_left_right)
    env.define(interface_NOT_right, function_NOT_right)
    env.define(interface_AND_left_right, function_AND_left_right)
    env.define(interface_OR_left_right, function_OR_left_right)
    env.define(interface_XOR_left_right, function_XOR_left_right)

    
    env.define(interface_lt_left_right, function_lt_left_right)
    env.define(interface_le_left_right, function_le_left_right)
    env.define(interface_eq_left_right, function_eq_left_right)
    env.define(interface_ne_left_right, function_ne_left_right)
    env.define(interface_gt_left_right, function_gt_left_right)
    env.define(interface_ge_left_right, function_ge_left_right)
    env.define(interface_isA_value_ofType, function_isA_value_ofType)
    env.define(interface_joinValues_left_right, function_joinValues_left_right)
    env.define(interface_show_value, function_show_value)

    env.define(interface_defineHandler_interface_action_commandEnv, function_defineHandler_interface_action_commandEnv)
}
