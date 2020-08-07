//
//  dictionary constraints.swift
//  libiris
//

import Foundation

// TO DO: non-empty constraint?

extension AsKeyedList: ConstrainableCoercion {
    
    public var interface: HandlerInterface { return AsKeyedList.interface_constrain }
    
    private static let type_constrain = (
        name: Symbol("keyed_list"),
        param_0: (Symbol("key_type"), Symbol("key_type"), AsSwiftDefault(asCoercion, asValue)),
        param_1: (Symbol("value_type"), Symbol("value_type"), AsSwiftDefault(asCoercion, asValue)),
        result: asCoercion
    )
    
    private static let interface_constrain = HandlerInterface(
        name: type_constrain.name,
        parameters: [
            nativeParameter(type_constrain.param_0),
            nativeParameter(type_constrain.param_1),
        ],
        result: type_constrain.result.nativeCoercion
    )
    
    public func constrain(to command: Command, in scope: Scope) throws -> NativeCoercion {
        var index = 0
        let arg_0 = try command.value(for: AsKeyedList.type_constrain.param_0, at: &index, in: scope)
        let arg_1 = try command.value(for: AsKeyedList.type_constrain.param_1, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: self) }
        return AsKeyedList(keyType: arg_0, valueType: arg_1)
    }
    
}
