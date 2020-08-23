//
//  stdlib_coercions.swift
//
//  Handler extensions for constructing constrained coercions.
//
//  This file is auto-generated; do not edit directly.
//

import Foundation

extension AsChoice: ConstrainableCoercion {
    
    private static let type_constrain = (
        param_0: (Symbol("options"), Symbol("options"), AsArray(asSymbol)),
        _: ()
    )
    
    public var interface: HandlerType {
        return HandlerType(
            name: self.name,
            parameters: [
                nativeParameter(Self.type_constrain.param_0),
            ],
            result: asCoercion.nativeCoercion
        )
    }
    
    public func constrain(to command: Command, in scope: Scope) throws -> NativeCoercion {
        var index = 0
        let arg_0 = try command.value(for: Self.type_constrain.param_0, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: self) }
        return AsChoice(_: arg_0)
    }
}

extension AsEditable: ConstrainableCoercion {
    
    private static let type_constrain = (
        param_0: (Symbol("of_type"), Symbol("value_type"), AsSwiftDefault(asCoercion, defaultValue: asAnything)),
        _: ()
    )
    
    public var interface: HandlerType {
        return HandlerType(
            name: self.name,
            parameters: [
                nativeParameter(Self.type_constrain.param_0),
            ],
            result: asCoercion.nativeCoercion
        )
    }
    
    public func constrain(to command: Command, in scope: Scope) throws -> NativeCoercion {
        var index = 0
        let arg_0 = try command.value(for: Self.type_constrain.param_0, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: self) }
        return AsEditable(_: arg_0)
    }
}

extension AsKeyedList: ConstrainableCoercion {
    
    private static let type_constrain = (
        param_0: (Symbol("key_type"), Symbol("key_type"), AsSwiftDefault(asCoercion, defaultValue: asValue)),
        param_1: (Symbol("value_type"), Symbol("value_type"), AsSwiftDefault(asCoercion, defaultValue: asAnything)),
        _: ()
    )
    
    public var interface: HandlerType {
        return HandlerType(
            name: self.name,
            parameters: [
                nativeParameter(Self.type_constrain.param_0),
                nativeParameter(Self.type_constrain.param_1),
            ],
            result: asCoercion.nativeCoercion
        )
    }
    
    public func constrain(to command: Command, in scope: Scope) throws -> NativeCoercion {
        var index = 0
        let arg_0 = try command.value(for: Self.type_constrain.param_0, at: &index, in: scope)
        let arg_1 = try command.value(for: Self.type_constrain.param_1, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: self) }
        return AsKeyedList(keyType: arg_0, valueType: arg_1)
    }
}

extension AsNumber: ConstrainableCoercion {
    
    private static let type_constrain = (
        param_0: (Symbol("whole"), Symbol("whole"), AsSwiftDefault(asBool, defaultValue: false)),
        param_1: (Symbol("from"), Symbol("minimum"), AsSwiftOptional(asSwiftNumber)),
        param_2: (Symbol("to"), Symbol("maximum"), AsSwiftOptional(asSwiftNumber)),
        _: ()
    )
    
    public var interface: HandlerType {
        return HandlerType(
            name: self.name,
            parameters: [
                nativeParameter(Self.type_constrain.param_0),
                nativeParameter(Self.type_constrain.param_1),
                nativeParameter(Self.type_constrain.param_2),
            ],
            result: asCoercion.nativeCoercion
        )
    }
    
    public func constrain(to command: Command, in scope: Scope) throws -> NativeCoercion {
        var index = 0
        let arg_0 = try command.value(for: Self.type_constrain.param_0, at: &index, in: scope)
        let arg_1 = try command.value(for: Self.type_constrain.param_1, at: &index, in: scope)
        let arg_2 = try command.value(for: Self.type_constrain.param_2, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: self) }
        return try AsConstrainedNumber(isWhole: arg_0, min: arg_1, max: arg_2)
    }
}

extension AsOptional: ConstrainableCoercion {
    
    private static let type_constrain = (
        param_0: (Symbol("of_type"), Symbol("value_type"), AsSwiftDefault(asCoercion, defaultValue: asValue)),
        param_1: (Symbol("with_default"), Symbol("default_value"), asAnything),
        _: ()
    )
    
    public var interface: HandlerType {
        return HandlerType(
            name: self.name,
            parameters: [
                nativeParameter(Self.type_constrain.param_0),
                nativeParameter(Self.type_constrain.param_1),
            ],
            result: asCoercion.nativeCoercion
        )
    }
    
    public func constrain(to command: Command, in scope: Scope) throws -> NativeCoercion {
        var index = 0
        let arg_0 = try command.value(for: Self.type_constrain.param_0, at: &index, in: scope)
        let arg_1 = try command.value(for: Self.type_constrain.param_1, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: self) }
        return AsOptional(_: arg_0, default: arg_1)
    }
}

extension AsOrderedList: ConstrainableCoercion {
    
    private static let type_constrain = (
        param_0: (Symbol("of"), Symbol("type"), AsSwiftDefault(asCoercion, defaultValue: asAnything)),
        param_1: (Symbol("from"), Symbol("minimum"), AsSwiftOptional(asInt)),
        param_2: (Symbol("to"), Symbol("maximum"), AsSwiftOptional(asInt)),
        _: ()
    )
    
    public var interface: HandlerType {
        return HandlerType(
            name: self.name,
            parameters: [
                nativeParameter(Self.type_constrain.param_0),
                nativeParameter(Self.type_constrain.param_1),
                nativeParameter(Self.type_constrain.param_2),
            ],
            result: asCoercion.nativeCoercion
        )
    }
    
    public func constrain(to command: Command, in scope: Scope) throws -> NativeCoercion {
        var index = 0
        let arg_0 = try command.value(for: Self.type_constrain.param_0, at: &index, in: scope)
        let arg_1 = try command.value(for: Self.type_constrain.param_1, at: &index, in: scope)
        let arg_2 = try command.value(for: Self.type_constrain.param_2, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: self) }
        return try AsOrderedList(_: arg_0, minLength: arg_1, maxLength: arg_2)
    }
}

extension AsRecord: ConstrainableCoercion {
    
    private static let type_constrain = (
        param_0: (Symbol("of_type"), Symbol("record_type"), AsSwiftOptional(asRecordType)),
        _: ()
    )
    
    public var interface: HandlerType {
        return HandlerType(
            name: self.name,
            parameters: [
                nativeParameter(Self.type_constrain.param_0),
            ],
            result: asCoercion.nativeCoercion
        )
    }
    
    public func constrain(to command: Command, in scope: Scope) throws -> NativeCoercion {
        var index = 0
        let arg_0 = try command.value(for: Self.type_constrain.param_0, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: self) }
        return AsRecord(_: arg_0)
    }
}

public func stdlib_loadCoercions(into env: Environment) {
    env.define(coercion: asAnything)
    env.define(coercion: asBlock)
    env.define(coercion: asBool)
    env.define(coercion: CallableCoercion(asChoice))
    env.define(coercion: asCoercion)
    env.define(coercion: CallableCoercion(asEditable))
    env.define(coercion: asHandler)
    env.define(coercion: CallableCoercion(asKeyedList))
    env.define(coercion: CallableCoercion(asNumber))
    env.define(coercion: CallableCoercion(asOptional))
    env.define(coercion: CallableCoercion(asOrderedList))
    env.define("list", CallableCoercion(asOrderedList))
    env.define(coercion: CallableCoercion(asRecord))
    env.define(coercion: asSymbol)
    env.define(coercion: asText)
    env.define(coercion: asValue)
}
