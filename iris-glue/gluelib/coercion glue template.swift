//
//  coercion glue template.swift
//  gluelib
//
//  generates primitive coercion glue code
//

import Foundation
import iris


private let templateSource = """
//
//  ««libraryName»»_coercions.swift
//
//  Handler extensions for constructing constrained coercions.
//
//  This file is auto-generated; do not edit directly.
//

import Foundation

««+defineConstructor»»

extension ««swiftType»»: ConstrainableCoercion {
    
    private static let type_constrain = (
        ««+typeParameters»»
        param_««count»»: (Symbol("««label»»"), Symbol("««binding»»"), ««coercion»»),
        ««-typeParameters»»
        _: ()
    )
    
    public var interface: HandlerType {
        return HandlerType(
            name: self.name,
            parameters: [
                ««+interfaceParameters»»
                nativeParameter(Self.type_constrain.param_««count»»),
                ««-interfaceParameters»»
            ],
            result: asCoercion.nativeCoercion
        )
    }
    
    public func constrain(to command: Command, in scope: Scope) throws -> NativeCoercion {
        var index = 0
        ««+unboxArguments»»
        let arg_««count»» = try command.value(for: Self.type_constrain.param_««count»», at: &index, in: scope)
        ««-unboxArguments»»
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: self) }
        return ««+tryKeyword»» try ««-tryKeyword»» ««swiftFunction»»(««+swiftArguments»»««label»»: ««argument»» ««~swiftArguments»», ««-swiftArguments»»)
    }
}

««-defineConstructor»»

public func stdlib_loadCoercions(into env: Environment) {
    ««+loadCoercions»»
    env.define(coercion: ««coercion»»)
    ««+aliases»»
    env.define("««binding»»", ««coercion»»)
    ««-aliases»»
    ««-loadCoercions»»
}
"""



let coercionsTemplate = TextTemplate(templateSource) {
    (tpl: Node, args: (libraryName: String, glues: [CoercionGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.defineConstructor.map(args.glues.filter{$0.constructor != nil}) {
        (node: Node, glue: CoercionGlue) -> Void in
        let constructor = glue.constructor!
        node.swiftType.set(glue.swiftType)
        node.typeParameters.map(constructor.parameters.enumerated()) {
            (node: Node, item: (count: Int, param: HandlerGlue.Parameter)) -> Void in
            node.count.set(item.count)
            node.label.set(item.param.label)
            node.binding.set(item.param.binding)
            node.coercion.set(item.param.coercion)
        }
        node.interfaceParameters.map(0..<constructor.parameters.count) {
            (node: Node, count: Int) -> Void in
            node.count.set(count)
        }
        node.unboxArguments.map(0..<constructor.parameters.count) {
            (node: Node, count: Int) -> Void in
            node.count.set(count)
        }
        if !constructor.canError { node.tryKeyword.delete() }
        node.swiftFunction.set(constructor.swiftName.isEmpty ? glue.swiftType : constructor.swiftName) // this is usually, but not always, same as swiftType
        node.swiftArguments.map(constructor.swiftArguments) {
            (node: Node, item: (label: String, param: String)) -> Void in
            node.label.set(item.label)
            node.argument.set(item.param)
        }
    }
    tpl.loadCoercions.map(args.glues) {
        (node: Node, glue: CoercionGlue) -> Void in
        let value = glue.constructor == nil ? glue.swiftName : "CallableCoercion(\(glue.swiftName))"
        node.coercion.set(value)
        node.aliases.map(glue.aliases) {
            (node: Node, alias: String) -> Void in
            node.binding.set(alias)
            node.coercion.set(value)
        }
    }
}

