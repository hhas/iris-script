//
//  stdlib_records.swift
//
//  Bridging code for primitive structs/classes. This file is auto-generated; do not edit directly.
//

import Foundation

public struct AsHandlerGlueRequirements: SwiftCoercion {

    private static let type_struct = (
        field_0: (Symbol("can_error"), Symbol("can_error"), AsSwiftDefault(asBool, defaultValue: false)),
        field_1: (Symbol("use_scopes"), Symbol("use_scopes"), AsSwiftDefault(AsArray(AsMultichoice([Symbol("command"), Symbol("handler")]).swiftCoercion), defaultValue: [])),
        field_2: (Symbol("swift_function"), Symbol("swift_function"), AsSwiftOptional(AsLiteral<Command>())),
        field_3: (Symbol("operator"), Symbol("operator_definition"), AsSwiftOptional(asOperatorDefinition)),
        _: ()
    )
    
    public let name: Symbol = "handler_glue_requirements"
    
    public var swiftLiteralDescription: String { return "asHandlerGlueRequirements" }
    
    public var literalDescription: String { return self.name.label }
    
    public typealias SwiftType = HandlerGlueRequirements
    
    public static let recordType = RecordType([
        nativeParameter(Self.type_struct.field_0),
        nativeParameter(Self.type_struct.field_1),
        nativeParameter(Self.type_struct.field_2),
        nativeParameter(Self.type_struct.field_3),
    ])
    
    public init() {}
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        let fields = (value as? Record)?.data ?? [(nullSymbol, value)]
        var index = 0
        let arg_0 = try fields.coerce(param: Self.type_struct.field_0, at: &index, in: scope)
        let arg_1 = try fields.coerce(param: Self.type_struct.field_1, at: &index, in: scope)
        let arg_2 = try fields.coerce(param: Self.type_struct.field_2, at: &index, in: scope)
        let arg_3 = try fields.coerce(param: Self.type_struct.field_3, at: &index, in: scope)
        if fields.count > index { throw UnknownFieldError(at: index, of: fields) }
        return HandlerGlueRequirements( canError: arg_0,  useScopes: arg_1,  swiftFunction: arg_2,  operator: arg_3)
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return try! Record([
            (Self.type_struct.field_0.0, Self.type_struct.field_0.2.wrap(value.canError, in: scope)),
            (Self.type_struct.field_1.0, Self.type_struct.field_1.2.wrap(value.useScopes, in: scope)),
            (Self.type_struct.field_2.0, Self.type_struct.field_2.2.wrap(value.swiftFunction, in: scope)),
            (Self.type_struct.field_3.0, Self.type_struct.field_3.2.wrap(value.operatorDefinition, in: scope)),
        ])
    }
}

public let asHandlerGlueRequirements = AsHandlerGlueRequirements()

public struct AsOperatorDefinition: SwiftCoercion {

    private static let type_struct = (
        field_0: (Symbol("pattern"), Symbol("pattern"), asOperatorSyntax),
        field_1: (Symbol("precedence"), Symbol("precedence"), asInt),
        field_2: (Symbol("associate"), Symbol("associate"), AsSwiftDefault(asAssociativity, defaultValue: Symbol("left"))),
        field_3: (Symbol("reducer"), Symbol("reducer"), AsSwiftOptional(asString)),
        _: ()
    )
    
    public let name: Symbol = "operator_definition"
    
    public var swiftLiteralDescription: String { return "asOperatorDefinition" }
    
    public var literalDescription: String { return self.name.label }
    
    public typealias SwiftType = OperatorDefinition
    
    public static let recordType = RecordType([
        nativeParameter(Self.type_struct.field_0),
        nativeParameter(Self.type_struct.field_1),
        nativeParameter(Self.type_struct.field_2),
        nativeParameter(Self.type_struct.field_3),
    ])
    
    public init() {}
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        let fields = (value as? Record)?.data ?? [(nullSymbol, value)]
        var index = 0
        let arg_0 = try fields.coerce(param: Self.type_struct.field_0, at: &index, in: scope)
        let arg_1 = try fields.coerce(param: Self.type_struct.field_1, at: &index, in: scope)
        let arg_2 = try fields.coerce(param: Self.type_struct.field_2, at: &index, in: scope)
        let arg_3 = try fields.coerce(param: Self.type_struct.field_3, at: &index, in: scope)
        if fields.count > index { throw UnknownFieldError(at: index, of: fields) }
        return OperatorDefinition( pattern: arg_0,  precedence: arg_1,  associate: arg_2,  reducer: arg_3)
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return try! Record([
            (Self.type_struct.field_0.0, Self.type_struct.field_0.2.wrap(value.pattern, in: scope)),
            (Self.type_struct.field_1.0, Self.type_struct.field_1.2.wrap(value.precedence, in: scope)),
            (Self.type_struct.field_2.0, Self.type_struct.field_2.2.wrap(value.associate, in: scope)),
            (Self.type_struct.field_3.0, Self.type_struct.field_3.2.wrap(value.reducer, in: scope)),
        ])
    }
}

public let asOperatorDefinition = AsOperatorDefinition()