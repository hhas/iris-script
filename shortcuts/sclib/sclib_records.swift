//
//  sclib_records.swift
//  sclib
//

import Foundation
import iris


public struct ShortcutActionRequirements {
    
    let id: String
    let category: String
    let tags: [Symbol]
}


public struct AsShortcutActionRequirements: SwiftCoercion {

    private static let type_struct = (
        field_0: (Symbol("id"), Symbol("id"), asString),
        field_1: (Symbol("category"), Symbol("category"), asString),
        field_2: (Symbol("tags"), Symbol("tags"), AsArray(asSymbol))
    )
    
    public let name: Symbol = "shortcut_action_requirements"
    
    public var swiftLiteralDescription: String { return "asShortcutActionRequirements" }
    
    public var literalDescription: String { return self.name.label }
    
    public typealias SwiftType = ShortcutActionRequirements
    
    public static let recordType = RecordType([
        nativeParameter(Self.type_struct.field_0),
        nativeParameter(Self.type_struct.field_1),
        nativeParameter(Self.type_struct.field_2),
    ])
    
    public init() {}
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        let fields = (value as? Record)?.data ?? [(nullSymbol, value)]
        var index = 0
        let arg_0 = try fields.coerce(param: Self.type_struct.field_0, at: &index, in: scope)
        let arg_1 = try fields.coerce(param: Self.type_struct.field_1, at: &index, in: scope)
        let arg_2 = try fields.coerce(param: Self.type_struct.field_2, at: &index, in: scope)
        if fields.count > index { throw UnknownFieldError(at: index, of: fields) }
        return ShortcutActionRequirements(id: arg_0, category: arg_1, tags: arg_2)
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return try! Record([
            (Self.type_struct.field_0.0, Self.type_struct.field_0.2.wrap(value.id, in: scope)),
            (Self.type_struct.field_1.0, Self.type_struct.field_1.2.wrap(value.category, in: scope)),
            (Self.type_struct.field_2.0, Self.type_struct.field_2.2.wrap(value.tags, in: scope)),
        ])
    }
}

public let asShortcutActionRequirements = AsShortcutActionRequirements()


