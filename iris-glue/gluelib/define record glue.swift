//
//  define record glue.swift
//  iris-glue
//

import Foundation
import iris

// TO DO: how to support nested structs? e.g. HandlerGlue.OperatorDefinition (for now, use a top-level typealias)

// `swift_record {…} requires {…}`

// TO DO: should interface be HandlerType, allowing name to be passed there rather than in body? (if we do, should coercions installed in env use that name as a record constructor? this'd be similar to syntax for parameterizing coercions via callable coercion, except the argument would be a record of some/all field values and the result would be a constructed record with all fields labeled, populated, and coerced/constraint-checked)

func defineRecordGlue(interface: NamedRecordType, requirements: RecordGlueRequirements, commandEnv: Scope, handlerEnv: Scope) throws {
    print("Defining record glue for:", interface)
    guard let recordGlues = handlerEnv.get(recordGluesKey) as? OpaqueRecordGlues else {
        throw UnknownNameError(name: recordGluesKey, in: handlerEnv)
    }
    let name = interface.name
    if recordGlues.data[name] == nil {
        recordGlues.data[name] = RecordGlue(interface: interface, requirements: requirements)
    } else {
        print("Error: ignoring duplicate record definition for: \(interface)")
    }
    //
}
