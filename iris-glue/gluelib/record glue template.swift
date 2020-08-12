//
//  record glue template.swift
//  iris-glue
//

import Foundation
import iris



private let templateSource = """
//
//  ««libraryName»»_records.swift
//
//  Bridging code for primitive structs/classes. This file is auto-generated; do not edit directly.
//

import Foundation

««+defineStruct»»

public struct As««structName»»: SwiftCoercion {

    private static let type_struct = (
        ««+typeFields»»
        field_««count»»: (Symbol("««label»»"), Symbol("««binding»»"), ««coercion»»),
        ««-typeFields»»
        _: ()
    )
    
    public let name: Symbol = "record"
    
    public var swiftLiteralDescription: String { return "as««structName»»" }
    
    public var literalDescription: String { return "record \\(Self.recordType.literalDescription)" }
    
    public typealias SwiftType = ««structName»»
    
    public static let recordType = RecordType([
        ««+interfaceFields»»
        nativeParameter(Self.type_struct.field_««count»»),
        ««-interfaceFields»»
    ])
    
    public init() {}
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        let fields = (value as? Record)?.data ?? [(nullSymbol, value)]
        var index = 0
        ««+unboxArguments»»
        let arg_««count»» = try fields.coerce(param: Self.type_struct.field_««count»», at: &index, in: scope)
        ««-unboxArguments»»
        if fields.count > index { throw UnknownFieldError(at: index, of: fields) }
        return ««+tryKeyword»» try ««-tryKeyword»» ««structName»»(««+swiftArguments»» ««label»»: arg_««count»» ««~swiftArguments»», ««-swiftArguments»»)
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return try! Record([
            ««+boxArguments»»
            (Self.type_struct.field_««count»».0, Self.type_struct.field_««count»».2.wrap(value.««swiftAttribute»», in: scope)),
            ««-boxArguments»»
        ])
    }
}

public let as««structName»» = As««structName»»()

««-defineStruct»»
"""


let recordsTemplate = TextTemplate(templateSource) {
    (tpl: Node, args: (libraryName: String, glues: [RecordGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.defineStruct.map(args.glues) {
        (node: Node, glue: RecordGlue) -> Void in
        node.structName.set(glue.swiftType)
        node.typeFields.map(glue.fields.enumerated()) {
            (node: Node, item: (count: Int, field: RecordGlue.Field)) -> Void in
            node.count.set(item.count)
            node.label.set(item.field.label)
            node.binding.set(item.field.binding)
            node.coercion.set(item.field.coercion)
        }
        node.interfaceFields.map(0..<glue.fields.count) {
            (node: Node, count: Int) -> Void in
            node.count.set(count)
        }
        node.unboxArguments.map(0..<glue.fields.count) {
            (node: Node, count: Int) -> Void in
            node.count.set(count)
        }
        if !glue.canError { node.tryKeyword.delete() }
        node.structName.set(glue.swiftType)
        node.swiftArguments.map(glue.swiftFields.enumerated()) {
            (node: Node, item: (count: Int, field: RecordGlue.Field)) -> Void in
            node.label.set(item.field.label)
            node.count.set(item.count)
        }
        node.boxArguments.map(glue.swiftFields.enumerated()) {
            (node: Node, item: (count: Int, field: RecordGlue.Field)) -> Void in
            node.swiftAttribute.set(item.field.binding)
            node.count.set(item.count)
        }
    }
}

