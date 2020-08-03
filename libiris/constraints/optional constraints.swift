//
//  optional constraints.swift
//  libiris
//

// TO DO: constraint support for native coercions should be defined by extension; eventually these extensions will be code-generated by `iris-glue`, which should also generate the environment bindings that load them (for now, Environment.define(coercion:) does an extra type check)

import Foundation



extension AsOptional: ConstrainableCoercion {
    
    private static let type_optional = (
        name: Symbol("optional"),
        param_0: (Symbol("type"), Symbol("type"), asCoercion),
        result: asCoercion
    )
    
    private static let interface_optional = HandlerInterface(
        name: type_optional.name,
        parameters: [
            nativeParameter(type_optional.param_0),
        ],
        result: type_optional.result.nativeCoercion
    )
    
    public func constrain(with command: Command, in scope: Scope, as coercion: CallableCoercion) throws -> Self {
        // coercion is passed for error reporting only
        var index = 0
        let arg_0 = try command.value(for: AsOptional.type_optional.param_0, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: coercion) }
        return arg_0 is NullValue ? self : AsOptional(arg_0)
    }
}

