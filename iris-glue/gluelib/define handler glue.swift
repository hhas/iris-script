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


func defineHandlerGlue(interface: HandlerType, attributes: Value, commandEnv: Scope, handlerEnv: Scope) throws {
    print("Defining handler glue for:", interface)
    guard let handlerGlues = handlerEnv.get(handlerGluesKey) as? OpaqueHandlerGlues else {
        throw UnknownNameError(name: handlerGluesKey, in: handlerEnv)
    }
    guard let body = attributes as? Record else { // TO DO: glue currently uses asIs to pass record without any evaluation, leaving defineHandlerGlue to extract its fields below; eventually handler_glue record should be defined as a SwiftCoercion with named+typed fields, allowing it to unbox directly to HandlerGlue
        throw TypeCoercionError(value: attributes, coercion: asRecord)
    }
    let options = Options(uniqueKeysWithValues: body.data.map{ ($0.key, $1) })
    let canError = try options.value(named: "can_error", in: commandEnv, as: AsSwiftDefault(asBool, false))
    let swiftFunction: HandlerGlue.SwiftFunction?
    if let cmd = try options.value(named: "swift_function", in: commandEnv, as: AsSwiftOptional(asLiteralCommand)) {
        // TO DO: if given, swiftfunc's parameter record should be of form `{label,…}` and/or `{label:binding,…}` (currently only the first is accepted)
        // TO DO: error if no. of Swift params is neither 0 nor equal to no. of native params
        swiftFunction = (name: cmd.name.label, params: try cmd.arguments.map{
            guard let name = $0.value.asIdentifier() else {
                throw TypeCoercionError(value: $0.value, coercion: asLiteralName) // TO DO: it would be better for error reporting purposes to move this logic into a custom coercion for matching+unwrapping the entire command
            }
            return name.label
        })
    } else {
        swiftFunction = nil
    }
    let useScopes = try options.value(named: "use_scopes", in: commandEnv, as: AsSwiftDefault(asSymbols, [])).map{"\($0.key)Env"} // TO DO: enum
    let patternScope = PatternDialect(parent: commandEnv, for: interface)
    let operatorSyntax = try options.value(named: "operator", in: patternScope, as: AsSwiftOptional(asOperatorSyntax))
    let glue = HandlerGlue(interface: interface, canError: canError, useScopes: useScopes,
                           swiftFunction: swiftFunction, operatorSyntax: operatorSyntax)
    if handlerGlues.data[Symbol(glue.signature)] == nil {
        handlerGlues.data[Symbol(glue.signature)] = glue
    } else {
        print("Error: ignoring duplicate definition for: \(interface)")
    }
}

