//
//  handler stub template.swift
//  gluelib
//
//  generates function stubs
//

import Foundation
import iris

// TO DO: need to sort out public vs internal declarations

// TO DO: disable whitespace auto-trimming (space after comma in param list currently isn't being preserved)

private let templateSource = """
//
//  ««libraryName»» handler stubs.swift
//
//  Swift functions that bridge to native handlers. Copy and modify as needed.
//
//  This file is auto-generated; do not edit directly.
//

import Foundation

««+defineHandler»»

func ««functionName»»(««+functionParameters»»\
««label»»««binding»»: ««type»» ««|functionParameters»», \
««-functionParameters»») ««+canThrow»» throws ««-canThrow»» ««+hasReturnType»» -> ««returnType»» ««-hasReturnType»» {
    fatalError("««functionName»» of ««libraryName»» is not yet implemented.")
}
««-defineHandler»»
"""


let handlerStubsTemplate = TextTemplate(templateSource) {
    (tpl: Node, args: (libraryName: String, glues: [HandlerGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.defineHandler.map(args.glues.filter{ !($0.interface.result is AsItself) }) {
        (node: Node, glue: HandlerGlue) -> Void in
        node.functionName.set(glue.swiftName)
        node.libraryName.set(args.libraryName)
      //  let scopes = glue.useScopes.map{(Symbol($0), Symbol($0), asScope) as HandlerType.Parameter}
        node.functionParameters.map(glue.swiftParameters) {
            (node: Node, item: (label: String, binding: String?, type: String)) -> Void in
            node.label.set(item.label)
            if let binding = item.binding { node.binding.set(" \(binding)") }
            node.type.set(item.type)
        }
        if !glue.canError { node.canThrow.delete() }
        let returnType = glue.interface.result.swiftTypeDescription
        if returnType.isEmpty {
            node.hasReturnType.delete()
        } else {
            node.hasReturnType.returnType.set(returnType)
        }
    }
}

