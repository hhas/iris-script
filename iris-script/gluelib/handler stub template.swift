//
//  handler stub template.swift
//  gluelib
//

import Foundation

// TO DO: need to sort out public vs internal declarations

// TO DO: disable whitespace auto-trimming (space after comma in param list currently isn't being preserved)

private let templateSource = """
//
//  ««libraryName»» HANDLERS.swift
//
//  Swift functions that implement primitive handlers.
//

import Foundation

««+defineHandler»»

func ««functionName»»(««+functionParameters»»\
««label»»««binding»»: ««argumentType»» ««~functionParameters»», \
««-functionParameters»») ««+canThrow»» throws ««-canThrow»» ««+hasReturnType»» -> ««returnType»» ««-hasReturnType»» {
    fatalError("Not yet implemented.")
}
««-defineHandler»»
"""


let handlerStubsTemplate = TextTemplate(templateSource) { (tpl: Node, args: (libraryName: String, handlerGlues: [HandlerGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.defineHandler.map(args.handlerGlues) { (node: Node, glue: HandlerGlue) -> Void in
        node.functionName.set(glue.swiftName)
        node.functionParameters.map(glue.interface.parameters) { (node: Node, item: HandlerInterface.Parameter) -> Void in
            node.label.set(item.name.label)
            if item.binding != item.name { node.binding.set(" " + camelCase(item.binding.label)) }
            node.argumentType.set(item.coercion.swiftTypeDescription)
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
