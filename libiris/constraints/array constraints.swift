//
//  array constraints.swift
//  libiris
//

// TO DO: how best to specify ranges; e.g. could we use `thru`, as in `integer 0 thru 100`? challenge there is how to specify a min/max value only? we might use chunk expressions, e.g. `list whose length = 4`, integer where 0 ≤ it ≤ 100, though those still need to reduce down to [simple] commands


import Foundation


extension AsOrderedList: ConstrainableCoercion {
    
    public var interface: HandlerInterface { return AsOrderedList.interface_constrain }
    
    private static let type_constrain = (
        name: Symbol("ordered_list"), // aliased as `list` // TO DO: should canonical name be ‘list’ or ‘ordered_list’? (either way, one should be aliased to the other)
        param_0: (Symbol("of"), Symbol("type"), AsSwiftDefault(asCoercion, asValue)),
        param_1: (Symbol("from"), Symbol("minimum"), AsSwiftOptional(IntConstraint(asInt, min: 0))), // TO DO: as with AsNumber, min ≤ max
        param_2: (Symbol("to"), Symbol("maximum"), AsSwiftOptional(IntConstraint(asInt, min: 0))),
        result: asCoercion
    )
    
    private static let interface_constrain = HandlerInterface(
        name: type_constrain.name,
        parameters: [
            nativeParameter(type_constrain.param_0),
            nativeParameter(type_constrain.param_1),
            nativeParameter(type_constrain.param_2),
        ],
        result: type_constrain.result.nativeCoercion
    )
    
    public func constrain(to command: Command, in scope: Scope) throws -> NativeCoercion {
        var index = 0
        let arg_0 = try command.value(for: AsOrderedList.type_constrain.param_0, at: &index, in: scope)
        let arg_1 = try command.value(for: AsOrderedList.type_constrain.param_1, at: &index, in: scope)
        let arg_2 = try command.value(for: AsOrderedList.type_constrain.param_2, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: self) }
        return try AsOrderedList(arg_0, minLength: arg_1, maxLength: arg_2)
    }
}

