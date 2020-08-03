//
//  array constraints.swift
//  libiris
//

// TODO: how best to specify ranges; e.g. could we use `thru`, as in `integer 0 thru 100`? challenge there is how to specify a min/max value only? we might use chunk expressions, e.g. `list whose length = 4`, integer where 0 ≤ it ≤ 100, though those still need to reduce down to [simple] commands


import Foundation


extension AsOrderedList: ConstrainableCoercion {
    
    private static let type_list = (
        name: Symbol("list"),
        param_0: (Symbol("of"), Symbol("type"), asCoercion),
        result: asCoercion
    )
    
    private static let interface_list = HandlerInterface(
        name: type_list.name,
        parameters: [
            nativeParameter(type_list.param_0),
        ],
        result: type_list.result.nativeCoercion
    )
    
    public func constrain(with command: Command, in scope: Scope, as coercion: CallableCoercion) throws -> Self {
        var index = 0
        let arg_0 = try command.value(for: AsOrderedList.type_list.param_0, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: coercion) }
        return AsOrderedList(arg_0)
    }
    
}
