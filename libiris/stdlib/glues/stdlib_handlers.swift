//
//  stdlib_handlers.swift
//
//  Bridging code for primitive handlers. This file is auto-generated; do not edit directly.
//

import Foundation

// & {left, right}
private let type_joinValues_left_right = (
    name: Symbol("&"),
    param_0: (Symbol("left"), Symbol("left"), AsString()),
    param_1: (Symbol("right"), Symbol("right"), AsString()),
    result: AsString()
)
private let interface_joinValues_left_right = HandlerInterface(
    name: type_joinValues_left_right.name,
    parameters: [
		type_joinValues_left_right.param_0,
		type_joinValues_left_right.param_1,
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

// * {left, right}
private let type_multiply_left_right = (
    name: Symbol("*"),
    param_0: (Symbol("left"), Symbol("left"), AsNumber()),
    param_1: (Symbol("right"), Symbol("right"), AsNumber()),
    result: AsNumber()
)
private let interface_multiply_left_right = HandlerInterface(
    name: type_multiply_left_right.name,
    parameters: [
		type_multiply_left_right.param_0,
		type_multiply_left_right.param_1,
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

// + {left, right}
private let type_add_left_right = (
    name: Symbol("+"),
    param_0: (Symbol("left"), Symbol("left"), AsNumber()),
    param_1: (Symbol("right"), Symbol("right"), AsNumber()),
    result: AsNumber()
)
private let interface_add_left_right = HandlerInterface(
    name: type_add_left_right.name,
    parameters: [
		type_add_left_right.param_0,
		type_add_left_right.param_1,
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
    name: Symbol("-"),
    param_0: (Symbol("left"), Symbol("left"), AsNumber()),
    param_1: (Symbol("right"), Symbol("right"), AsNumber()),
    result: AsNumber()
)
private let interface_subtract_left_right = HandlerInterface(
    name: type_subtract_left_right.name,
    parameters: [
		type_subtract_left_right.param_0,
		type_subtract_left_right.param_1,
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

// / {left, right}
private let type_divide_left_right = (
    name: Symbol("/"),
    param_0: (Symbol("left"), Symbol("left"), AsNumber()),
    param_1: (Symbol("right"), Symbol("right"), AsNumber()),
    result: AsNumber()
)
private let interface_divide_left_right = HandlerInterface(
    name: type_divide_left_right.name,
    parameters: [
		type_divide_left_right.param_0,
		type_divide_left_right.param_1,
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

// < {left, right}
private let type_isLess_left_right = (
    name: Symbol("<"),
    param_0: (Symbol("left"), Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), Symbol("right"), AsDouble()),
    result: asBool
)
private let interface_isLess_left_right = HandlerInterface(
    name: type_isLess_left_right.name,
    parameters: [
		type_isLess_left_right.param_0,
		type_isLess_left_right.param_1,
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

// = {left, right}
private let type_isEqual_left_right = (
    name: Symbol("="),
    param_0: (Symbol("left"), Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), Symbol("right"), AsDouble()),
    result: asBool
)
private let interface_isEqual_left_right = HandlerInterface(
    name: type_isEqual_left_right.name,
    parameters: [
		type_isEqual_left_right.param_0,
		type_isEqual_left_right.param_1,
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

// > {left, right}
private let type_isGreater_left_right = (
    name: Symbol(">"),
    param_0: (Symbol("left"), Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), Symbol("right"), AsDouble()),
    result: asBool
)
private let interface_isGreater_left_right = HandlerInterface(
    name: type_isGreater_left_right.name,
    parameters: [
		type_isGreater_left_right.param_0,
		type_isGreater_left_right.param_1,
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

// AND {left, right}
private let type_AND_left_right = (
    name: Symbol("AND"),
    param_0: (Symbol("left"), Symbol("left"), asBool),
    param_1: (Symbol("right"), Symbol("right"), asBool),
    result: asBool
)
private let interface_AND_left_right = HandlerInterface(
    name: type_AND_left_right.name,
    parameters: [
		type_AND_left_right.param_0,
		type_AND_left_right.param_1,
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

// NOT {right}
private let type_NOT_right = (
    name: Symbol("NOT"),
    param_0: (Symbol("right"), Symbol("right"), asBool),
    result: asBool
)
private let interface_NOT_right = HandlerInterface(
    name: type_NOT_right.name,
    parameters: [
		type_NOT_right.param_0,
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

// OR {left, right}
private let type_OR_left_right = (
    name: Symbol("OR"),
    param_0: (Symbol("left"), Symbol("left"), asBool),
    param_1: (Symbol("right"), Symbol("right"), asBool),
    result: asBool
)
private let interface_OR_left_right = HandlerInterface(
    name: type_OR_left_right.name,
    parameters: [
		type_OR_left_right.param_0,
		type_OR_left_right.param_1,
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
    name: Symbol("XOR"),
    param_0: (Symbol("left"), Symbol("left"), asBool),
    param_1: (Symbol("right"), Symbol("right"), asBool),
    result: asBool
)
private let interface_XOR_left_right = HandlerInterface(
    name: type_XOR_left_right.name,
    parameters: [
		type_XOR_left_right.param_0,
		type_XOR_left_right.param_1,
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

// ^ {left, right}
private let type_exponent_left_right = (
    name: Symbol("^"),
    param_0: (Symbol("left"), Symbol("left"), AsNumber()),
    param_1: (Symbol("right"), Symbol("right"), AsNumber()),
    result: AsNumber()
)
private let interface_exponent_left_right = HandlerInterface(
    name: type_exponent_left_right.name,
    parameters: [
		type_exponent_left_right.param_0,
		type_exponent_left_right.param_1,
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

// after {element_type, expression}
private let type_afterElement_elementType_expression = (
    name: Symbol("after"),
    param_0: (Symbol("element_type"), Symbol("element_type"), AsLiteralName()),
    param_1: (Symbol("expression"), Symbol("expression"), asIs),
    result: asIs
)
private let interface_afterElement_elementType_expression = HandlerInterface(
    name: type_afterElement_elementType_expression.name,
    parameters: [
		type_afterElement_elementType_expression.param_0,
		type_afterElement_elementType_expression.param_1,
    ],
    result: type_afterElement_elementType_expression.result
)
private func procedure_afterElement_elementType_expression(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_afterElement_elementType_expression.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_afterElement_elementType_expression.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = afterElement(
    	elementType: arg_0,
    	expression: arg_1
    )
    return type_afterElement_elementType_expression.result.box(value: result, in: handlerEnv)
}

// any {element_type}
private let type_randomElement_elementType = (
    name: Symbol("any"),
    param_0: (Symbol("element_type"), Symbol("element_type"), AsLiteralName()),
    result: asIs
)
private let interface_randomElement_elementType = HandlerInterface(
    name: type_randomElement_elementType.name,
    parameters: [
		type_randomElement_elementType.param_0,
    ],
    result: type_randomElement_elementType.result
)
private func procedure_randomElement_elementType(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_randomElement_elementType.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = randomElement(
    	elementType: arg_0
    )
    return type_randomElement_elementType.result.box(value: result, in: handlerEnv)
}

// app {bundle_identifier}
private let type_Application_bundleIdentifier = (
    name: Symbol("app"),
    param_0: (Symbol("bundle_identifier"), Symbol("bundle_identifier"), AsString()),
    result: AsValue()
)
private let interface_Application_bundleIdentifier = HandlerInterface(
    name: type_Application_bundleIdentifier.name,
    parameters: [
		type_Application_bundleIdentifier.param_0,
    ],
    result: type_Application_bundleIdentifier.result
)
private func procedure_Application_bundleIdentifier(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_Application_bundleIdentifier.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try Application(
    	bundleIdentifier: arg_0
    )
    return type_Application_bundleIdentifier.result.box(value: result, in: handlerEnv)
}

// as {value, coercion}
private let type_coerce_value_coercion = (
    name: Symbol("as"),
    param_0: (Symbol("value"), Symbol("value"), AsSwiftPrecis<AsOptional>(AsOptional(AsValue()), "anything")),
    param_1: (Symbol("coercion"), Symbol("coercion"), AsCoercion()),
    result: AsSwiftPrecis<AsOptional>(AsOptional(AsValue()), "anything")
)
private let interface_coerce_value_coercion = HandlerInterface(
    name: type_coerce_value_coercion.name,
    parameters: [
		type_coerce_value_coercion.param_0,
		type_coerce_value_coercion.param_1,
    ],
    result: type_coerce_value_coercion.result
)
private func procedure_coerce_value_coercion(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_coerce_value_coercion.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_coerce_value_coercion.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try coerce(
    	value: arg_0,
    	coercion: arg_1,
    	commandEnv: commandEnv
    )
    return type_coerce_value_coercion.result.box(value: result, in: handlerEnv)
}

// at {element_type, selector_data}
private let type_atSelector_elementType_selectorData = (
    name: Symbol("at"),
    param_0: (Symbol("element_type"), Symbol("element_type"), AsLiteralName()),
    param_1: (Symbol("selector_data"), Symbol("selector_data"), asIs),
    result: asIs
)
private let interface_atSelector_elementType_selectorData = HandlerInterface(
    name: type_atSelector_elementType_selectorData.name,
    parameters: [
		type_atSelector_elementType_selectorData.param_0,
		type_atSelector_elementType_selectorData.param_1,
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

// before {element_type, expression}
private let type_beforeElement_elementType_expression = (
    name: Symbol("before"),
    param_0: (Symbol("element_type"), Symbol("element_type"), AsLiteralName()),
    param_1: (Symbol("expression"), Symbol("expression"), asIs),
    result: asIs
)
private let interface_beforeElement_elementType_expression = HandlerInterface(
    name: type_beforeElement_elementType_expression.name,
    parameters: [
		type_beforeElement_elementType_expression.param_0,
		type_beforeElement_elementType_expression.param_1,
    ],
    result: type_beforeElement_elementType_expression.result
)
private func procedure_beforeElement_elementType_expression(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_beforeElement_elementType_expression.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_beforeElement_elementType_expression.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = beforeElement(
    	elementType: arg_0,
    	expression: arg_1
    )
    return type_beforeElement_elementType_expression.result.box(value: result, in: handlerEnv)
}

// beginning {}
private let type_insertAtBeginning_ = (
    name: Symbol("beginning"),
	_: (),
    result: asIs
)
private let interface_insertAtBeginning_ = HandlerInterface(
    name: type_insertAtBeginning_.name,
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

// begins_with {left, right}
private let type_beginsWith_left_right = (
    name: Symbol("begins_with"),
    param_0: (Symbol("left"), Symbol("left"), AsString()),
    param_1: (Symbol("right"), Symbol("right"), AsString()),
    result: asBool
)
private let interface_beginsWith_left_right = HandlerInterface(
    name: type_beginsWith_left_right.name,
    parameters: [
		type_beginsWith_left_right.param_0,
		type_beginsWith_left_right.param_1,
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

// contains {left, right}
private let type_contains_left_right = (
    name: Symbol("contains"),
    param_0: (Symbol("left"), Symbol("left"), AsString()),
    param_1: (Symbol("right"), Symbol("right"), AsString()),
    result: asBool
)
private let interface_contains_left_right = HandlerInterface(
    name: type_contains_left_right.name,
    parameters: [
		type_contains_left_right.param_0,
		type_contains_left_right.param_1,
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

// div {left, right}
private let type_div_left_right = (
    name: Symbol("div"),
    param_0: (Symbol("left"), Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), Symbol("right"), AsDouble()),
    result: AsDouble()
)
private let interface_div_left_right = HandlerInterface(
    name: type_div_left_right.name,
    parameters: [
		type_div_left_right.param_0,
		type_div_left_right.param_1,
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

// end {}
private let type_insertAtEnd_ = (
    name: Symbol("end"),
	_: (),
    result: asIs
)
private let interface_insertAtEnd_ = HandlerInterface(
    name: type_insertAtEnd_.name,
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

// ends_with {left, right}
private let type_endsWith_left_right = (
    name: Symbol("ends_with"),
    param_0: (Symbol("left"), Symbol("left"), AsString()),
    param_1: (Symbol("right"), Symbol("right"), AsString()),
    result: asBool
)
private let interface_endsWith_left_right = HandlerInterface(
    name: type_endsWith_left_right.name,
    parameters: [
		type_endsWith_left_right.param_0,
		type_endsWith_left_right.param_1,
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

// every {element_type}
private let type_allElements_elementType = (
    name: Symbol("every"),
    param_0: (Symbol("element_type"), Symbol("element_type"), AsLiteralName()),
    result: asIs
)
private let interface_allElements_elementType = HandlerInterface(
    name: type_allElements_elementType.name,
    parameters: [
		type_allElements_elementType.param_0,
    ],
    result: type_allElements_elementType.result
)
private func procedure_allElements_elementType(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_allElements_elementType.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = allElements(
    	elementType: arg_0
    )
    return type_allElements_elementType.result.box(value: result, in: handlerEnv)
}

// first {element_type}
private let type_firstElement_elementType = (
    name: Symbol("first"),
    param_0: (Symbol("element_type"), Symbol("element_type"), AsLiteralName()),
    result: asIs
)
private let interface_firstElement_elementType = HandlerInterface(
    name: type_firstElement_elementType.name,
    parameters: [
		type_firstElement_elementType.param_0,
    ],
    result: type_firstElement_elementType.result
)
private func procedure_firstElement_elementType(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_firstElement_elementType.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = firstElement(
    	elementType: arg_0
    )
    return type_firstElement_elementType.result.box(value: result, in: handlerEnv)
}

// format_code {value}
private let type_formatCode_value = (
    name: Symbol("format_code"),
    param_0: (Symbol("value"), Symbol("value"), AsSwiftPrecis<AsOptional>(AsOptional(AsValue()), "optional")),
    result: AsString()
)
private let interface_formatCode_value = HandlerInterface(
    name: type_formatCode_value.name,
    parameters: [
		type_formatCode_value.param_0,
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

// from {element_type, selector_data}
private let type_rangeSelector_elementType_selectorData = (
    name: Symbol("from"),
    param_0: (Symbol("element_type"), Symbol("element_type"), AsLiteralName()),
    param_1: (Symbol("selector_data"), Symbol("selector_data"), asIs),
    result: asIs
)
private let interface_rangeSelector_elementType_selectorData = HandlerInterface(
    name: type_rangeSelector_elementType_selectorData.name,
    parameters: [
		type_rangeSelector_elementType_selectorData.param_0,
		type_rangeSelector_elementType_selectorData.param_1,
    ],
    result: type_rangeSelector_elementType_selectorData.result
)
private func procedure_rangeSelector_elementType_selectorData(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_rangeSelector_elementType_selectorData.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_rangeSelector_elementType_selectorData.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try rangeSelector(
    	elementType: arg_0,
    	selectorData: arg_1,
    	commandEnv: commandEnv,
    	handlerEnv: handlerEnv
    )
    return type_rangeSelector_elementType_selectorData.result.box(value: result, in: handlerEnv)
}

// id {element_type, selector_data}
private let type_idSelector_elementType_selectorData = (
    name: Symbol("id"),
    param_0: (Symbol("element_type"), Symbol("element_type"), AsLiteralName()),
    param_1: (Symbol("selector_data"), Symbol("selector_data"), asIs),
    result: asIs
)
private let interface_idSelector_elementType_selectorData = HandlerInterface(
    name: type_idSelector_elementType_selectorData.name,
    parameters: [
		type_idSelector_elementType_selectorData.param_0,
		type_idSelector_elementType_selectorData.param_1,
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

// if {test, then, else}
private let type_ifTest_condition_action_alternativeAction = (
    name: Symbol("if"),
    param_0: (Symbol("test"), Symbol("condition"), asBool),
    param_1: (Symbol("then"), Symbol("action"), asIs),
    param_2: (Symbol("else"), Symbol("alternative_action"), asIs),
    result: AsSwiftPrecis<AsOptional>(AsOptional(AsValue()), "anything")
)
private let interface_ifTest_condition_action_alternativeAction = HandlerInterface(
    name: type_ifTest_condition_action_alternativeAction.name,
    parameters: [
		type_ifTest_condition_action_alternativeAction.param_0,
		type_ifTest_condition_action_alternativeAction.param_1,
		type_ifTest_condition_action_alternativeAction.param_2,
    ],
    result: type_ifTest_condition_action_alternativeAction.result
)
private func procedure_ifTest_condition_action_alternativeAction(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_ifTest_condition_action_alternativeAction.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_ifTest_condition_action_alternativeAction.param_1, in: commandEnv)
    let arg_2 = try command.swiftValue(at: &index, for: type_ifTest_condition_action_alternativeAction.param_2, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try ifTest(
    	condition: arg_0,
    	action: arg_1,
    	alternativeAction: arg_2,
    	commandEnv: commandEnv
    )
    return type_ifTest_condition_action_alternativeAction.result.box(value: result, in: handlerEnv)
}

// is_a {value, coercion}
private let type_isA_value_coercion = (
    name: Symbol("is_a"),
    param_0: (Symbol("value"), Symbol("value"), AsSwiftPrecis<AsOptional>(AsOptional(AsValue()), "anything")),
    param_1: (Symbol("coercion"), Symbol("coercion"), AsCoercion()),
    result: asBool
)
private let interface_isA_value_coercion = HandlerInterface(
    name: type_isA_value_coercion.name,
    parameters: [
		type_isA_value_coercion.param_0,
		type_isA_value_coercion.param_1,
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

// is_after {left, right}
private let type_isAfter_left_right = (
    name: Symbol("is_after"),
    param_0: (Symbol("left"), Symbol("left"), AsString()),
    param_1: (Symbol("right"), Symbol("right"), AsString()),
    result: asBool
)
private let interface_isAfter_left_right = HandlerInterface(
    name: type_isAfter_left_right.name,
    parameters: [
		type_isAfter_left_right.param_0,
		type_isAfter_left_right.param_1,
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

// is_before {left, right}
private let type_isBefore_left_right = (
    name: Symbol("is_before"),
    param_0: (Symbol("left"), Symbol("left"), AsString()),
    param_1: (Symbol("right"), Symbol("right"), AsString()),
    result: asBool
)
private let interface_isBefore_left_right = HandlerInterface(
    name: type_isBefore_left_right.name,
    parameters: [
		type_isBefore_left_right.param_0,
		type_isBefore_left_right.param_1,
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

// is_in {left, right}
private let type_isIn_left_right = (
    name: Symbol("is_in"),
    param_0: (Symbol("left"), Symbol("left"), AsString()),
    param_1: (Symbol("right"), Symbol("right"), AsString()),
    result: asBool
)
private let interface_isIn_left_right = HandlerInterface(
    name: type_isIn_left_right.name,
    parameters: [
		type_isIn_left_right.param_0,
		type_isIn_left_right.param_1,
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

// is_not_after {left, right}
private let type_isNotAfter_left_right = (
    name: Symbol("is_not_after"),
    param_0: (Symbol("left"), Symbol("left"), AsString()),
    param_1: (Symbol("right"), Symbol("right"), AsString()),
    result: asBool
)
private let interface_isNotAfter_left_right = HandlerInterface(
    name: type_isNotAfter_left_right.name,
    parameters: [
		type_isNotAfter_left_right.param_0,
		type_isNotAfter_left_right.param_1,
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

// is_not_before {left, right}
private let type_isNotBefore_left_right = (
    name: Symbol("is_not_before"),
    param_0: (Symbol("left"), Symbol("left"), AsString()),
    param_1: (Symbol("right"), Symbol("right"), AsString()),
    result: asBool
)
private let interface_isNotBefore_left_right = HandlerInterface(
    name: type_isNotBefore_left_right.name,
    parameters: [
		type_isNotBefore_left_right.param_0,
		type_isNotBefore_left_right.param_1,
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

// is_not_same_as {left, right}
private let type_isNotSameAs_left_right = (
    name: Symbol("is_not_same_as"),
    param_0: (Symbol("left"), Symbol("left"), AsString()),
    param_1: (Symbol("right"), Symbol("right"), AsString()),
    result: asBool
)
private let interface_isNotSameAs_left_right = HandlerInterface(
    name: type_isNotSameAs_left_right.name,
    parameters: [
		type_isNotSameAs_left_right.param_0,
		type_isNotSameAs_left_right.param_1,
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

// is_same_as {left, right}
private let type_isSameAs_left_right = (
    name: Symbol("is_same_as"),
    param_0: (Symbol("left"), Symbol("left"), AsString()),
    param_1: (Symbol("right"), Symbol("right"), AsString()),
    result: asBool
)
private let interface_isSameAs_left_right = HandlerInterface(
    name: type_isSameAs_left_right.name,
    parameters: [
		type_isSameAs_left_right.param_0,
		type_isSameAs_left_right.param_1,
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

// last {element_type}
private let type_lastElement_elementType = (
    name: Symbol("last"),
    param_0: (Symbol("element_type"), Symbol("element_type"), AsLiteralName()),
    result: asIs
)
private let interface_lastElement_elementType = HandlerInterface(
    name: type_lastElement_elementType.name,
    parameters: [
		type_lastElement_elementType.param_0,
    ],
    result: type_lastElement_elementType.result
)
private func procedure_lastElement_elementType(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_lastElement_elementType.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = lastElement(
    	elementType: arg_0
    )
    return type_lastElement_elementType.result.box(value: result, in: handlerEnv)
}

// lowercase {text}
private let type_lowercase_text = (
    name: Symbol("lowercase"),
    param_0: (Symbol("text"), Symbol("text"), AsString()),
    result: AsString()
)
private let interface_lowercase_text = HandlerInterface(
    name: type_lowercase_text.name,
    parameters: [
		type_lowercase_text.param_0,
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

// middle {element_type}
private let type_middleElement_elementType = (
    name: Symbol("middle"),
    param_0: (Symbol("element_type"), Symbol("element_type"), AsLiteralName()),
    result: asIs
)
private let interface_middleElement_elementType = HandlerInterface(
    name: type_middleElement_elementType.name,
    parameters: [
		type_middleElement_elementType.param_0,
    ],
    result: type_middleElement_elementType.result
)
private func procedure_middleElement_elementType(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_middleElement_elementType.param_0, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = middleElement(
    	elementType: arg_0
    )
    return type_middleElement_elementType.result.box(value: result, in: handlerEnv)
}

// mod {left, right}
private let type_mod_left_right = (
    name: Symbol("mod"),
    param_0: (Symbol("left"), Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), Symbol("right"), AsDouble()),
    result: AsDouble()
)
private let interface_mod_left_right = HandlerInterface(
    name: type_mod_left_right.name,
    parameters: [
		type_mod_left_right.param_0,
		type_mod_left_right.param_1,
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

// named {element_type, selector_data}
private let type_nameSelector_elementType_selectorData = (
    name: Symbol("named"),
    param_0: (Symbol("element_type"), Symbol("element_type"), AsLiteralName()),
    param_1: (Symbol("selector_data"), Symbol("selector_data"), asIs),
    result: asIs
)
private let interface_nameSelector_elementType_selectorData = HandlerInterface(
    name: type_nameSelector_elementType_selectorData.name,
    parameters: [
		type_nameSelector_elementType_selectorData.param_0,
		type_nameSelector_elementType_selectorData.param_1,
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

// negative {right}
private let type_negative_right = (
    name: Symbol("negative"),
    param_0: (Symbol("right"), Symbol("right"), AsNumber()),
    result: AsNumber()
)
private let interface_negative_right = HandlerInterface(
    name: type_negative_right.name,
    parameters: [
		type_negative_right.param_0,
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

// of {attribute, value}
private let type_ofClause_attribute_target = (
    name: Symbol("of"),
    param_0: (Symbol("attribute"), Symbol("attribute"), asIs),
    param_1: (Symbol("value"), Symbol("value"), AsValue()),
    result: asIs
)
private let interface_ofClause_attribute_target = HandlerInterface(
    name: type_ofClause_attribute_target.name,
    parameters: [
		type_ofClause_attribute_target.param_0,
		type_ofClause_attribute_target.param_1,
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

// positive {right}
private let type_positive_right = (
    name: Symbol("positive"),
    param_0: (Symbol("right"), Symbol("right"), AsNumber()),
    result: AsNumber()
)
private let interface_positive_right = HandlerInterface(
    name: type_positive_right.name,
    parameters: [
		type_positive_right.param_0,
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

// repeat {action, condition}
private let type_repeatWhile_action_condition = (
    name: Symbol("repeat"),
    param_0: (Symbol("action"), Symbol("action"), asIs),
    param_1: (Symbol("condition"), Symbol("condition"), asBool),
    result: AsSwiftPrecis<AsOptional>(AsOptional(AsValue()), "anything")
)
private let interface_repeatWhile_action_condition = HandlerInterface(
    name: type_repeatWhile_action_condition.name,
    parameters: [
		type_repeatWhile_action_condition.param_0,
		type_repeatWhile_action_condition.param_1,
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

// returning {interface, coercion}
private let type_returning_interface_coercion = (
    name: Symbol("returning"),
    param_0: (Symbol("interface"), Symbol("interface"), AsHandlerInterface()),
    param_1: (Symbol("coercion"), Symbol("coercion"), AsCoercion()),
    result: asItself
)
private let interface_returning_interface_coercion = HandlerInterface(
    name: type_returning_interface_coercion.name,
    parameters: [
		type_returning_interface_coercion.param_0,
		type_returning_interface_coercion.param_1,
    ],
    result: type_returning_interface_coercion.result
)
private func procedure_returning_interface_coercion(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
	return BoxedCommand(command)
}

// set {name, to}
private let type_set_name_to = (
    name: Symbol("set"),
    param_0: (Symbol("name"), Symbol("name"), AsLiteralName()),
    param_1: (Symbol("to"), Symbol("value"), AsSwiftPrecis<AsOptional>(AsOptional(AsValue()), "anything")),
    result: AsSwiftPrecis<AsOptional>(AsOptional(AsValue()), "anything")
)
private let interface_set_name_to = HandlerInterface(
    name: type_set_name_to.name,
    parameters: [
		type_set_name_to.param_0,
		type_set_name_to.param_1,
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

// tell {target, action}
private let type_tell_target_action = (
    name: Symbol("tell"),
    param_0: (Symbol("target"), Symbol("target"), AsValue()),
    param_1: (Symbol("action"), Symbol("action"), asIs),
    result: AsSwiftPrecis<AsOptional>(AsOptional(AsValue()), "anything")
)
private let interface_tell_target_action = HandlerInterface(
    name: type_tell_target_action.name,
    parameters: [
		type_tell_target_action.param_0,
		type_tell_target_action.param_1,
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

// thru {start_selector, stop_selector}
private let type_ElementRange_from_to = (
    name: Symbol("thru"),
    param_0: (Symbol("start_selector"), Symbol("start_selector"), asIs),
    param_1: (Symbol("stop_selector"), Symbol("stop_selector"), asIs),
    result: asIs
)
private let interface_ElementRange_from_to = HandlerInterface(
    name: type_ElementRange_from_to.name,
    parameters: [
		type_ElementRange_from_to.param_0,
		type_ElementRange_from_to.param_1,
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

// to {interface, action}
private let type_defineCommandHandler_interface_action = (
    name: Symbol("to"),
    param_0: (Symbol("interface"), Symbol("interface"), AsHandlerInterface()),
    param_1: (Symbol("action"), Symbol("action"), asIs),
    result: AsHandler()
)
private let interface_defineCommandHandler_interface_action = HandlerInterface(
    name: type_defineCommandHandler_interface_action.name,
    parameters: [
		type_defineCommandHandler_interface_action.param_0,
		type_defineCommandHandler_interface_action.param_1,
    ],
    result: type_defineCommandHandler_interface_action.result
)
private func procedure_defineCommandHandler_interface_action(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_defineCommandHandler_interface_action.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_defineCommandHandler_interface_action.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try defineCommandHandler(
    	interface: arg_0,
    	action: arg_1,
    	commandEnv: commandEnv
    )
    return type_defineCommandHandler_interface_action.result.box(value: result, in: handlerEnv)
}

// uppercase {text}
private let type_uppercase_text = (
    name: Symbol("uppercase"),
    param_0: (Symbol("text"), Symbol("text"), AsString()),
    result: AsString()
)
private let interface_uppercase_text = HandlerInterface(
    name: type_uppercase_text.name,
    parameters: [
		type_uppercase_text.param_0,
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

// when {interface, action}
private let type_defineEventHandler_interface_action = (
    name: Symbol("when"),
    param_0: (Symbol("interface"), Symbol("interface"), AsHandlerInterface()),
    param_1: (Symbol("action"), Symbol("action"), asIs),
    result: AsHandler()
)
private let interface_defineEventHandler_interface_action = HandlerInterface(
    name: type_defineEventHandler_interface_action.name,
    parameters: [
		type_defineEventHandler_interface_action.param_0,
		type_defineEventHandler_interface_action.param_1,
    ],
    result: type_defineEventHandler_interface_action.result
)
private func procedure_defineEventHandler_interface_action(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_defineEventHandler_interface_action.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_defineEventHandler_interface_action.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try defineEventHandler(
    	interface: arg_0,
    	action: arg_1,
    	commandEnv: commandEnv
    )
    return type_defineEventHandler_interface_action.result.box(value: result, in: handlerEnv)
}

// while {condition, action}
private let type_whileRepeat_condition_action = (
    name: Symbol("while"),
    param_0: (Symbol("condition"), Symbol("condition"), asBool),
    param_1: (Symbol("action"), Symbol("action"), asIs),
    result: AsSwiftPrecis<AsOptional>(AsOptional(AsValue()), "anything")
)
private let interface_whileRepeat_condition_action = HandlerInterface(
    name: type_whileRepeat_condition_action.name,
    parameters: [
		type_whileRepeat_condition_action.param_0,
		type_whileRepeat_condition_action.param_1,
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

// whose {element_type, selector_data}
private let type_testSelector_elementType_selectorData = (
    name: Symbol("whose"),
    param_0: (Symbol("element_type"), Symbol("element_type"), AsLiteralName()),
    param_1: (Symbol("selector_data"), Symbol("selector_data"), asIs),
    result: asIs
)
private let interface_testSelector_elementType_selectorData = HandlerInterface(
    name: type_testSelector_elementType_selectorData.name,
    parameters: [
		type_testSelector_elementType_selectorData.param_0,
		type_testSelector_elementType_selectorData.param_1,
    ],
    result: type_testSelector_elementType_selectorData.result
)
private func procedure_testSelector_elementType_selectorData(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arg_0 = try command.swiftValue(at: &index, for: type_testSelector_elementType_selectorData.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_testSelector_elementType_selectorData.param_1, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    let result = try testSelector(
    	elementType: arg_0,
    	selectorData: arg_1,
    	commandEnv: commandEnv,
    	handlerEnv: handlerEnv
    )
    return type_testSelector_elementType_selectorData.result.box(value: result, in: handlerEnv)
}

// write {value}
private let type_write_value = (
    name: Symbol("write"),
    param_0: (Symbol("value"), Symbol("value"), AsSwiftPrecis<AsOptional>(AsOptional(AsValue()), "anything")),
    result: AsNothing()
)
private let interface_write_value = HandlerInterface(
    name: type_write_value.name,
    parameters: [
		type_write_value.param_0,
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

// ≠ {left, right}
private let type_isNotEqual_left_right = (
    name: Symbol("≠"),
    param_0: (Symbol("left"), Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), Symbol("right"), AsDouble()),
    result: asBool
)
private let interface_isNotEqual_left_right = HandlerInterface(
    name: type_isNotEqual_left_right.name,
    parameters: [
		type_isNotEqual_left_right.param_0,
		type_isNotEqual_left_right.param_1,
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

// ≤ {left, right}
private let type_isLessOrEqual_left_right = (
    name: Symbol("≤"),
    param_0: (Symbol("left"), Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), Symbol("right"), AsDouble()),
    result: asBool
)
private let interface_isLessOrEqual_left_right = HandlerInterface(
    name: type_isLessOrEqual_left_right.name,
    parameters: [
		type_isLessOrEqual_left_right.param_0,
		type_isLessOrEqual_left_right.param_1,
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

// ≥ {left, right}
private let type_isGreaterOrEqual_left_right = (
    name: Symbol("≥"),
    param_0: (Symbol("left"), Symbol("left"), AsDouble()),
    param_1: (Symbol("right"), Symbol("right"), AsDouble()),
    result: asBool
)
private let interface_isGreaterOrEqual_left_right = HandlerInterface(
    name: type_isGreaterOrEqual_left_right.name,
    parameters: [
		type_isGreaterOrEqual_left_right.param_0,
		type_isGreaterOrEqual_left_right.param_1,
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



public func stdlib_loadHandlers(into env: Environment) {
    env.define(interface_joinValues_left_right, procedure_joinValues_left_right)
    env.define(interface_multiply_left_right, procedure_multiply_left_right)
    env.define(interface_add_left_right, procedure_add_left_right)
    env.define(interface_subtract_left_right, procedure_subtract_left_right)
    env.define(interface_divide_left_right, procedure_divide_left_right)
    env.define(interface_isLess_left_right, procedure_isLess_left_right)
    env.define(interface_isEqual_left_right, procedure_isEqual_left_right)
    env.define(interface_isGreater_left_right, procedure_isGreater_left_right)
    env.define(interface_AND_left_right, procedure_AND_left_right)
    env.define(interface_NOT_right, procedure_NOT_right)
    env.define(interface_OR_left_right, procedure_OR_left_right)
    env.define(interface_XOR_left_right, procedure_XOR_left_right)
    env.define(interface_exponent_left_right, procedure_exponent_left_right)
    env.define(interface_afterElement_elementType_expression, procedure_afterElement_elementType_expression)
    env.define(interface_randomElement_elementType, procedure_randomElement_elementType)
    env.define(interface_Application_bundleIdentifier, procedure_Application_bundleIdentifier)
    env.define(interface_coerce_value_coercion, procedure_coerce_value_coercion)
    env.define(interface_atSelector_elementType_selectorData, procedure_atSelector_elementType_selectorData)
    env.define(interface_beforeElement_elementType_expression, procedure_beforeElement_elementType_expression)
    env.define(interface_insertAtBeginning_, procedure_insertAtBeginning_)
    env.define(interface_beginsWith_left_right, procedure_beginsWith_left_right)
    env.define(interface_contains_left_right, procedure_contains_left_right)
    env.define(interface_div_left_right, procedure_div_left_right)
    env.define(interface_insertAtEnd_, procedure_insertAtEnd_)
    env.define(interface_endsWith_left_right, procedure_endsWith_left_right)
    env.define(interface_allElements_elementType, procedure_allElements_elementType)
    env.define(interface_firstElement_elementType, procedure_firstElement_elementType)
    env.define(interface_formatCode_value, procedure_formatCode_value)
    env.define(interface_rangeSelector_elementType_selectorData, procedure_rangeSelector_elementType_selectorData)
    env.define(interface_idSelector_elementType_selectorData, procedure_idSelector_elementType_selectorData)
    env.define(interface_ifTest_condition_action_alternativeAction, procedure_ifTest_condition_action_alternativeAction)
    env.define(interface_isA_value_coercion, procedure_isA_value_coercion)
    env.define(interface_isAfter_left_right, procedure_isAfter_left_right)
    env.define(interface_isBefore_left_right, procedure_isBefore_left_right)
    env.define(interface_isIn_left_right, procedure_isIn_left_right)
    env.define(interface_isNotAfter_left_right, procedure_isNotAfter_left_right)
    env.define(interface_isNotBefore_left_right, procedure_isNotBefore_left_right)
    env.define(interface_isNotSameAs_left_right, procedure_isNotSameAs_left_right)
    env.define(interface_isSameAs_left_right, procedure_isSameAs_left_right)
    env.define(interface_lastElement_elementType, procedure_lastElement_elementType)
    env.define(interface_lowercase_text, procedure_lowercase_text)
    env.define(interface_middleElement_elementType, procedure_middleElement_elementType)
    env.define(interface_mod_left_right, procedure_mod_left_right)
    env.define(interface_nameSelector_elementType_selectorData, procedure_nameSelector_elementType_selectorData)
    env.define(interface_negative_right, procedure_negative_right)
    env.define(interface_ofClause_attribute_target, procedure_ofClause_attribute_target)
    env.define(interface_positive_right, procedure_positive_right)
    env.define(interface_repeatWhile_action_condition, procedure_repeatWhile_action_condition)
    env.define(interface_returning_interface_coercion, procedure_returning_interface_coercion)
    env.define(interface_set_name_to, procedure_set_name_to)
    env.define(interface_tell_target_action, procedure_tell_target_action)
    env.define(interface_ElementRange_from_to, procedure_ElementRange_from_to)
    env.define(interface_defineCommandHandler_interface_action, procedure_defineCommandHandler_interface_action)
    env.define(interface_uppercase_text, procedure_uppercase_text)
    env.define(interface_defineEventHandler_interface_action, procedure_defineEventHandler_interface_action)
    env.define(interface_whileRepeat_condition_action, procedure_whileRepeat_condition_action)
    env.define(interface_testSelector_elementType_selectorData, procedure_testSelector_elementType_selectorData)
    env.define(interface_write_value, procedure_write_value)
    env.define(interface_isNotEqual_left_right, procedure_isNotEqual_left_right)
    env.define(interface_isLessOrEqual_left_right, procedure_isLessOrEqual_left_right)
    env.define(interface_isGreaterOrEqual_left_right, procedure_isGreaterOrEqual_left_right)
}