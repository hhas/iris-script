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
//  Operator definitions for primitive handlers.
//
//  This file is auto-generated; do not edit directly.
//

import Foundation

public func stdlib_loadOperators(into registry: OperatorRegistry) {
    ««+loadOperators»»
    registry.add(««args»»)
    ««-loadOperators»»
}

"""


let operatorsTemplate = TextTemplate(templateSource) {
    (tpl: Node, args: (libraryName: String, glues: [HandlerGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.loadOperators.map(args.glues) {
        (node: Node, glue: HandlerGlue) -> Void in
        guard let definition = glue.operatorDefinition else {
            node.delete()
            return
        }
        let reducefunc: String
        if let reducer = definition.reducer { reducefunc = ", \(reducer)" } else { reducefunc = "" }
        let patternScope = PatternDialect(parent: nullScope, for: glue.interface)
        do {
            let syntax = try asOperatorSyntax.coerce(definition.syntax, in: patternScope) // kludge
            let pattern: String
            switch syntax {
            case .sequence:  pattern = syntax.swiftLiteralDescription
            default:         pattern = "[\(syntax.swiftLiteralDescription)]"
            }
            node.args.set("\(pattern), \(definition.precedence), .\(definition.associate)\(reducefunc)")
        } catch {
            print(error)
            print()
            print(definition.syntax)
            exit(5)
        }
    }
}

