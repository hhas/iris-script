//
//  define coercion glue.swift
//  iris-glue
//

import Foundation
import iris


func defineCoercionGlue(swiftType: Symbol, attributes: Value, commandEnv: Scope, handlerEnv: Scope) throws {
    print("Defining coercion glue for:", swiftType)
    guard let coercionGlues = handlerEnv.get(coercionGluesKey) as? OpaqueCoercionGlues else {
        throw UnknownNameError(name: coercionGluesKey, in: handlerEnv)
    }
    guard let body = attributes as? Record else {
        throw TypeCoercionError(value: attributes, coercion: asRecord)
    }
    let options = Options(uniqueKeysWithValues: body.data.map{ ($0.key, $1) })
    let swiftName = try options.value(named: "swift_binding", in: commandEnv, as: AsSwiftOptional(asString))
    let aliases = try options.value(named: "aliases", in: commandEnv, as: AsSwiftDefault(AsArray(asString), []))
    let constructor: HandlerGlue?
    if let constructorArguments = try options.value(named: "constraints", in: commandEnv, as: AsSwiftOptional(asRecordType)) { // constraint handler must take at least 1 argument
        if constructorArguments.fields.isEmpty { throw ConstraintCoercionError(value: body, coercion: asRecordType) }
        let canError = try options.value(named: "can_error", in: commandEnv, as: AsSwiftDefault(asBool, false))
        let handlerType = HandlerType(name: "", parameters: constructorArguments.fields, result: asCoercion.nativeCoercion)
        
        let swiftFunction = try options.value(named: "swift_function", in: commandEnv, as: AsSwiftOptional(asLiteralCommand))
        let patternScope = PatternDialect(parent: commandEnv, for: handlerType)
        let operatorDefinition = try options.value(named: "operator", in: patternScope, as: AsSwiftOptional(asOperatorDefinition))
        let requirements = HandlerGlueRequirements(canError: canError, useScopes: [],
            swiftFunction: swiftFunction, operatorDefinition: operatorDefinition)
        constructor = HandlerGlue(interface: handlerType, requirements: requirements)
    } else {
        constructor = nil
    }
    if coercionGlues.data[swiftType] == nil {
        coercionGlues.data[swiftType] = CoercionGlue(swiftType: swiftType.label, swiftName: swiftName,
                                                     aliases: aliases, constructor: constructor)
    } else {
        print("Error: ignoring duplicate coercion definition for: \(swiftType)")
    }
}