//
//  editable constraints.swift
//  libiris
//

import Foundation


extension AsEditable: ConstrainableCoercion {
    
    public var interface: HandlerInterface { return AsEditable.interface_constrain }
    
    private static let type_constrain = (
        name: Symbol("editable_value"),
        param_0: (Symbol("of"), Symbol("type"), AsSwiftDefault(asCoercion, asValue)),
        result: asCoercion
    )
    
    private static let interface_constrain = HandlerInterface(
        name: type_constrain.name,
        parameters: [
            nativeParameter(type_constrain.param_0),
        ],
        result: type_constrain.result.nativeCoercion
    )
    
    public func constrain(to command: Command, in scope: Scope) throws -> NativeCoercion {
        var index = 0
        let arg_0 = try command.value(for: AsEditable.type_constrain.param_0, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: self) }
        return AsEditable(arg_0)
    }
    
}
