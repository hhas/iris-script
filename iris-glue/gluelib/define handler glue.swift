//
//  handler glue.swift
//  gluelib
//
//

import Foundation
import iris

// TO DO: should stdlib be baked into libiris? or should it be built as a separate static/dynamic linked module?

// TO DO: sort 'name' vs 'label' naming convention for all args+params

// TO DO: what about name/arg aliasing (including deprecated names)? (i.e. establishing a formal mechanism for amending an existing interface design enables automatic upgrading of user scripts)

// TO DO: what about introspecting the Swift func's API, e.g. to extract parameter names and primitive types, `throws`, and primitive return type? (also check for scope and coercion params); see: https://github.com/apple/swift-syntax

// TO DO: need `swift` coercion modifier to indicate where arguments/results should be bridged to Swift primitives (String, Array<T>, etc) rather than passed as native Values (TBH, for bridging it probably makes more sense to assume Swift types unless a Value type is explicitly specified)

// TO DO: would be helpful to validate swift function/binding names against list of known Swift keywords (and identifiers in Swift stdlib?) in order to reject/warn of any name conflicts

// TO DO: distinguish between swift_function, swift_struct, etc; this'll allow stub template to create appropriate skeleton (currently ElementRange stub renders as a func instead of struct+init)



// TO DO: replace this dict with standard record unpacking (caveat this allows fields to appear in any order and always requires labels, whereas record fields are ordered and labels can be omitted); best to leave as-is until glue APIs are finalized (including record-to-struct bridging)
typealias Options = [String: Value]

extension Options {

    func value<T: SwiftCoercion>(named name: String, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        return try coercion.coerce(self[name] ?? nullValue, in: scope)
    }
}


let asLiteralCommand = AsLiteral<Command>()

let asSymbols = AsArray(asSymbol)


func defineHandlerGlue(interface: HandlerType, requirements: HandlerGlueRequirements, commandEnv: Scope, handlerEnv: Scope) throws {
    print("Defining handler glue for:", interface)
    guard let handlerGlues = handlerEnv.get(handlerGluesKey) as? OpaqueHandlerGlues else {
        throw UnknownNameError(name: handlerGluesKey, in: handlerEnv)
    }
    let glue = HandlerGlue(interface: interface, requirements: requirements)
    if handlerGlues.data[Symbol(glue.signature)] == nil {
        handlerGlues.data[Symbol(glue.signature)] = glue
    } else {
        print("Error: ignoring duplicate definition for: \(interface)")
    }
}

