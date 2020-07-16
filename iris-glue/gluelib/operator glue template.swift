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
    registry.««call»»
««-loadOperators»»
}

"""


let operatorsTemplate = TextTemplate(templateSource) { (tpl: Node, args: (libraryName: String, handlerGlues: [HandlerGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.loadOperators.map(args.handlerGlues.filter{$0.operatorSyntax != nil}) { (node: Node, glue: HandlerGlue) -> Void in
        
        //(««operatorName»», ««precedence»», ««associativity»»)
        let call: String
        let syntax = glue.operatorSyntax!
        let name = syntax.keywords.isEmpty ? glue.name : syntax.keywords[0]
        let reducefunc = syntax.reducefunc == nil ? "" : ", reducer: \(syntax.reducefunc!)"
        switch syntax.form {
        case "atom":
            call = "atom(\"\(name)\"\(reducefunc))"
        case "prefix":
            call = "prefix(\"\(name)\", \(syntax.precedence)\(reducefunc))"
        case "infix":
            call = "infix(\"\(name)\", \(syntax.precedence), .\(syntax.associate)\(reducefunc))"
        case "postfix":
            call = "postfix(\"\(name)\", \(syntax.precedence)\(reducefunc))"
        case "prefix_with_conjunction" where syntax.keywords.count == 2:
            call = "prefix(\"\(name)\", conjunction: \"\(syntax.keywords[1])\", \(syntax.precedence)\(reducefunc))"
        case "prefix_with_two_conjunctions" where syntax.keywords.count == 3:
            call = "prefix(\"\(name)\", conjunction: \"\(syntax.keywords[1])\", alternate: \"\(syntax.keywords[2])\", \(syntax.precedence)\(reducefunc))"
        default:
            print("Glue Error: Bad operator definition for \(glue.name).")
            call = "atom(\(name)) // ERROR: Bad operator definition." // placeholder
        }
        node.call.set(call)
    }
}



