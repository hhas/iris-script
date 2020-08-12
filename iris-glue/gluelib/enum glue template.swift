//
//  enum glue template.swift
//  iris-glue
//

import Foundation
import iris

// TO DO: enum stub template

// TO DO: as with record glue template, these are generating Coercions


private let templateSource = """
//
//  ««libraryName»»_operators.swift
//
//  Bridging code for primitive enums. This file is auto-generated; do not edit directly.
//

import Foundation

««+defineEnum»»

public struct As««swiftType»»: SwiftCoercion {
    
    public typealias SwiftType = ««swiftType»»
    
    public let name: Symbol = "««coercionName»»"
    
    public var swiftLiteralDescription: String { return "as««swiftType»»" }

    public var literalDescription: String { return self.name.label }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        switch try asSymbol.coerce(value, in: scope) {
        ««+cases»»
        case ««nativeCase»»: return .««swiftCase»»
        ««-cases»»
        }
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        switch value {
        ««+cases»»
        case .««swiftCase»»: return ««nativeCase»»
        ««-cases»»
        }
    }
}

public let as««swiftType»» = As««swiftType»»()

««-defineEnum»»

"""


let enumsTemplate = TextTemplate(templateSource) {
    (tpl: Node, args: (libraryName: String, glues: [EnumGlue])) in
    tpl.libraryName.set(args.libraryName)
    tpl.defineEnum.map(args.glues) {
        (node: Node, glue: EnumGlue) -> Void in
        node.swiftType.set(glue.swiftType)
        node.coercionName.set(glue.name)
        node.cases.map(zip(glue.options, glue.swiftCases)) {
            (node: Node, item: (nativeCase: Symbol, swiftCase: String)) -> Void in
            node.nativeCase.set(item.nativeCase.swiftLiteralDescription)
            node.swiftCase.set(item.swiftCase)
        }
    }
}
