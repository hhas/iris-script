//
//  handler glue.swift
//  gluelib
//
//

import Foundation

// TO DO: sort 'name' vs 'label' naming convention for all args+params

// TO DO: what about name/arg aliasing (including deprecated names)? (i.e. establishing a formal mechanism for amending an existing interface design enables automatic upgrading of user scripts)

// TO DO: what about introspecting the Swift func's API, e.g. to extract parameter names and primitive types, `throws`, and primitive return type?

// TO DO: need `swift` coercion modifier to indicate where arguments/results should be bridged to Swift primitives (String, Array<T>, etc) rather than passed as native Values

// TO DO: would be helpful to validate swift function/binding names against list of known Swift keywords (and identifiers in Swift stdlib?) in order to reject/warn of any name conflicts

// TO DO: distinguish between swift_function, swift_struct, etc; this'll allow stub template to create appropriate skeleton (currently ElementRange stub renders as a func instead of struct+init)


var _handlerGlues = [HandlerGlue]()


// TO DO: glue definitions could be constructed by running the glue definition script with a custom Environment and custom/standard `to` handler, where evaluating the `to` operator's procedure operand populates a sub-scope that is a wrapper around/extension of HandlerGlue (for now we use a custom `to` handler that directly disassembles the procedure body, but this approach doesn't allow for metaprogramming); one caveat to evaluation strategy is that pair values need to be lazily evaluated - not entirely sure how to distinguish a command that returns the value to be used (e.g. when factoring out common information such as arithmetic operator definitions into a shared handler) from a command that is the value to be used (e.g. as in swift_function)


struct HandlerGlue: Value {
    
    var description: String { return "«HandlerGlue \(self.interface) \(self.canError), \(self.useScopes), \(String(describing: self.swiftFunction)), \(String(describing: self.operatorSyntax))»"}
    static let nominalType: Coercion = AsComplex<HandlerGlue>(name: "HandlerGlue")
    
    // TO DO: also extract user documentation (from annotations); Q. where should user docs go? may be an idea to put them in separate data file that is loaded as needed (or just use the native glue def itself, assuming it isn't too slow to parse)
    typealias Parameter = (name: String, binding: String, coercion: String)
    
    typealias SwiftFunction = (name: String, params: [String])
    typealias OperatorSyntax = (form: String, precedence: Int, isLeftAssociative: Bool, aliases: [String])
    
    let interface: HandlerInterface
    
    var name: String { return self.interface.name.label }
    var parameters: [Parameter] { return self.interface.parameters.map{($0.name.label, $0.binding.label, $0.coercion.swiftLiteralDescription)} }
    var result: String { return self.interface.result.swiftLiteralDescription } // coercion name
    
    let canError: Bool
    let useScopes: [String] // commandEnv, handlerEnv // TO DO: any use-cases for per-invocation sub-env?
    let swiftFunction: SwiftFunction? // if different to native names
    let operatorSyntax: OperatorSyntax?
}

typealias Options = [String: Value]

func readOptions(_ block: Block, _ result: inout Options) throws {
    for option in block.data {
        switch option {
        case let block as Block:
            try readOptions(block, &result)
        case let pair as Pair:
            guard let name = pair.key.asIdentifier() else {throw BadSyntax.missingExpression}
            result[name.key] = pair.value
        default:
            throw BadSyntax.missingExpression
        }
    }
}

// performs full eval of right-side (e.g. `true`/`false` are commands which return corresponding Bool values, so either we eval them for can_error or else we unbox asCommand and use asIdentifier + switch to determine if true or false; right now we don't really care, but longer term we need to figure out how metaprogramming should behave, e.g. when distinguishing literal values from calculated [command-returned] values; on the one hand, glue definitions for e.g. arithmetic and comparison operators could themselves be generated by parameterizing the bits that change; on the other, that requires distinguishing between commands that should be evaled and commands that should be manipulated as-is [in kiwi this is trivial as tags provide orthogonal substitution mechanism which can be used within command names and args, but here commands do both so are not so easily rewritable])
func unpackOption<T: SwiftCoercion>(_ options: Options, _ name: String, in scope: Scope, as coercion: T) throws -> T.SwiftType {
    return try (options[name] ?? nullValue).swiftEval(in: scope, as: coercion)
}

func unboxOption<T: SwiftCoercion>(_ options: Options, _ name: String, in scope: Scope, as coercion: T) throws -> T.SwiftType {
    return try coercion.unbox(value: options[name] ?? nullValue, in: scope) // TO DO: slightly skeezy; we bypass swiftEval() as we don't want Command to look up handler (kludge it for now, but this is part of larger debate on double dispatch); nope, that doesn't work either as AsComplex calls swiftEval
}


let asOperatorSyntax = AsRecord([ // TO DO: given a native record/enum coercion, code generator should emit corresponding struct/enum definition and/or extension with static `unboxNativeValue()` method and primitive coercion
    ("form", asSymbol),
    ("precedence", asInt),
    ("associativity", AsSwiftDefault(asSymbol, defaultValue: "left")), // TO DO: need AsEnum(ofType,options)
    ("aliases", AsSwiftDefault(AsArray(asString), defaultValue: []))
    ])


