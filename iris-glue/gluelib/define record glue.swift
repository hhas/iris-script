//
//  define record glue.swift
//  iris-glue
//

import Foundation
import iris

// TO DO: how to support nested structs? e.g. HandlerGlue.OperatorSyntax (for now, use a top-level typealias)

// `swift_record {…} requires {…}`

func defineRecordGlue(interface: RecordType, attributes: Value, commandEnv: Scope, handlerEnv: Scope) throws {
    print("Defining record glue for:", interface)
    guard let recordGlues = handlerEnv.get(recordGluesKey) as? OpaqueRecordGlues else {
        throw UnknownNameError(name: recordGluesKey, in: handlerEnv)
    }
    
    guard let body = attributes as? Record else {
        throw TypeCoercionError(value: attributes, coercion: asRecord)
    }
    let fields = interface.fields
    let options = Options(uniqueKeysWithValues: body.data.map{ ($0.key, $1) })
    let structName = try options.value(named: "swift_name", in: commandEnv, as: asString)
    let structFields = try options.value(named: "swift_fields", in: commandEnv, as: AsSwiftOptional(asRecordType))?.fields ?? fields.map{ (camelCase($0), camelCase($1), $2) }
    let canError = try options.value(named: "can_error", in: commandEnv, as: AsSwiftDefault(asBool, false))
    let name = Symbol(structName)
    if recordGlues.data[name] == nil {
        recordGlues.data[name] = RecordGlue(fields: fields, structName: structName, structFields: structFields, canError: canError)
    } else {
        print("Error: ignoring duplicate record definition for: \(structName)")
    }
    //
}
