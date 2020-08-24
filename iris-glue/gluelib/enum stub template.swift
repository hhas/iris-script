//
//  enum stub template.swift
//  iris-glue
//

import Foundation
import iris

// TO DO: how to get SwiftCoercion’s SwiftType?

// TO DO: also generate record stub file:
//
// public struct FooBar {
//    public let foo: String
//    public let bar: Int
// }



private let templateSource = """
//
//  ««libraryName»» enum stubs.swift
//
//  Swift enums that bridge to native choices. Copy and modify as needed.
//
//  This file is auto-generated; do not edit directly.
//

import Foundation

««+defineEnum»»

public enum ««swiftType»» {
    
    ««+cases»»
    case ««swiftCase»»
    ««-cases»»
}

««-defineEnum»»
"""


let enumStubsTemplate = TextTemplate(templateSource) {
    (tpl: Node, args: (libraryName: String, glues: [EnumGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.defineEnum.map(args.glues) {
        (node: Node, glue: EnumGlue) -> Void in
        node.swiftType.set(glue.swiftType)
        node.cases.map(glue.swiftCases) {
            (node: Node, swiftCase: String) -> Void in
            node.swiftCase.set(swiftCase)
        }
    }
}

