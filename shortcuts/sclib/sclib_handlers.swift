//
//  sclib_handlers.swift
//  sclib
//

import Foundation
import iris



// read glue files

private let type_shortcutAction = (
    name: Symbol("shortcut_action"),
    param_0: (Symbol("for"), Symbol("interface"), asHandlerType),
    param_1: (Symbol("requires"), Symbol("requirements"), asShortcutActionRequirements),
    result: nullValue
)
private let interface_shortcutAction = HandlerType(
    name: type_shortcutAction.name,
    parameters: [
        nativeParameter(type_shortcutAction.param_0),
        nativeParameter(type_shortcutAction.param_1),
    ],
    result: type_shortcutAction.result.nativeCoercion
)
private func procedure_shortcutAction(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_shortcutAction.param_0, at: &index, in: commandEnv)
    let arg_1 = try command.value(for: type_shortcutAction.param_1, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    do {
        try (commandEnv as! Environment).define(action: DefaultActionConstructor(for: arg_0, requires: arg_1))
    } catch {
        // e.g. `street_address` // TO DO: how to disambiguate? (part of the problem is that we discard ObjC-style namespace prefixes for readability, e.g. `WFStreetAddress` type -> `street_address`, but since action name is `Street Address` it ends up as `street_address` too); FWIW, most of the conflicting actions serve only to output a value of that type, so can be replaced with coercions that output the action XML when applied in pipeline context
        print("Skipping ‘\(arg_0.name.label)’ action as its name conflicts with an existing type.")
    }
    return nullValue
}

private let type_shortcutType = (
    name: Symbol("shortcut_type"),
    param_0: (Symbol("named"), Symbol("name"), asLiteralName),
    result: nullValue
)
private let interface_shortcutType = HandlerType(
    name: type_shortcutType.name,
    parameters: [
        nativeParameter(type_shortcutType.param_0),
    ],
    result: type_shortcutType.result.nativeCoercion
)
private func procedure_shortcutType(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_shortcutType.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let env = commandEnv as! Environment
    // don't overwrite existing stdlib types
    if env.get(arg_0) == nil { env.define(coercion: AsAbstractType(_: arg_0)) }
    return nullValue
}


// build workflow

private let type_set_name_to = (
    name: Symbol("set"),
    param_0: (Symbol("name"), Symbol("name"), asLiteralName),
    param_1: (Symbol("to"), Symbol("value"), asAnything),
    result: asAnything
)
private let interface_set_name_to = HandlerType(
    name: type_set_name_to.name,
    parameters: [
        nativeParameter(type_set_name_to.param_0),
        nativeParameter(type_set_name_to.param_1),
    ],
    result: type_set_name_to.result.nativeCoercion
)
private func procedure_set_name_to(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_set_name_to.param_0, at: &index, in: commandEnv)
    let arg_1 = try command.value(for: type_set_name_to.param_1, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let result = try set(name: arg_0, to: arg_1, commandEnv: commandEnv)
    return type_set_name_to.result.wrap(result, in: handlerEnv)
}

private let type_store_value_name = (
    name: Symbol("store"),
    param_0: (Symbol("value"), Symbol("value"), asAnything),
    param_1: (Symbol("named"), Symbol("name"), asLiteralName),
    result: asAnything // passthru
)
private let interface_store_value_name = HandlerType(
    name: type_store_value_name.name,
    parameters: [
        nativeParameter(type_store_value_name.param_0),
        nativeParameter(type_store_value_name.param_1),
    ],
    result: type_store_value_name.result.nativeCoercion
)
private func procedure_store_value_name(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_store_value_name.param_0, at: &index, in: commandEnv)
    let arg_1 = try command.value(for: type_store_value_name.param_1, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let result = try store(value: arg_0, named: arg_1, commandEnv: commandEnv)
    return type_store_value_name.result.wrap(result, in: handlerEnv)
}

private let type_interpolate_text = (
    name: Symbol("interpolate"),
    param_0: (Symbol("text"), Symbol("text"), asString),
    result: asValue
)
private let interface_interpolate_text = HandlerType(
    name: type_interpolate_text.name,
    parameters: [
        nativeParameter(type_interpolate_text.param_0),
    ],
    result: type_interpolate_text.result.nativeCoercion
)
private func procedure_interpolate_text(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_interpolate_text.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let result = try InterpolatedText(text: arg_0, commandEnv: commandEnv)
    return type_interpolate_text.result.wrap(result, in: handlerEnv)
}




func sclib_loadHandlers(into env: ExtendedEnvironment) {
    env.define(interface_shortcutAction, procedure_shortcutAction)
    env.define(interface_shortcutType, procedure_shortcutType)
    env.define(interface_set_name_to, procedure_set_name_to)
    env.define(interface_store_value_name, procedure_store_value_name)
    env.define(interface_interpolate_text, procedure_interpolate_text)
}




