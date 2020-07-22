//
//  operator glue template.swift
//  gluelib
//
//  generates operator definitions for primitive handler definitions that have an `operator:` field
//

import Foundation
import iris


// Operation(pattern: [.keyword(name)], precedence: precedence, associate: associate)


private let templateSource = """
//
//  ««libraryName»»_operators.swift
//
//  Bridging code for primitive handlers. This file is auto-generated; do not edit directly.
//

import Foundation

func stdlib_loadOperators(into registry: OperatorRegistry) {
««+loadOperators»»
    registry.add(««args»»)
««-loadOperators»»
}

"""


let operatorsTemplate = TextTemplate(templateSource) { (tpl: Node, args: (libraryName: String, handlerGlues: [HandlerGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.loadOperators.map(args.handlerGlues.filter{$0.operatorSyntax != nil}.map{$0.operatorSyntax!}) {
        (node: Node, syntax: HandlerGlue.OperatorSyntax) -> Void in
        node.args.set(
            "\(syntax.pattern.swiftLiteralDescription), \(syntax.precedence), .\(syntax.associate), \(syntax.reducefunc)")
    }
}



