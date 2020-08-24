//
//  sclib_coercions.swift
//  sclib
//

import Foundation
import iris



public struct AsAbstractType: NativeCoercion { // represents a Shortcuts “type”; for now these don’t do anything except allow action definitions to be created and added to env
    
    public let name: Symbol
    
    public init(_ name: Symbol) {
        self.name = name
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        // TO DO: what should this output?
        print("Coerce value to Shortcuts type ‘\(self.name)’: \(value)")
        throw TypeCoercionError(value: value, coercion: self)
    }
    
    public func wrap(_ value: Value, in scope: Scope) -> Value {
        return value
    }
}



public struct AsHiddenParameter: NativeCoercion {
    
    public var name: Symbol { return Symbol("hidden_parameter") }
    
    public var literalDescription: String { return "hidden_parameter \(self.elementType.literalDescription)" }
    
    public let elementType: NativeCoercion
    
    public init(_ elementType: NativeCoercion) {
        self.elementType = elementType
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        return try self.elementType.coerce(value, in: scope)
    }
    
    public func wrap(_ value: Value, in scope: Scope) -> Value {
        return self.elementType.wrap(value, in: scope)
    }
}

extension AsHiddenParameter: ConstrainableCoercion {
    
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
        return AsHiddenParameter(_: arg_0)
    }
}

let asHiddenParameter = AsHiddenParameter(asAnything)



// kludgy

public struct AsChoice: NativeCoercion {
    
    public let name: Symbol = "choice"
    
    public var swiftTypeDescription: String { return "String" }
    
    public var swiftLiteralDescription: String {
        return "AsChoice([\(self.options.map{Text($0).swiftLiteralDescription}.joined(separator: ", "))]).swiftCoercion"
    }
    
    public var literalDescription: String {
        return "\(self.name.label) [\(self.options.map{Text($0).literalDescription}.joined(separator: ", "))]"
    }
    
    private let options: Set<String> // TO DO: ideally should capture the original ordered list for documentation purposes
    
    public init(_ options: Set<String>) {
        self.options = Set<String>(options.map{$0.lowercased()})
    }
    
    public init(_ options: [String]) {
        self.options = Set<String>(options)
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self.swiftCoercion) }
        if let result = try? asString.coerce(value, in: scope),
            self.options.contains(result.lowercased()) { return Text(result) }
        throw TypeCoercionError(value: value, coercion: self)
    }
}

extension AsChoice: ConstrainableCoercion {
    
    private static let type_constrain = (
        param_0: (Symbol("options"), Symbol("options"), AsArray(asString)),
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


let asChoice = AsChoice([])






// quick-n-dirty hacks

public struct AsUnion: NativeCoercion {
    
    public var name: Symbol { return Symbol("OR") }
    
    public var literalDescription: String {
        return "‘OR’ {\(self.elementTypes[0].literalDescription), \(self.elementTypes[1].literalDescription)}"
    }
    
    public let elementTypes: [NativeCoercion]
    
    public init(_ left: NativeCoercion, _ right: NativeCoercion) {
        self.elementTypes = [left, right]
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        throw NotYetImplementedError()
    }
    
    public func wrap(_ value: Value, in scope: Scope) -> Value {
        return value
    }
}

extension AsUnion: ConstrainableCoercion {
    
    private static let type_constrain = (
        param_0: (Symbol("left"), Symbol("left"), asCoercion),
        param_1: (Symbol("right"), Symbol("right"), asCoercion),
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
        return AsUnion(_: arg_0, _: arg_1)
    }
}

let asUnion = AsUnion(asAnything, asAnything)

// TO DO: AsIntersection (AND), AsSymmetricDifference (XOR);

public struct AsSubtraction: NativeCoercion {
    
    public var name: Symbol { return Symbol("but_not") }
    
    public var literalDescription: String {
        return "‘but_not’ [{\(self.elementType.literalDescription), [\(self.excludedTypes.map{$0.literalDescription}.joined(separator: ", "))]}"
    }
    
    public let elementType: NativeCoercion
    public let excludedTypes: [NativeCoercion]
    
    public init(_ elementType: NativeCoercion, butNot excludedTypes: [NativeCoercion]) {
        self.elementType = elementType
        self.excludedTypes = excludedTypes
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        throw NotYetImplementedError()
    }
    
    public func wrap(_ value: Value, in scope: Scope) -> Value {
        return value
    }
}

extension AsSubtraction: ConstrainableCoercion {
    
    private static let type_constrain = (
        param_0: (Symbol("of_type"), Symbol("value_type"), asCoercion),
        param_1: (Symbol("but_not"), Symbol("excluded_types"), AsArray(asCoercion)), // TO DO: list of coercions should coerce to AsUnion
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
        return AsSubtraction(_: arg_0, butNot: arg_1)
    }
}

let asSubtraction = AsSubtraction(asAnything, butNot: [asNothing])







func sclib_loadCoercions(into env: ExtendedEnvironment) {
    env.define(coercion: CallableCoercion(asHiddenParameter))
    env.define(coercion: AsAbstractType("input"))
    env.define(coercion: AsSwiftPrecis(asString, "single_line_string")) // TO DO: need to implement this
    env.define(coercion: CallableCoercion(asUnion))
    env.define(coercion: CallableCoercion(asSubtraction))
    env.define(coercion: CallableCoercion(asChoice)) // need to override stdlib definition for now as it uses symbols but Shortcuts uses strings
    
    env.define(coercion: AsAbstractType("integer")) // TO DO: implement this
}


