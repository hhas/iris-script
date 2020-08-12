//
//  define enum glue.swift
//  iris-glue
//

import Foundation
import iris


func defineEnumGlue(options: [Symbol], attributes: Value, commandEnv: Scope, handlerEnv: Scope) throws {
    print("Defining enum glue for:", options)
    guard let coercionGlues = handlerEnv.get(enumGluesKey) as? OpaqueEnumGlues else {
        throw UnknownNameError(name: enumGluesKey, in: handlerEnv)
    }
    guard let body = attributes as? Record else {
        throw TypeCoercionError(value: attributes, coercion: asRecord)
    }
    let requirements = Options(uniqueKeysWithValues: body.data.map{ ($0.key, $1) })
    let name = try requirements.value(named: "name", in: commandEnv, as: AsSwiftOptional(asString))
    let swiftType = try requirements.value(named: "swift_name", in: commandEnv, as: AsSwiftOptional(asString))
        ?? (name == nil ? options.map{ camelCase($0.label, uppercaseFirst: true) }.joined(separator: "")
                        : camelCase(name!, uppercaseFirst: true))
    let swiftCases = try requirements.value(named: "swift_cases", in: commandEnv, as: AsSwiftDefault(AsArray(asString), []))
    if coercionGlues.data[Symbol(swiftType)] == nil {
        coercionGlues.data[Symbol(swiftType)] = EnumGlue(options: options, name: name,
                                                         swiftType: swiftType, swiftCases: swiftCases)
    } else {
        print("Error: ignoring duplicate coercion definition for: \(swiftType)")
    }
}
