//
//  handler template.swift
//  gluelib
//

import Foundation


// TO DO: would be simpler if type def's parameter tuple could be passed directly to interface params, but Swift doesn't want to downcast it ("Cannot express tuple conversion…")

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
	««+typeParameters»»
    param_««count»»: (Symbol("««nativeName»»"), ««coercion»»),
	««-typeParameters»»
    result: ««returnType»»
)
private let interface_««signature»» = HandlerInterface(
    name: "««nativeName»»",
    parameters: [
    ««+interfaceParameters»»
		(type_««signature»».param_««count»».0, "««bindingName»»", type_««signature»».param_««count»».1),
    ««-interfaceParameters»»
    ],
    result: type_««signature»».result
)
private func procedure_««signature»»(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    ««+unboxArguments»»
    let arg_««count»» = try command.swiftValue(at: &index, for: type_««signature»».param_««count»», in: commandEnv)
    ««-unboxArguments»»

    ««+checkForUnexpectedArguments»»
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
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



let handlersTemplate = TextTemplate(templateSource) { (tpl: Node, args: (libraryName: String, handlerGlues: [HandlerGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.defineHandler.map(args.handlerGlues) { (node: Node, glue: HandlerGlue) -> Void in
        node.signature.set(glue.signature)
        node.nativeName.set(glue.name)
        node.nativeArgumentNames.set(glue.parameters.map{$0.name}.joined(separator: ", "))
        node.typeParameters.map(glue.parameters.enumerated()) {
            (node: Node, item: (count: Int, param: HandlerGlue.Parameter)) -> Void in
            node.count.set(item.count)
            node.nativeName.set(item.param.name)
            node.coercion.set(item.param.coercion)
        }
        node.returnType.set(glue.result)
        node.interfaceParameters.map(glue.parameters.enumerated()) {
            (node: Node, item: (count: Int, param: HandlerGlue.Parameter)) -> Void in
            node.signature.set(glue.signature)
            node.bindingName.set(item.param.binding)
            node.count.set(item.count)
        }
        node.unboxArguments.map(0..<glue.parameters.count) { (node: Node, count: Int) -> Void in
            node.signature.set(glue.signature)
            node.count.set(count)
        }
        if glue.result == "asNothing" {
            node.resultAssignment.delete()
            node.returnIfResult.delete()
            node.returnIfNoResult.signature.set(glue.signature)
        } else {
            node.returnIfNoResult.delete()
            node.returnIfResult.signature.set(glue.signature)
        }
        if !glue.canError { node.tryKeyword.delete() }
        node.functionName.set(glue.swiftName)
        node.functionArguments.map(glue.swiftParameters) { (node: Node, item: (label: String, param: String)) -> Void in
            node.label.set(item.label)
            node.argument.set(item.param)
        }
    }
    tpl.loadHandlers.map(args.handlerGlues) { (node: Node, glue: HandlerGlue) -> Void in
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
    
    var _swiftParameters: [String] {
        if let params = self.swiftFunction?.params, params.count == self.parameters.count {
            return params
        } else {
            return self.parameters.map{camelCase($0.name)}
        }
    }
    
    var swiftParameters: [(String, String)] {
        return self._swiftParameters.enumerated().map{($1, "arg_\($0)")} + self.useScopes.map{($0, $0)}
    }
    
    var signature: String { return self.swiftName + "_" + self._swiftParameters.joined(separator: "_") }
}

