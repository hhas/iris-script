//
//  operator template.swift
//  iris-script
//

import Foundation



private let templateSource = """
//
//  ««libraryName»»_operators.swift
//
//  Bridging code for primitive handlers. This file is auto-generated; do not edit directly.
//

import Foundation

func stdlib_loadOperators(into registry: OperatorRegistry) {
««+loadOperators»»
    registry.add("««operatorName»»", ««form»», ««precedence»», ««associativity»», [««aliases»»])
««-loadOperators»»
}


"""


let operatorsTemplate = TextTemplate(templateSource) { (tpl: Node, args: (libraryName: String, handlerGlues: [HandlerGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.loadOperators.map(args.handlerGlues.filter{$0.operatorSyntax != nil}) { (node: Node, glue: HandlerGlue) -> Void in
        node.operatorName.set(glue.name)
        node.form.set(glue.operatorSyntax!.form)
        node.precedence.set(glue.operatorSyntax!.precedence)
        node.associativity.set(glue.operatorSyntax!.isLeftAssociative ? ".left" : ".right")
        node.aliases.set(glue.operatorSyntax!.aliases.map{$0.debugDescription}.joined(separator: ", "))
    }
}



