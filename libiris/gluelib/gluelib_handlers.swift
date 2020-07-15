//
//  gluelib_handlers.swift
//  iris-lang
//

// code generator

import Foundation



// define_handler (name, parameters, return_type, action, is_event_handler)
let type_defineHandlerGlue_handler_commandEnv = (
    // TO DO: reduce `name+parameters+result` to single parameter of type asHandlerInterface?
    param_0: (label: leftOperand, coercion: asHandlerInterface),
    param_1: (label: rightOperand, coercion: asIs), // TO DO: Record
    result: asNothing
)
let interface_defineHandlerGlue_handler_commandEnv = HandlerInterface(
    name: "to",
    parameters: [
        (type_defineHandlerGlue_handler_commandEnv.param_0.label, nullSymbol, type_defineHandlerGlue_handler_commandEnv.param_0.coercion),
        (type_defineHandlerGlue_handler_commandEnv.param_1.label, nullSymbol, type_defineHandlerGlue_handler_commandEnv.param_1.coercion),
        ],
    result: type_defineHandlerGlue_handler_commandEnv.result
)
func procedure_defineHandlerGlue_handler_commandEnv(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    let arguments = command.arguments
    let arg_0 = try command.swiftValue(at: &index, for: type_defineHandlerGlue_handler_commandEnv.param_0, in: commandEnv)
    let arg_1 = try command.swiftValue(at: &index, for: type_defineHandlerGlue_handler_commandEnv.param_1, in: commandEnv)
    if arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    try defineHandlerGlue(
        interface: arg_0,
        attributes: arg_1,
        commandEnv: commandEnv
    )
    return nullValue
}




struct AsScope: SwiftCoercion { // for now, this is purely to enable Swift func stubs to be generated with correct commandEnv/handlerEnv param types
    
    var swiftLiteralDescription: String { return "asScope" }
    
    let name: Symbol = "scope"
    
    typealias SwiftType = Scope
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        fatalError("Not yet implemented.")
    }
    
    func box(value: Scope, in scope: Scope) -> Value {
        fatalError("Not yet implemented.")
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        fatalError("Not yet implemented.")
    }
}

let asScope = AsScope()




func gluelib_loadHandlers(into env: Environment) {
    
    env.define(interface_defineHandlerGlue_handler_commandEnv, procedure_defineHandlerGlue_handler_commandEnv)
    
    try! env.set("expression", to: asIs) // caution: AsIs outputs the input Value exactly as-is, without evaluating it or capturing its lexical scope; this coercion is suitable for use only within primitive handlers that eval the parameter themselves using commandEnv // TO DO: stdlib needs to implement a native `expression` Coercion which thunks the input value before returning it // TO DO: rename `raw`/`raw_expression`/`unbound_expression`?
    
    env.define(coercion: asScope)
    env.define(coercion: asLiteralName)
    env.define(coercion: asHandlerInterface)

}