func defineHandlerGlue(handler: Handler, commandEnv: Scope) throws {
    //print("making glue for", handler)
    guard let body = (handler as! NativeHandler).action as? Block else { throw BadSyntax.missingExpression }
    var options = Options()
    try readOptions(body, &options)
    
    let canError = try unpackOption(options, "can_error", in: commandEnv, as: AsSwiftDefault(asBool, defaultValue: false))
    let swiftFunction: HandlerGlue.SwiftFunction?
    if let cmd = try unboxOption(options, "swift_function", in: commandEnv, as: AsSwiftOptional(asCommand)) {
        // TO DO: if given, swiftfunc's parameter record should be of form `{label,…}` and/or `{label:binding,…}`
        // TO DO: error if no. of Swift params is neither 0 nor equal to no. of native params
        swiftFunction = (name: cmd.name.label, params: try cmd.arguments.map{
            guard let name = $0.value.asIdentifier() else { throw BadSyntax.missingName }
            return name.label
        })
    } else {
        swiftFunction = nil
    }
    let useScopes = try unpackOption(options, "use_scopes", in: commandEnv, as: AsSwiftDefault(AsArray(asSymbol), defaultValue: [])).map{"\($0.key)Env"}
    
    let operatorSyntax: HandlerGlue.OperatorSyntax?
    if let record = try unboxOption(options, "operator", in: commandEnv, as: AsOptional(asOperatorSyntax)) as? Record {
        let form = record.fields[0].value as! Symbol
        let precedence = try! asInt.unbox(value: record.fields[1].value, in: commandEnv) // native coercion may return Number
        let associativity = record.fields[2].value as! Symbol
        let aliases = try! AsArray(asString).unbox(value: record.fields[3].value, in: commandEnv)
        if !["left", "right"].contains(associativity) {
                print("malformed operator record", record)
                throw BadSyntax.missingExpression
        }
        let formName: String
        // kludge: to use .custom(…) form, pass a parsefunc name as symbol, e.g. #parseIfOperator, where `let parseIfOperator = parsePrefixControlOperator(withConjunction: "to")` is defined elsewhere [note: double-quotes cannot appear within quoted names; while we could avoid this limitation by accepting a string or command, it's not worth the effort as passing a parsefunc just a temporary workaround anyway] // TO DO: this'll be replaced when table-driven parser is implemented; presumably with the form field accepting the custom pattern to match
        if ["atom", "prefix", "infix", "postfix"].contains(form) {
            formName = ".\(form.key)"
        } else {
            formName = ".custom(\(form.label))"
        }
        operatorSyntax = (formName, precedence, associativity == "left", aliases)
    } else {
        operatorSyntax = nil
    }
    let glue = HandlerGlue(interface: handler.interface, canError: canError, useScopes: useScopes, swiftFunction: swiftFunction, operatorSyntax: operatorSyntax)
    
    //print(glue)
    
    _handlerGlues.append(glue) // ideally should append glues to editable list stored in commandEnv (or use an Environment subclass that captures glues directly, or pass collector array to defineHandlerGlue as an ExternalResource, but for now just chuck them all in a global and run renderer on that)
}



func renderGlue(libraryName: String, handlerGlues: [HandlerGlue]) -> String {
    // TO DO: what about defining operators for constants and other non-command structures (e.g. `do…done` block keywords) [for now, put them in handcoded function and call that separately]
    return handlersTemplate.render((libraryName, handlerGlues)) + "\n\n" + operatorsTemplate.render((libraryName, handlerGlues)) + "\n\n" + handlerStubsTemplate.render((libraryName, handlerGlues)) 
}


// main

func renderHandlerGlue(for libraryName: String, from script: String) throws -> String {
    // parse glue definitions for primitive handlers
    let env = Environment()
    gluelib_loadHandlers(into: env) // TO DO: what handlers must gluelib define? Q. what about loading stdlib handlers into a parent scope, for metaprogramming use?
    stdlib_loadConstants(into: env) // mostly needed for coercions
    
    let operatorRegistry = OperatorRegistry()
    gluelib_loadOperators(into: operatorRegistry) // essential operators used in glue defs; these may be overwritten by stdlib operators
    //stdlib_loadOperators(into: operatorRegistry)
    //stdlib_loadKeywords(into: operatorRegistry) // temporary while we bootstrap stdlib + gluelib
    let operatorReader = newOperatorReader(for: operatorRegistry)
    
    let doc = EditableScript(script) { NumericReader(operatorReader(NameReader(UnicodeReader($0)))) }
    let p = Parser(tokenStream: QuoteReader(doc.tokenStream), operatorRegistry: operatorRegistry)
    do {
        let script = try p.parseScript()
        //print(script)
        let _ = (try script.eval(in: env, as: asAnything))
        let code = renderGlue(libraryName: libraryName, handlerGlues: _handlerGlues)
        return(code)
    } catch {
        print(error)
        throw error
    }
}

