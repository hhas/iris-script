//
//  handlers template.swift
//  template-renderer
//

import Foundation



private let templateSource = """
//
//  ««libraryName»»_handlers.swift
//
//  Bridging code for primitive handlers. This file is auto-generated; do not edit directly.
//

import Foundation

««+defineHandler»»

// ««nativeName»» {««nativeArgumentNames»»}
private let type_««signatureName»» = (
	««+signatureParameters»»
    param_««count»»: ««coercion»»,
	««-signatureParameters»»
    result: ««returnType»»
)
private let interface_««signatureName»» = HandlerInterface(
    name: "««nativeName»»",
    parameters: [
    ««+interfaceParameters»»
		("««nativeName»»", "", type_««signatureName»».param_««count»»),
    ««-interfaceParameters»»
    ],
    result: type_««signatureName»».result
)
private func procedure_««signatureName»»(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var index = 0
    ««+unboxArguments»»
    let arg_««count»» = try command.swiftValue(at: &index, for: type_««signatureName»».param_««count»», in: commandEnv)
    ««-unboxArguments»»

    ««+checkForUnexpectedArguments»»
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command) }
    ««-checkForUnexpectedArguments»»

    ««+resultAssignment»»
    let result =
    ««-resultAssignment»»««+tryKeyword»» try ««-tryKeyword»» ««functionName»»(
    ««+functionArguments»»
    	««label»»: ««value»» ««/functionArguments»»,
    ««-functionArguments»»
    )
    ««+returnIfResult»»
    return try type_««signatureName»».result.box(value: result, env: handlerEnv)
    ««-returnIfResult»»
    ««+returnIfNoResult»»
    return nullValue
    ««-returnIfNoResult»»
}
««-defineHandler»»



public func stdlib_loadHandlers(env: Environment) {
    ««+loadHandlers»»
    env.define(interface_««signatureName»», procedure_««signatureName»»)
    ««-loadHandlers»»
}
"""



let handlersTemplate = TextTemplate(templateSource) { (tpl: Node, args: (libraryName: String, handlerGlues: [HandlerGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.defineHandler.map(args.handlerGlues) { (node: Node, glue: HandlerGlue) -> Void in
        node.signatureName.set(glue.signatureName)
        node.nativeName.set(glue.name)
        node.nativeArgumentNames.set(glue.parameters.map{$0.label}.joined(separator: ", "))
        node.signatureParameters.map(glue.parameters.enumerated()) {
            (node: Node, item: (count: Int, param: HandlerGlue.Parameter)) -> Void in
            node.count.set(item.count)
            node.coercion.set(item.param.coercion)
        }
        node.returnType.set(glue.result)
        node.interfaceParameters.map(glue.parameters.enumerated()) {
            (node: Node, item: (count: Int, param: HandlerGlue.Parameter)) -> Void in
            node.nativeName.set(item.param.label)
            node.signatureName.set(glue.signatureName)
            node.count.set(item.count)
        }
        node.unboxArguments.map(0..<glue.parameters.count) { (node: Node, count: Int) -> Void in
            node.signatureName.set(glue.signatureName)
            node.count.set(count)
        }
        if glue.result == "asNothing" {
            node.resultAssignment.delete()
            node.returnIfResult.delete()
            node.returnIfNoResult.signatureName.set(glue.signatureName)
        } else {
            node.returnIfNoResult.delete()
            node.returnIfResult.signatureName.set(glue.signatureName)
        }
        if !glue.canError {
            node.tryKeyword.delete()
        }
        node.functionName.set(glue.swiftName)
        node.functionArguments.map(glue.swiftParameters) { (node: Node, item: (label: String, param: String)) -> Void in
            node.label.set(item.label)
            node.value.set(item.param)
        }
    }
    tpl.loadHandlers.map(args.handlerGlues) { (node: Node, glue: HandlerGlue) -> Void in
        node.signatureName.set(glue.signatureName)
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
            return self.parameters.map{camelCase($0.label)}
        }
    }
    
    var swiftParameters: [(String, String)] {
        return self._swiftParameters.enumerated().map{("arg_\($0)", $1)} + self.useScopes.map{($0, $0)}
    }
    
    var signatureName: String { return self.swiftName + "_" + self._swiftParameters.joined(separator: "_") }
}

