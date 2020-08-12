//
//  operator glue template.swift
//  gluelib
//
//  generates operator definitions for primitive handler definitions that have an `operator:` field
//

import Foundation
import iris


// TO DO: operators currently use first keyword’s name as command name; should there be an option to supply custom name? (ideally the command name should be same as existing operator keyword to avoid adding extra—and unexpected—names to namespace, but occasionally it may be beneficial to name handler after, say, operator’s alias rather than canonical name, e.g. mapping unary `-` to `negative` handler)


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


let operatorsTemplate = TextTemplate(templateSource) {
    (tpl: Node, args: (libraryName: String, glues: [HandlerGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.loadOperators.map(args.glues.compactMap{ $0.operatorSyntax }) {
        (node: Node, syntax: OperatorSyntax) -> Void in
        let reducefunc: String
        if let reducer = syntax.reducer { reducefunc = ", \(reducer)" } else { reducefunc = "" }
        let pattern: String
        switch syntax.pattern {
        case .sequence:  pattern = syntax.pattern.swiftLiteralDescription
        default:         pattern = "[\(syntax.pattern.swiftLiteralDescription)]"
        }
        node.args.set("\(pattern), \(syntax.precedence), .\(syntax.associate)\(reducefunc)")
    }
}

