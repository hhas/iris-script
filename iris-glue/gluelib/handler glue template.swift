//
//  handler glue template.swift
//  gluelib
//
//  generates primitive handler glue code
//

import Foundation
import iris

// TO DO: how to insert additional import statement[s]? e.g. non-built-in libraries need `import iris`


// TO DO: coercion parameter isn't being used


// TO DO: should `itself` validate command args? (currently returns Command as-is with no checking)

// TO DO: would be simpler if type def's parameter tuple could be passed directly to interface params, but Swift doesn't want to downcast it ("Cannot express tuple conversion…")

// TO DO: how best to structure argument unpacking so that Command can best optimize? (e.g. length check really only needs to be performed once, and both it and argument-to-parameter matching could easily be moved up to first-run and/or parse-time); that said, current arrangement is unlikely to be major performance sink

// TO DO: while texttemplate library is designed for plain text templating, maybe allow limited code-generation extensions, e.g. for literal string quoting: `««"someText"»»`

// command.swiftValue() needs to know coercion’s exact type in order to unbox given Value to SwiftType suitable for passing to underlying Swift func; thus it’s simplest to declare signatures in type_NAME.param_N tuples (while we could capture parameter info in a generic Parameter struct, it wouldn’t add any benefit)

private let templateSource = """
//
//  ««libraryName»»_handlers.swift
//
//  Handler wrappers for Swift functions.
//
//  This file is auto-generated; do not edit directly.
//

import Foundation

««+defineHandler»»

// ««nativeName»» {««nativeArguments»»}
private let type_««signature»» = (
    name: Symbol("««nativeName»»"),
	««+typeParameters»»
    param_««count»»: (Symbol("««label»»"), Symbol("««binding»»"), ««coercion»»),
	««-typeParameters»»
    result: ««returnType»»
)
private let interface_««signature»» = HandlerType(
    name: type_««signature»».name,
    parameters: [
    ««+interfaceParameters»»
        nativeParameter(type_««signature»».param_««count»»),
    ««-interfaceParameters»»
    ],
    result: type_««signature»».result.nativeCoercion
)
private func procedure_««signature»»(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    ««+body»»
    ««+procedureParameters»»
    var index = 0
    ««+unboxArguments»»
    let arg_««count»» = try command.value(for: type_««signature»».param_««count»», at: &index, in: commandEnv)
    ««-unboxArguments»»

    ««+checkForUnexpectedArguments»»
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    ««-checkForUnexpectedArguments»»
    ««-procedureParameters»»

    ««+checkForUnexpectedArguments»»
    if !command.arguments.isEmpty { throw UnknownArgumentError(at: 0, of: command, to: handler) }
    ««-checkForUnexpectedArguments»»

    ««+resultAssignment»»
    let result =
    ««-resultAssignment»»««+tryKeyword»» try ««-tryKeyword»» ««swiftName»»(««+swiftArguments»»««label»»: ««argument»» ««~swiftArguments»», ««-swiftArguments»»)
    ««+returnIfResult»»
    return type_««signature»».result.wrap(result, in: handlerEnv)
    ««-returnIfResult»»
    ««+returnIfNoResult»»
    return nullValue
    ««-returnIfNoResult»»
    ««-body»»
}
««-defineHandler»»



public func stdlib_loadHandlers(into env: Environment) {
    ««+loadHandlers»»
    env.define(interface_««signature»», procedure_««signature»»)
    ««-loadHandlers»»
}
"""


let handlersTemplate = TextTemplate(templateSource) {
    (tpl: Node, args: (libraryName: String, glues: [HandlerGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.defineHandler.map(args.glues) {
        (node: Node, glue: HandlerGlue) -> Void in
        node.signature.set(glue.signature)
        node.nativeName.set(glue.name)
        node.nativeArguments.set(glue.parameters.map{$0.label}.joined(separator: ", "))
        node.typeParameters.map(glue.parameters.enumerated()) {
            (node: Node, item: (count: Int, param: HandlerGlue.Parameter)) -> Void in
            node.count.set(item.count)
            node.label.set(item.param.label)
            node.binding.set(item.param.binding)
            node.coercion.set(item.param.coercion)
        }
        node.returnType.set(glue.result)
        node.interfaceParameters.map(glue.parameters.enumerated()) {
            (node: Node, item: (count: Int, param: HandlerGlue.Parameter)) -> Void in
            node.signature.set(glue.signature)
            node.count.set(item.count)
        }
        if glue.interface.result is AsItself {
            node.body.set("\n\treturn BoxedCommand(command)")
        } else {
            let node = node.body
            if glue.parameters.isEmpty {
                node.procedureParameters.delete()
            } else {
                node.checkForUnexpectedArguments.delete()
                node.procedureParameters.unboxArguments.map(0..<glue.parameters.count) {
                    (node: Node, count: Int) -> Void in
                    node.signature.set(glue.signature)
                    node.count.set(count)
                }
                if glue.interface.isEventHandler { node.procedureParameters.checkForUnexpectedArguments.delete() }
            }
            if glue.interface.result is AsNothing {
                node.resultAssignment.set("\n\t")
                node.returnIfResult.delete()
            } else {
                node.returnIfNoResult.delete()
                node.returnIfResult.signature.set(glue.signature)
            }
            if !glue.canError { node.tryKeyword.delete() }
            node.swiftName.set(glue.swiftName)
            node.swiftArguments.map(glue.swiftArguments) {
                (node: Node, item: (label: String, param: String)) -> Void in
                node.label.set(item.label)
                node.argument.set(item.param)
            }
        }
    }
    tpl.loadHandlers.map(args.glues) {
        (node: Node, glue: HandlerGlue) -> Void in
        node.signature.set(glue.signature)
    }
}



func camelCase(_ name: String, uppercaseFirst: Bool = false) -> String { // convert underscored_name to camelCase
    var result = ""
    var isUpper = uppercaseFirst
    for c in name {
        if c == "_" {
            isUpper = true
        } else if isUpper {
            result += c.uppercased()
            isUpper = false
        } else {
            result += String(c)
        }
    }
    return result
}


