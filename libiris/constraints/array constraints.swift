//
//  array constraints.swift
//  libiris
//

// TODO: how best to specify ranges; e.g. could we use `thru`, as in `integer 0 thru 100`? challenge there is how to specify a min/max value only? we might use chunk expressions, e.g. `list whose length = 4`, integer where 0 ≤ it ≤ 100, though those still need to reduce down to [simple] commands


import Foundation


extension AsOrderedList: ConstrainableCoercion {
    
    private static let type_list = (
        name: Symbol("list"),
        param_0: (Symbol("of"), Symbol("type"), AsSwiftDefault(asCoercion, asValue)),
        param_1: (Symbol("from"), Symbol("minimum"), AsSwiftOptional(IntConstraint(asInt, min: 0))),
        param_2: (Symbol("to"), Symbol("maximum"), AsSwiftOptional(IntConstraint(asInt, min: 0))),
        result: asCoercion
    )
    
    private static let interface_list = HandlerInterface(
        name: type_list.name,
        parameters: [
        nativeParameter(type_list.param_0),
        nativeParameter(type_list.param_1),
        nativeParameter(type_list.param_2),
        ],
        result: type_list.result.nativeCoercion
    )
    
    public func constrain(with command: Command, in scope: Scope, as coercion: CallableCoercion) throws -> NativeCoercion {
        var index = 0
        let arg_0 = try command.value(for: AsOrderedList.type_list.param_0, at: &index, in: scope)
        let arg_1 = try command.value(for: AsOrderedList.type_list.param_1, at: &index, in: scope)
        let arg_2 = try command.value(for: AsOrderedList.type_list.param_2, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: coercion) }
        return AsOrderedList(arg_0, minLength: arg_1, maxLength: arg_2)
    }
    
}
