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
//  ««libraryName»» HANDLER STUBS.swift
//
//  Swift functions that implement primitive handlers.
//

import Foundation

««+defineHandler»»

func ««functionName»»(««+functionParameters»»\
««label»»««binding»»: ««type»» ««~functionParameters»», \
««-functionParameters»») ««+canThrow»» throws ««-canThrow»» ««+hasReturnType»» -> ««returnType»» ««-hasReturnType»» {
    fatalError("««functionName»» of ««libraryName»» is not yet implemented.")
}
««-defineHandler»»
"""


let handlerStubsTemplate = TextTemplate(templateSource) {
    (tpl: Node, args: (libraryName: String, handlerGlues: [HandlerGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.defineHandler.map(args.handlerGlues.filter{ !($0.interface.result is AsItself) }) {
        (node: Node, glue: HandlerGlue) -> Void in
        node.functionName.set(glue.swiftName)
        node.libraryName.set(args.libraryName)
      //  let scopes = glue.useScopes.map{(Symbol($0), Symbol($0), asScope) as HandlerInterface.Parameter}
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


extension HandlerGlue {
    
    var swiftParameters: [(label: String, binding: String?, type: String)] { // used in primitive handler function stubs; label may include binding name (TO DO: we should probably split binding name into separate String?)
        let params: [(String, String, String)]
        let nativeParameters = self.interface.parameters.map{(camelCase($0.name.label), camelCase($0.binding.label), $0.coercion.swiftTypeDescription)}
        if let swiftParams = self.swiftFunction?.params, swiftParams.count == nativeParameters.count {
            params = zip(swiftParams, nativeParameters).map{($0, $1.1, $1.2)}
        } else {
            params = nativeParameters
        }
        return params.map{($0, ($0 == $1 || $1.isEmpty ? nil : $1), $2)} + self.useScopes.map{($0, nil, "Scope")}
    }
}
