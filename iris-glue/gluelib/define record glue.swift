//
//  define record glue.swift
//  iris-glue
//

import Foundation
import iris

// TO DO: how to support nested structs? e.g. HandlerGlue.OperatorSyntax (for now, use a top-level typealias)

// `swift_record {…} requires {…}`

// TO DO: should interface be HandlerType, allowing name to be passed there rather than in body? (if we do, should coercions installed in env use that name as a record constructor? this'd be similar to syntax for parameterizing coercions via callable coercion, except the argument would be a record of some/all field values and the result would be a constructed record with all fields labeled, populated, and coerced/constraint-checked)

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
    let name = try options.value(named: "name", in: commandEnv, as: AsSwiftOptional(asString))
        ?? fields.map{ $0.label.label }.joined(separator: "_")
    let structName = try options.value(named: "swift_name", in: commandEnv, as: AsSwiftOptional(asString))
        ??  camelCase(name, uppercaseFirst: true)
    let structFields = try options.value(named: "swift_fields", in: commandEnv, as: AsSwiftOptional(asRecordType))?.fields
        ?? fields.map{ (camelCase($0), camelCase($1), $2) }
    let canError = try options.value(named: "can_error", in: commandEnv, as: AsSwiftDefault(asBool, false))
    if recordGlues.data[Symbol(name)] == nil {
        recordGlues.data[Symbol(name)] = RecordGlue(fields: fields, name: name, structName: structName, structFields: structFields, canError: canError)
    } else {
        print("Error: ignoring duplicate record definition for: \(structName)")
    }
    //
}
