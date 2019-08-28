//
//  gluelib_handlers.swift
//  iris-lang
//

// code generator

import Foundation



// define_handler (name, parameters, return_type, action, is_event_handler)
let type_defineHandlerGlue_handler_commandEnv = (
    // TO DO: reduce `name+parameters+result` to single parameter of type asHandlerInterface?
    param_0: (label: rightOperand, coercion: asHandler),
    result: asNothing
)
let interface_defineHandlerGlue_handler_commandEnv = HandlerInterface(
    name: "to",
    parameters: [
        (type_defineHandlerGlue_handler_commandEnv.param_0.label, nullSymbol, type_defineHandlerGlue_handler_commandEnv.param_0.coercion),
        ],
    result: type_defineHandlerGlue_handler_commandEnv.result
)
func procedure_defineHandlerGlue_handler_commandEnv(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_defineHandlerGlue_handler_commandEnv.param_0, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    try defineHandlerGlue(
        handler: arg_0,
        commandEnv: commandEnv
    )
    return nullValue
}



func gluelib_loadHandlers(into env: Environment) {
    
    env.define(interface_defineHandlerGlue_handler_commandEnv, procedure_defineHandlerGlue_handler_commandEnv)
    
    try! env.set("expression", to: asIs) // caution: AsIs outputs the input Value exactly as-is, without evaluating it or capturing its lexical scope; this coercion is suitable for use only within primitive handlers that eval the parameter themselves using commandEnv // TO DO: stdlib needs to implement a native `expression` Coercion which thunks the input value before returning it
}
