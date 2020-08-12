//
//  glue data.swift
//  iris-glue
//

// `handler … {…} returning … requires {…}`
// `record {…} requires {…}`
// `coercion … requires {…}`


import Foundation
import iris

// TO DO: also extract user documentation (from annotations); Q. where should user docs go? may be an idea to put them in separate data file[s] (this might be the original glue file, or it may be XML/JSON/whatever) within library bundle that is only loaded as needed


public typealias OperatorSyntax = HandlerGlue.OperatorSyntax


public struct HandlerGlue {
    
    // TO DO: is it work distinguishing function name from struct initializer (e.g. if swiftName starts with lowerchar vs uppercase char); makes no different to handler glues, but would allow better stub generation
    
    typealias Parameter = (label: String, binding: String, coercion: String)
    typealias SwiftFunction = (name: String, params: [String])
    
    public struct OperatorSyntax {
        public let pattern: iris.Pattern
        public let precedence: Int
        public let associate: Associativity
        public let reducer: String?
    }
    
    let interface: HandlerType // template uses result and isEventHandler
    
    var name: String { return self.interface.name.label }
    var parameters: [Parameter] {
        return self.interface.parameters.map{($0.label.label, $0.binding.label, $0.coercion.swiftLiteralDescription)}
    }
    var result: String { return self.interface.result.swiftLiteralDescription } // coercion name
    
    let canError: Bool
    let useScopes: [String] // commandEnv, handlerEnv // TO DO: any use-cases for per-invocation sub-env?
    let swiftFunction: SwiftFunction? // if different to native names
    let operatorSyntax: OperatorSyntax?

    init(interface: HandlerType, canError: Bool = false, useScopes: [String] = [],
         swiftFunction: SwiftFunction? = nil, operatorSyntax: OperatorSyntax? = nil) {
        self.interface = interface
        self.canError = canError
        self.useScopes = useScopes
        self.swiftFunction = swiftFunction
        self.operatorSyntax = operatorSyntax
    }
    
    // TO DO: tidy this up
    
    var swiftName: String { return self.swiftFunction?.name ?? camelCase(self.name) }
    
    var _swiftArguments: [String] {
        if let params = self.swiftFunction?.params, params.count == self.parameters.count {
            return params
        } else {
            return self.parameters.map{camelCase($0.label)}
        }
    }
    
    var swiftArguments: [(String, String)] {
        return self._swiftArguments.enumerated().map{($1, "arg_\($0)")} + self.useScopes.map{($0, $0)}
    }
    
    var signature: String { return self.swiftName + "_" + self._swiftArguments.joined(separator: "_") }
    
    
    // TO DO: FIX: returned `type` needs to be SwiftType (e.g. `String`), not coercion (e.g. `asString`)
    var swiftParameters: [(label: String, binding: String?, type: String)] { // used in primitive handler function stubs
        let params: [(String, String, String)]
        let nativeParameters = self.interface.parameters.map{(camelCase($0.label.label), camelCase($0.binding.label), $0.coercion.swiftTypeDescription)}
        if let swiftParams = self.swiftFunction?.params, swiftParams.count == nativeParameters.count {
            params = zip(swiftParams, nativeParameters).map{($0, $1.1, $1.2)}
        } else {
            params = nativeParameters
        }
        return params.map{($0, ($0 == $1 || $1.isEmpty ? nil : $1), $2)} + self.useScopes.map{($0, nil, "Scope")}
    }
}




public struct RecordGlue {
    
    public typealias Field = (label: String, binding: String, coercion: String)
    
    public let fields: [Field] // native-style (snake_case) label and binding names, e.g. "of_type"; coercion is Swift constructor/binding name, e.g. "AsArray(asString)"
    public let swiftType: String // struct’s name
    public let swiftFields: [Field] // camelCase labels are used as parameter labels in init(…), binding names are used as property names; coercion is SwiftType used as parameter+property types, e.g. "String"
    public let canError: Bool
    
    init(fields: RecordType.Fields, structName: String, structFields: RecordType.Fields?, canError: Bool) {
        self.fields = fields.map{ ($0.label, $1.label, $2.swiftLiteralDescription) }
        self.swiftType = structName
        if let structFields = structFields, structFields.count == fields.count {
            self.swiftFields = structFields.map{ ($0.label, $1.label, $2.swiftTypeDescription) }
        } else {
            self.swiftFields = fields.map{ (camelCase($0.label), camelCase($1.label), $2.swiftTypeDescription) }
        }
        self.canError = canError
    }
}


public struct CoercionGlue {
    
    // TO DO: ideally we’d get these names from the Coercion itself
    public let swiftType: String // e.g. "AsNumber"
    public let swiftName: String // e.g. "asNumber" // this is usually same as swiftType with first char lowercased // TO DO: is there any use-case where this assumption doesn't hold? if not, probably best to generate this name automatically
    public let aliases: [String] // e.g. `ordered_list` is aliased as `list`
    
    //let operatorName: String? // implement this if any non-constrainable coercions need atom operator
    
    public let constructor: HandlerGlue?
    
    public init(swiftType: String, swiftName: String? = nil, aliases: [String] = [], constructor: HandlerGlue? = nil) { // caution: this doesn’t validate arguments
        self.swiftType = swiftType
        self.swiftName = swiftName ?? (swiftType.first!.lowercased() + swiftType.dropFirst())
        self.aliases = aliases
        self.constructor = constructor
    }
}


public struct EnumGlue {
    
    public let options: [Symbol]
    public let name: String? // e.g. `foo_bar`; if omitted, don’t add glue code to store the enum in env
    public let swiftType: String // e.g. "FooBar"
    public let swiftCases: [String]
    
    public init(options: [Symbol], name: String?, swiftType: String, swiftCases: [String] = []) {
        self.options = options
        self.name = name
        self.swiftType = swiftType
        self.swiftCases = swiftCases.isEmpty ? options.map{ camelCase($0.label) } : swiftCases
    }
}

