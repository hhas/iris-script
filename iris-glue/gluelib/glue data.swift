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


public typealias OperatorDefinition = HandlerGlueRequirements.OperatorDefinition


public struct HandlerGlueRequirements {
    
    public struct OperatorDefinition {
        
        public let syntax: Value // TO DO: can't evaluate this when evaluating `swift_handler`/`swift_coercion` as it needs special context
        public let precedence: Int
        public let associate: Associativity
        public let reducer: String?
    }
    
    public let canError: Bool
    public let useScopes: [Symbol]
    public let swiftFunction: Command?
    public let operatorDefinition: OperatorDefinition?
    
    public init(canError: Bool, useScopes: [Symbol], swiftFunction: Command?, operatorDefinition: OperatorDefinition?) {
        self.canError = canError
        self.useScopes = useScopes
        self.swiftFunction = swiftFunction
        self.operatorDefinition = operatorDefinition
    }
}


public struct HandlerGlue {
    
    // TO DO: is it work distinguishing function name from struct initializer (e.g. if swiftName starts with lowerchar vs uppercase char); makes no different to handler glues, but would allow better stub generation
    
    typealias Parameter = (label: String, binding: String, coercion: String)
    typealias SwiftFunction = (name: String, params: [String])
    
    let interface: HandlerType // template uses result and isEventHandler
    
    var name: String { return self.interface.name.label }
    var parameters: [Parameter] {
        return self.interface.parameters.map{($0.label.label, $0.binding.label, $0.coercion.swiftLiteralDescription)}
    }
    var result: String { return self.interface.result.swiftLiteralDescription } // coercion name
    
    var canError: Bool { return requirements.canError }
    
    var useScopes: [String] { // commandEnv, handlerEnv // TO DO: any use-cases for per-invocation sub-env?
        var scopes = [String]()
        if requirements.useScopes.contains("command") { scopes.append("commandEnv") }
        if requirements.useScopes.contains("handler") { scopes.append("handlerEnv") }
        return scopes
    }
    
    var operatorDefinition: OperatorDefinition? { return requirements.operatorDefinition }
    
    let requirements: HandlerGlueRequirements
    
    let swiftName: String
    let _swiftArguments: [String]

    init(interface: HandlerType, requirements: HandlerGlueRequirements) {
        self.interface = interface
        self.requirements = requirements
        self.swiftName = requirements.swiftFunction?.name.label ?? camelCase(interface.name.label)
        if let swiftFunction = requirements.swiftFunction, swiftFunction.arguments.count == interface.parameters.count {
            self._swiftArguments = swiftFunction.arguments.map{ $0.value.asIdentifier()!.label } // TO DO: use specialized coercion to unpack command, raising error there if not appropriately formed
        } else {
            self._swiftArguments = interface.parameters.map{ camelCase($0.label.label) }
        }
    }
    // TO DO: tidy this up
            
    var swiftArguments: [(String, String)] {
        return self._swiftArguments.enumerated().map{($1, "arg_\($0)")} + self.useScopes.map{($0, $0)}
    }
    
    var signature: String { return self.swiftName + "_" + self._swiftArguments.joined(separator: "_") }
    
    
    var swiftParameters: [(label: String, binding: String?, type: String)] { // used in primitive handler function stubs
        return zip(self._swiftArguments, self.interface.parameters).map({
            (argName: String, param: (_: Symbol, binding: Symbol, coercion: NativeCoercion)) in
            let paramName = camelCase(param.binding.label) // TO DO: swift_function should probably allow labels and binding names (it only affects function stubs)
            return (argName, (argName == paramName ? nil : paramName), param.coercion.swiftTypeDescription)
        }) + self.useScopes.map{($0, nil, "Scope")}
    }
}




public struct RecordGlue {
    
    public typealias Field = (label: String, binding: String, coercion: String)
    
    public let name: String // the SwiftCoercion’s `name` attribute
    public let fields: [Field] // native-style (snake_case) label and binding names, e.g. "of_type"; coercion is Swift constructor/binding name, e.g. "AsArray(asString)"
    public let swiftType: String // struct’s name
    public let swiftFields: [Field] // camelCase labels are used as parameter labels in init(…), binding names are used as property names; coercion is SwiftType used as parameter+property types, e.g. "String"
    public let canError: Bool
    
    init(fields: RecordType.Fields, name: String, structName: String, structFields: RecordType.Fields?, canError: Bool) {
        self.fields = fields.map{ ($0.label, $1.label, $2.swiftLiteralDescription) }
        self.name = name
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

