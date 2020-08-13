//
//  stdlib_records.swift
//
//  Bridging code for primitive structs/classes. This file is auto-generated; do not edit directly.
//

import Foundation
import iris


public struct AsOperatorSyntax: SwiftCoercion {

    private static let type_struct = (
        field_0: (Symbol("pattern"), Symbol("pattern"), asPattern),
        field_1: (Symbol("precedence"), Symbol("precedence"), asInt),
        field_2: (Symbol("associate"), Symbol("associate"), AsSwiftDefault(asAssociativity, defaultValue: Symbol("left"))),
        field_3: (Symbol("reducer"), Symbol("reducer"), AsSwiftOptional(asString)),
        _: ()
    )
    
    public let name: Symbol = "operator_syntax"
    
    public var swiftLiteralDescription: String { return "asOperatorSyntax" }
    
    public var literalDescription: String { return "record \(Self.recordType.literalDescription)" }
    
    public typealias SwiftType = OperatorSyntax
    
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
        return OperatorSyntax(
            pattern: arg_0,
            precedence: arg_1,
            associate: arg_2,
            reducer: arg_3
        )
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

public let asOperatorSyntax = AsOperatorSyntax()
