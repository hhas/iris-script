//
//  gluelib_handlers.swift
//  libiris
//

// code generator

import Foundation
import iris


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
        attributes: arg_1,
        commandEnv: commandEnv,
        handlerEnv: handlerEnv
    )
    return nullValue
}


func gluelib_loadHandlers(into env: Environment) {
    env.define(interface_defineHandlerGlue_handler_commandEnv, procedure_defineHandlerGlue_handler_commandEnv)
}
