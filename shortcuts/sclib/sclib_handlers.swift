//
//  sclib_handlers.swift
//  sclib
//

import Foundation
import iris



public struct ShortcutAction: Callable {
    
    public static var nominalType: NativeCoercion = asHandler.nativeCoercion
    
    public var description: String { return self.interface.description }
    
    public var name: Symbol { return self.interface.name }
    
    public let interface: HandlerType
    public let requirements: ShortcutActionRequirements
    
    public init(for interface: HandlerType, requires requirements: ShortcutActionRequirements) {
        self.interface = interface
        self.requirements = requirements
    }
    
    public func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        fatalError()
    }
}

extension Environment {

    public func define(action: ShortcutAction) throws {
        try self.set(action.name, to: action)
    }
}



private let type_shortcutAction = (
    name: Symbol("shortcut_action"),
    param_0: (Symbol("for"), Symbol("interface"), asHandlerType),
    param_1: (Symbol("requires"), Symbol("requirements"), asShortcutActionRequirements),
    result: nullValue
)
private let interface_shortcutAction = HandlerType(
    name: type_shortcutAction.name,
    parameters: [
        nativeParameter(type_shortcutAction.param_0),
        nativeParameter(type_shortcutAction.param_1),
    ],
    result: type_shortcutAction.result.nativeCoercion
)
private func procedure_shortcutAction(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_shortcutAction.param_0, at: &index, in: commandEnv)
    let arg_1 = try command.value(for: type_shortcutAction.param_1, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    do {
        try (commandEnv as! Environment).define(action: ShortcutAction(for: arg_0, requires: arg_1))
    } catch {
        // e.g. `street_address` // TO DO: how to disambiguate? (part of the problem is that we discard ObjC-style namespace prefixes for readability, e.g. `WFStreetAddress` type -> `street_address`, but since action name is `Street Address` it ends up as `street_address` too)
        print("Skipping ‘\(arg_0.name.label)’ action as its name conflicts with an existing type.")
    }
    return nullValue
}



private let type_shortcutType = (
    name: Symbol("shortcut_type"),
    param_0: (Symbol("named"), Symbol("name"), asLiteralName),
    result: nullValue
)
private let interface_shortcutType = HandlerType(
    name: type_shortcutType.name,
    parameters: [
        nativeParameter(type_shortcutType.param_0),
    ],
    result: type_shortcutType.result.nativeCoercion
)
private func procedure_shortcutType(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_shortcutType.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let env = commandEnv as! Environment
    // don't overwrite existing stdlib types
    if env.get(arg_0) == nil { env.define(coercion: AsAbstractType(_: arg_0)) }
    return nullValue
}




private let type_union = (
    name: Symbol("OR"),
    param_0: (Symbol("left"), Symbol("left"), asCoercion),
    param_1: (Symbol("right"), Symbol("right"), asCoercion),
    result: asCoercion
)
private let interface_union = HandlerType(
    name: type_union.name,
    parameters: [
        nativeParameter(type_union.param_0),
        nativeParameter(type_union.param_1),
    ],
    result: type_union.result.nativeCoercion
)
private func procedure_union(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_union.param_0, at: &index, in: commandEnv)
    let arg_1 = try command.value(for: type_union.param_1, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    return AsUnion(_: arg_0, _: arg_1)
}




func sclib_loadHandlers(into env: ExtendedEnvironment) {
    env.define(interface_shortcutAction, procedure_shortcutAction)
    env.define(interface_shortcutType, procedure_shortcutType)
    env.define(interface_union, procedure_union)
}




