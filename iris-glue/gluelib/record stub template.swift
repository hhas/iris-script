//
//  record stub template.swift
//  iris-glue
//

import Foundation
import iris


// TO DO: FIX: this isn’t yet inserting correct types for `associate` (Associativity) and `reducer` (String?) slots


private let templateSource = """
//
//  ««libraryName»» record stubs.swift
//
//  Swift structs that bridge to native records. Copy and modify as needed.
//
//  This file is auto-generated; do not edit directly.
//

import Foundation

««+defineStruct»»

public struct ««swiftName»» {
    
    ««+attributes»»
    public let ««binding»»: ««swiftType»»
    ««-attributes»»
    
    public init(««+arguments»»««label»»««binding»»: ««swiftType»»««~arguments»», ««-arguments»») {
        ««+bindings»»
        self.««binding»» = ««binding»»
        ««-bindings»»
    }
}
    
««-defineStruct»»
"""


let recordStubsTemplate = TextTemplate(templateSource) {
    (tpl: Node, args: (libraryName: String, glues: [RecordGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.defineStruct.map(args.glues) {
        (node: Node, glue: RecordGlue) -> Void in
        node.swiftName.set(glue.swiftType)
        node.attributes.map(glue.swiftFields) {
            (node: Node, field: RecordGlue.Field) -> Void in
            node.binding.set(field.binding)
            node.swiftType.set(field.coercion) // SwiftType as string
        }
        node.arguments.map(glue.swiftFields) {
            (node: Node, field: RecordGlue.Field) -> Void in
            node.label.set(field.label == field.binding ? "" : "\(field.label) ")
            node.binding.set(field.binding)
            node.swiftType.set(field.coercion) // ditto
        }
        node.bindings.map(glue.swiftFields) {
            (node: Node, field: RecordGlue.Field) -> Void in
            node.binding.set(field.binding)
        }
    }
}

