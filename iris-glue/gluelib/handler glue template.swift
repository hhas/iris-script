//
//  handler glue template.swift
//  gluelib
//
//  generates primitive handler glue code
//

import Foundation
import iris


// TO DO: would be simpler if type def's parameter tuple could be passed directly to interface params, but Swift doesn't want to downcast it ("Cannot express tuple conversion…")

// TO DO: how best to structure argument unpacking so that Command can best optimize? (e.g. length check really only needs to be performed once, and both it and argument-to-parameter matching could easily be moved up to first-run and/or parse-time); that said, current arrangement is unlikely to be major performance sink

// TO DO: while texttemplate library is designed for plain text templating, maybe allow limited code-generation extensions, e.g. for literal string quoting: `««"someText"»»`

// command.swiftValue() needs to know coercion’s exact type in order to unbox given Value to SwiftType suitable for passing to underlying Swift func; thus it’s simplest to declare signatures in type_NAME.param_N tuples (while we could capture parameter info in a generic Parameter struct, it wouldn’t add any benefit)

private let templateSource = """
//
//  ««libraryName»»_handlers.swift
//
//  Bridging code for primitive handlers. This file is auto-generated; do not edit directly.
//

import Foundation

««+defineHandler»»

// ««nativeName»» {««nativeArgumentNames»»}
private let type_««signature»» = (
    name: Symbol("««nativeName»»"),
	««+typeParameters»»
    param_««count»»: (Symbol("««label»»"), Symbol("««binding»»"), ««coercion»»),
	««-typeParameters»»
    result: ««returnType»»
)
private let interface_««signature»» = HandlerInterface(
    name: type_««signature»».name,
    parameters: [
    ««+interfaceParameters»»
		type_««signature»».param_««count»»,
    ««-interfaceParameters»»
    ],
    result: type_««signature»».result
)
private func procedure_««signature»»(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    ««+procedureParameters»»
    var index = 0
    ««+unboxArguments»»
    let arg_««count»» = try command.swiftValue(at: &index, for: type_««signature»».param_««count»», in: commandEnv)
    ««-unboxArguments»»

    ««+checkForUnexpectedArguments»»
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    ««-checkForUnexpectedArguments»»
    ««-procedureParameters»»

    ««+checkForUnexpectedArguments»»
    if !command.arguments.isEmpty { throw UnknownArgumentError(at: 0, of: command) }
    ««-checkForUnexpectedArguments»»

    ««+resultAssignment»»
    let result =
    ««-resultAssignment»»««+tryKeyword»» try ««-tryKeyword»» ««functionName»»(
    ««+functionArguments»»
    	««label»»: ««argument»» ««~functionArguments»»,
    ««-functionArguments»»
    )
    ««+returnIfResult»»
    return type_««signature»».result.box(value: result, in: handlerEnv)
    ««-returnIfResult»»
    ««+returnIfNoResult»»
    return nullValue
    ««-returnIfNoResult»»
}
««-defineHandler»»



public func stdlib_loadHandlers(into env: Environment) {
    ««+loadHandlers»»
    env.define(interface_««signature»», procedure_««signature»»)
    ««-loadHandlers»»
}
"""

let nullParameters: [HandlerGlue.Parameter] = [("", "", "()")]

let handlersTemplate = TextTemplate(templateSource) {
    (tpl: Node, args: (libraryName: String, handlerGlues: [HandlerGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.defineHandler.map(args.handlerGlues) {
        (node: Node, glue: HandlerGlue) -> Void in
        node.signature.set(glue.signature)
        node.nativeName.set(glue.name)
        node.nativeArgumentNames.set(glue.parameters.map{$0.name}.joined(separator: ", "))
        if glue.parameters.isEmpty {
            node.typeParameters.set("\n\t_: (),") // swiftc doesn't like single-item (`result`-only) tuples, so add placeholder field
        } else {
            node.typeParameters.map(glue.parameters.enumerated()) {
                (node: Node, item: (count: Int, param: HandlerGlue.Parameter)) -> Void in
                node.count.set(item.count)
                node.label.set(item.param.name)
                node.binding.set(item.param.binding)
                node.coercion.set(item.param.coercion)
            }
        }
        node.returnType.set(glue.result)
        node.interfaceParameters.map(glue.parameters.enumerated()) {
            (node: Node, item: (count: Int, param: HandlerGlue.Parameter)) -> Void in
            node.signature.set(glue.signature)
            node.count.set(item.count)
        }
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
        node.functionName.set(glue.swiftName)
        node.functionArguments.map(glue.swiftArguments) {
            (node: Node, item: (label: String, param: String)) -> Void in
            node.label.set(item.label)
            node.argument.set(item.param)
        }
    }
    tpl.loadHandlers.map(args.handlerGlues) {
        (node: Node, glue: HandlerGlue) -> Void in
        node.signature.set(glue.signature)
    }
}



func camelCase(_ name: String) -> String { // convert underscored_name to camelCase
    var result = ""
    var isUpper = false
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


extension HandlerGlue {
    
    var swiftName: String { return self.swiftFunction?.name ?? camelCase(self.name) }
    
    var _swiftArguments: [String] {
        if let params = self.swiftFunction?.params, params.count == self.parameters.count {
            return params
        } else {
            return self.parameters.map{camelCase($0.name)}
        }
    }
    
    var swiftArguments: [(String, String)] {
        return self._swiftArguments.enumerated().map{($1, "arg_\($0)")} + self.useScopes.map{($0, $0)}
    }
    
    var signature: String { return self.swiftName + "_" + self._swiftArguments.joined(separator: "_") }
}

