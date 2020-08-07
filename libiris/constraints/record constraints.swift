//
//  record constraints.swift
//  libiris
//

import Foundation


// TO DO: use vararg instead? this would allow user to write `record {foo as string, bar as number,…}` instead of `record {{foo as string, bar as number,…}}`; note that unlike [e.g.] Python vararg support must be all-or-nothing, more akin to JS’s `arguments`; for now, we get equivalent syntax by defining ‘record’ as a prefix operator with optional operand (although that is inconsistent with other constrainable coercions which appear as commands)


extension AsRecord: ConstrainableCoercion {
    
    public var interface: HandlerInterface { return AsRecord.interface_constrain }
    
    private static let type_constrain = (
        name: Symbol("record"),
        param_0: (Symbol("of_type"), Symbol("record_type"), AsSwiftDefault(asRecordType, [])),
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
        let arg_0 = try command.value(for: AsRecord.type_constrain.param_0, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: self) }
        return AsRecord(arg_0)
    }
    
}
