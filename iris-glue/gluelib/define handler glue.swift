//
//  handler glue.swift
//  gluelib
//
//

import Foundation
import iris

// TO DO: should stdlib be baked into libiris? or should it be built as a separate static/dynamic linked module?



// TO DO: operator syntax should eventually be expressible as patterns, e.g. `if condition:EXPR then action:EXPR (else alternative_action)?`

// TO DO: glue definitions could do with a `returns_self:true` property or `itself` return type for indicating a command should evaluate to itself; e.g. `foo returning bar` -> `foo returning bar`; currently stdlib glue manually defines `returning` as an operator, which is fine when used in a handler’s signature as `to` , but without an underlying command it will throw a not-found error if evaled (confusing to language explorers and useless for metaprogramming)

// TO DO: sort 'name' vs 'label' naming convention for all args+params

// TO DO: what about name/arg aliasing (including deprecated names)? (i.e. establishing a formal mechanism for amending an existing interface design enables automatic upgrading of user scripts)

// TO DO: what about introspecting the Swift func's API, e.g. to extract parameter names and primitive types, `throws`, and primitive return type? (also check for scope and coercion params); see: https://github.com/apple/swift-syntax

// TO DO: need `swift` coercion modifier to indicate where arguments/results should be bridged to Swift primitives (String, Array<T>, etc) rather than passed as native Values

// TO DO: would be helpful to validate swift function/binding names against list of known Swift keywords (and identifiers in Swift stdlib?) in order to reject/warn of any name conflicts

// TO DO: distinguish between swift_function, swift_struct, etc; this'll allow stub template to create appropriate skeleton (currently ElementRange stub renders as a func instead of struct+init)


// TO DO: glue definitions could be constructed by running the glue definition script with a custom Environment and custom/standard `to` handler, where evaluating the `to` operator's procedure operand populates a sub-scope that is a wrapper around/extension of HandlerGlue (for now we use a custom `to` handler that directly disassembles the procedure body, but this approach doesn't allow for metaprogramming); one caveat to evaluation strategy is that pair values need to be lazily evaluated - not entirely sure how to distinguish a command that returns the value to be used (e.g. when factoring out common information such as arithmetic operator definitions into a shared handler) from a command that is the value to be used (e.g. as in swift_function)

// TO DO: this is replaced with record
typealias Options = [String: Value]


extension Options {

    func value<T: SwiftCoercion>(named name: String, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        return try coercion.coerce(self[name] ?? nullValue, in: scope)
    }
    
    
}


let asLiteralCommand = AsLiteral<Command>()

let asSymbols = AsArray(asSymbol)

let asPatternValues = AsArray(asPatternValue)

let asOperatorSyntax = AsRecord([ // TO DO: given a native record/enum coercion, code generator should emit corresponding struct/enum definition and/or extension with static `unboxNativeValue()` method and primitive coercion // TO DO: rework this to allow patterns to be specified
    ("pattern", asPatternValues.nativeCoercion),
    ("precedence", asInt.nativeCoercion),
    ("associate", AsSwiftDefault(asSymbol, "left").nativeCoercion), // TO DO: need AsEnum(ofType,options)
    ("reducer", AsSwiftOptional(asSymbol).nativeCoercion)
    ])




func defineHandlerGlue(interface: HandlerInterface, attributes: Value, commandEnv: Scope, handlerEnv: Scope) throws {
    print("Making glue for:", interface)
    guard let handlerGlues = handlerEnv.get(handlerGluesKey) as? OpaqueHandlerGlues else {
        throw UnknownNameError(name: handlerGluesKey, in: handlerEnv)
    }
    guard let currentHandlerInterface = handlerEnv.get(currentHandlerInterfaceKey) as? OpaqueHandlerInterface else {
        throw UnknownNameError(name: currentHandlerInterfaceKey, in: handlerEnv)
    }
    currentHandlerInterface.data = interface // kludge; needed in newExpression to remap operand binding name to argument label name
    guard let body = attributes as? Record else { // TO DO: glue currently uses asIs to pass record without any evaluation, leaving defineHandlerGlue to extract its fields below; eventually handler_glue record should be defined as a SwiftCoercion with named+typed fields, allowing it to unbox directly to HandlerGlue
        print("bad attributes (not record):", attributes)
        throw BadSyntax.missingExpression
    }
    let options = Options(uniqueKeysWithValues: body.data.map{ ($0.key, $1) })
    let canError = try options.value(named: "can_error", in: commandEnv, as: AsSwiftDefault(asBool, false))
    let swiftFunction: HandlerGlue.SwiftFunction?
    //
    if let cmd = try options.value(named: "swift_function", in: commandEnv, as: AsSwiftOptional(asLiteralCommand)) {
        // TO DO: if given, swiftfunc's parameter record should be of form `{label,…}` and/or `{label:binding,…}`
        // TO DO: error if no. of Swift params is neither 0 nor equal to no. of native params
        swiftFunction = (name: cmd.name.label, params: try cmd.arguments.map{
            guard let name = $0.value.asIdentifier() else { throw BadSyntax.missingName }
            return name.label
        })
    } else {
        swiftFunction = nil
    }
    let useScopes = try options.value(named: "use_scopes", in: commandEnv, as: AsSwiftDefault(asSymbols, [])).map{"\($0.key)Env"}
    let operatorSyntax: HandlerGlue.OperatorSyntax?
    let patternScope = PatternDialect(parent: commandEnv)
    if let record = try options.value(named: "operator", in: patternScope, as: AsSwiftOptional(asOperatorSyntax)) {
        operatorSyntax = try unpackOperatorDefinition(record, in: patternScope)
    } else {
        operatorSyntax = nil
    }
    let name = interface.name
    if handlerGlues.data[name] == nil {
        handlerGlues.data[name] = HandlerGlue(interface: interface, canError: canError, useScopes: useScopes,
                                              swiftFunction: swiftFunction, operatorSyntax: operatorSyntax)
    } else {
        print("Error: ignoring duplicate definition for: \(interface)")
    }
}


func unpackOperatorDefinition(_ record: Record, in commandEnv: Scope) throws -> HandlerGlue.OperatorSyntax {
    // since main Env’s `expression` and `optional` slots already hold Coercions, create a subenv in which to lookup pattern commands; TO DO: this is kludgy: it creates a new instance for each definition, reloading and rebinding handlers each time; need to give scoping more thought
    let patterns = try! asPatternValues.coerce(record.data[0].value, in: commandEnv).map{$0.data}
    let patternSeq: [iris.Pattern]
    if patterns.count == 1, case .sequence(let seq) = patterns[0] {
        patternSeq = seq
    } else {
        patternSeq = patterns
    }
    let precedence = try! asInt.coerce(record.data[1].value, in: commandEnv) // native coercion may return Number
    let associativity: Associativity
    switch record.data[2].value as! Symbol {
    case "left", "none": // TO DO: Associativity doesn't currently support `none`
        associativity = .left
    case "right":
        associativity = .right
    default:
        print("malformed operator record", record)
        throw BadSyntax.missingExpression
    }
    let reducefunc = try! AsSwiftOptional(asSymbol).coerce(record.data[3].value, in: commandEnv)?.label
    return (patternSeq, precedence, associativity, reducefunc)
}


