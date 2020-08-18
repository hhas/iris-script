//
//  gluelib_handlers.swift
//  libiris
//


import Foundation
import iris


private let type_defineHandlerGlue_handler_commandEnv = (
    name: Symbol("swift_handler"),
    param_0: (Symbol("with_interface"), Symbol("interface"), asHandlerType),
    param_1: (Symbol("requires"), Symbol("requirements"), asHandlerGlueRequirements),
    result: asNothing
)
private let interface_defineHandlerGlue_handler_commandEnv = HandlerType(
    name: type_defineHandlerGlue_handler_commandEnv.name,
    parameters: [
        nativeParameter(type_defineHandlerGlue_handler_commandEnv.param_0),
        nativeParameter(type_defineHandlerGlue_handler_commandEnv.param_1),
        ],
    result: type_defineHandlerGlue_handler_commandEnv.result.nativeCoercion
)
private func procedure_defineHandlerGlue_handler_commandEnv(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.value(for: type_defineHandlerGlue_handler_commandEnv.param_0, at: &index, in: commandEnv)
    let arg_1 = try command.value(for: type_defineHandlerGlue_handler_commandEnv.param_1, at: &index, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    try defineHandlerGlue(
        interface: arg_0,
        requirements: arg_1,
        commandEnv: commandEnv,
        handlerEnv: handlerEnv
    )
    return nullValue
}


private let type_defineRecordGlue_handler_commandEnv = (
    name: Symbol("swift_record"),
    param_0: (Symbol("of_type"), Symbol("record_type"), asNamedRecordType),
    param_1: (Symbol("requires"), Symbol("requirements"), asRecordGlueRequirements), 
    result: asNothing
)
private let interface_defineRecordGlue_handler_commandEnv = HandlerType(
    name: type_defineRecordGlue_handler_commandEnv.name,
    parameters: [
        nativeParameter(type_defineRecordGlue_handler_commandEnv.param_0),
        nativeParameter(type_defineRecordGlue_handler_commandEnv.param_1),
        ],
    result: type_defineRecordGlue_handler_commandEnv.result.nativeCoercion
)
private func procedure_defineRecordGlue_handler_commandEnv(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.value(for: type_defineRecordGlue_handler_commandEnv.param_0, at: &index, in: commandEnv)
    let arg_1 = try command.value(for: type_defineRecordGlue_handler_commandEnv.param_1, at: &index, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    try defineRecordGlue(
        interface: arg_0,
        requirements: arg_1,
        commandEnv: commandEnv,
        handlerEnv: handlerEnv
    )
    return nullValue
}


private let type_defineCoercionGlue_handler_commandEnv = (
    name: Symbol("swift_coercion"),
    param_0: (Symbol("of_type"), Symbol("swift_type"), asLiteralName),
    param_1: (Symbol("requires"), Symbol("requirements"), asIs), // TO DO: asCoercionRequirements
    result: asNothing
)
private let interface_defineCoercionGlue_handler_commandEnv = HandlerType(
    name: type_defineCoercionGlue_handler_commandEnv.name,
    parameters: [
        nativeParameter(type_defineCoercionGlue_handler_commandEnv.param_0),
        nativeParameter(type_defineCoercionGlue_handler_commandEnv.param_1),
    ],
    result: type_defineCoercionGlue_handler_commandEnv.result.nativeCoercion
)
private func procedure_defineCoercionGlue_handler_commandEnv(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.value(for: type_defineCoercionGlue_handler_commandEnv.param_0, at: &index, in: commandEnv)
    let arg_1 = try command.value(for: type_defineCoercionGlue_handler_commandEnv.param_1, at: &index, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    try defineCoercionGlue(
        swiftType: arg_0,
        attributes: arg_1,
        commandEnv: commandEnv,
        handlerEnv: handlerEnv
    )
    return nullValue
}


private let type_defineEnumGlue_handler_commandEnv = (
    name: Symbol("swift_choice"),
    param_0: (Symbol("options"), Symbol("options"), AsArray(asSymbol)),
    param_1: (Symbol("requires"), Symbol("requirements"), asIs), // TO DO: asEnumRequirements
    result: asNothing
)
private let interface_defineEnumGlue_handler_commandEnv = HandlerType(
    name: type_defineEnumGlue_handler_commandEnv.name,
    parameters: [
        nativeParameter(type_defineEnumGlue_handler_commandEnv.param_0),
        nativeParameter(type_defineEnumGlue_handler_commandEnv.param_1),
    ],
    result: type_defineEnumGlue_handler_commandEnv.result.nativeCoercion
)
private func procedure_defineEnumGlue_handler_commandEnv(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.value(for: type_defineEnumGlue_handler_commandEnv.param_0, at: &index, in: commandEnv)
    let arg_1 = try command.value(for: type_defineEnumGlue_handler_commandEnv.param_1, at: &index, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    try defineEnumGlue(
        options: arg_0,
        attributes: arg_1,
        commandEnv: commandEnv,
        handlerEnv: handlerEnv
    )
    return nullValue
}





func gluelib_loadHandlers(into env: Environment) {
    env.define(interface_defineHandlerGlue_handler_commandEnv, procedure_defineHandlerGlue_handler_commandEnv)
    env.define(interface_defineRecordGlue_handler_commandEnv, procedure_defineRecordGlue_handler_commandEnv)
    env.define(interface_defineCoercionGlue_handler_commandEnv, procedure_defineCoercionGlue_handler_commandEnv)
    env.define(interface_defineEnumGlue_handler_commandEnv, procedure_defineEnumGlue_handler_commandEnv)
}
