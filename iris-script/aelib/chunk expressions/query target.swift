//
//  query target.swift
//  iris-script
//

// TO DO: should there be separate protocols for indexed vs named access? (similar to AttributedValue, we either implement as part of Value with default implementations that fail, or we declare only on values that support it and test/cast values for protocol conformity before applying)

// for now, implement on top of AppleEvents.framework (i.e. solve for a specific case); extract to protocols/general behaviors that can apply to strings and lists later on


import Foundation

import AppleEvents
import SwiftAutomation

// TO DO: might be better if selector commands took element_type as Symbol and left operator parsefunc to take literal name and convert it

// TO DO: how to hint to PP when to use singular vs plural names? (and how to describe these names in easily machine-readable way)



let asDescriptor = asValue // TO DO: implement



// TO DO: how to parameterize run-time return type?
func tell(target: AttributedValue, action: Value, commandEnv: Scope) throws -> Value { // `tell expr to expr`
    let env = TargetScope(target: target, parent: commandEnv as! Environment) // TO DO: fix (TBH, APIs that currently require Environment should really take [Mutable]Scope)
    return try action.eval(in: env, as: asAnything) // TO DO: how to get coercion info?
}



struct RemoteCall: Handler { // for AE commands, the command name (e.g. Symbol("get")) needs to be looked up in glue; Q. should glue return HandlerInterface, or dedicated data structure (in which case `interface` will be calculated var); note that HI provides no argument processing support,
    
    var interface: HandlerInterface { return self.appData.interfaceForCommand(term: self.term) }
    let term: CommandTerm
    let appData: NativeAppData
    
    // TO DO: also pass target (this packs as keyDirectObject or keySubjectAttr)
    
    let isStaticBindable = false // TO DO: need to decide policy for methods
    
    func call(with command: Command, in scope: Scope, as coercion: Coercion) throws -> Value {
        print("Calling", command)
        let directParameter: Any
        var keywordParameters = [KeywordParameter]()
        if command.arguments.isEmpty {
            directParameter = noParameter
        } else {
            if command.arguments[0].label == nullSymbol {
                directParameter = try asDescriptor.coerce(value: command.arguments[0].value, in: scope) // TO DO: asDescriptor; ditto below
                for argument in command.arguments.dropFirst() {
                    guard let param = self.term.parameter(for: argument.label.key) else {
                        throw InternalError(description: "Bad parameter")
                    }
                    keywordParameters.append((param.name, param.code, try argument.value.eval(in: scope, as: asDescriptor)))
                }
            } else {
                directParameter = noParameter
                for argument in command.arguments {
                    guard let param = self.term.parameter(for: argument.label.key) else {
                        throw InternalError(description: "Bad parameter")
                    }
                    keywordParameters.append((param.name, param.code, try argument.value.eval(in: scope, as: asDescriptor)))
                }
            }
        }
        // TO DO: parentSpecifier arg is annoyingly specific about type
        let parentSpecifier = Specifier(parentQuery: nil, appData: self.appData, descriptor: RootSpecifierDescriptor.app)
        let resultDesc = try self.appData.sendAppleEvent(name: self.term.name,
                                                         event: self.term.event,
                                                         parentSpecifier: parentSpecifier, // TO DO
                                                         directParameter: directParameter, // the first (unnamed) parameter to the command method; see special-case packing logic below
                                                         keywordParameters: keywordParameters) as NativeDescriptor
        return try coercion.coerce(value: resultDesc, in: scope)
    }
    
    
    func swiftCall<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        throw NotYetImplementedError()
    }
    func swiftCallAs<T>(with command: Command, in scope: Scope, as coercion: Coercion) throws -> T {
        throw NotYetImplementedError()
    }
}



typealias AsQuery = AsValue // TO DO: implement coercion (AsComplex? probably not; we probably want same level of granularity as SwiftAutomation)
let asQuery = AsQuery()



// NativeAppData

typealias AsReference = AsComplex<Reference>

let asReference = AsReference(name: "reference")



protocol ReferenceProtocol: Value, SelfPacking {
    
    var appData: NativeAppData { get }
    var desc: SpecifierDescriptor { get }

    
    func lookup(_ name: Symbol) -> Value?
    
}

extension ReferenceProtocol {
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        return self.desc
    }
    
    var description: String { return "«\(self.desc) of \(self.appData)»" }
    
    public func get(_ name: Symbol) -> Value? { // TO DO: can/should get+call be folded into single call()?
        //print("get \(name) slot of \(self)")
        switch name {
        case "at":
            return ByIndexSelector(appData: self.appData, parentDesc: self.desc) // always pass glue and desc (unlike appscript/SwiftAutomation, all refs are rooted in `tell app…` block, so full terminology and target app is always available, including when building range/test specifiers)
        case "named":
            return ByNameSelector(appData: self.appData, parentDesc: self.desc)
        case "id":
            return nil // TO DO: ByIDSelector()
        case "where":
            return nil // TO DO: ByTestSelector()
        case "before", "after": // TO DO: 2 versions of this: `element_type before element of…` (relative), `before element of…` (insertion); dispatch on presence/absence of left operand (it is 2 different operators; just not sure if it should be 2 different commands, which operators could map to)
            return nil // TO DO: RelativeSelector() returns either Reference or Insertion, depending on 2 args or one
        case "beginning", "end":
            return nil
        case nullSymbol:
            return self
        default:
            // e.g. `first xxxx of this` // TO DO: what about aliasing 'some', 'all'? or should we pick one set of names and stick to them?
            if let selector = AbsoluteOrdinalSelector.Selector(rawValue: name) {
                return AbsoluteOrdinalSelector(name: selector, appData: self.appData, parentDesc: self.desc)
            }
            return self.lookup(name)
        }
    }
}



struct Reference: ReferenceProtocol {
    
    static var nominalType: Coercion = asReference
    
    let appData: NativeAppData
    let desc: SpecifierDescriptor
    
    internal func lookup(_ name: Symbol) -> Value? {
        //print("lookup \(name) slot of \(self)")
        // Q. should we allow command lookups directly on any reference?
        if let term = self.appData.glueTable.commandsByName[name.key] {
            return RemoteCall(term: term, appData: self.appData)
        } else if let term = self.appData.glueTable.propertiesByName[name.key] {
            // look up property/elements (elements are usually looked up on context of selector call, e.g. `every document of…`, but may be directly referenced as well: `documents of…`); properties are normally looked up directly, except that `every NAME of…` allows conflicting property/element names to be explicitly disambiguated as element name (by default, conflicting property/element names are treated as property name, with exception of `text` which AS treats as element name as standard)
            return Reference(appData: self.appData, desc: self.desc.property(term.code))
        } else if let term = self.appData.glueTable.elementsByName[name.key] {
            return MultipleReference(appData: self.appData, desc: self.desc.elements(term.code))
        } else {
            return nil
        }
    }
}

protocol MultipleReferenceProtocol: ReferenceProtocol {
    
}



struct MultipleReference: MultipleReferenceProtocol {
    
    static var nominalType: Coercion = asReference
    
    var desc: SpecifierDescriptor { return self._desc }
    
    let appData: NativeAppData
    let _desc: MultipleObjectSpecifierDescriptor
    
    init(appData: NativeAppData, desc: MultipleObjectSpecifierDescriptor) {
        self.appData = appData
        self._desc = desc
    }
    
    internal func lookup(_ name: Symbol) -> Value? {
        //print("lookup \(name) slot of \(self)")
        // Q. should we allow command lookups directly on any reference?
        if let term = self.appData.glueTable.commandsByName[name.key] {
            return RemoteCall(term: term, appData: self.appData)
        } else if let term = self.appData.glueTable.propertiesByName[name.key] {
            // look up property/elements (elements are usually looked up on context of selector call, e.g. `every document of…`, but may be directly referenced as well: `documents of…`); properties are normally looked up directly, except that `every NAME of…` allows conflicting property/element names to be explicitly disambiguated as element name (by default, conflicting property/element names are treated as property name, with exception of `text` which AS treats as element name as standard)
            return Reference(appData: self.appData, desc: self._desc.property(term.code))
        } else if let term = self.appData.glueTable.elementsByName[name.key] {
            return MultipleReference(appData: self.appData, desc: self._desc.elements(term.code))
        } else {
            return nil
        }
    }
}




struct Application: ReferenceProtocol {
    
    let desc: SpecifierDescriptor = RootSpecifierDescriptor.app
    
    static var nominalType: Coercion = asValue // TO DO
    
    var description: String { return "Application(\(self.appData)" }
    
    
    let appData: NativeAppData
    
    
    init(bundleIdentifier: String) {
        self.appData = try! NativeAppData(applicationURL: URL(fileURLWithPath: "/Applications/TextEdit.app"))
    }
    
    internal func lookup(_ name: Symbol) -> Value? {
        //print("lookup \(name) slot of \(self)")
        // Q. should we allow command lookups directly on any reference?
        if let term = self.appData.glueTable.commandsByName[name.key] {
            return RemoteCall(term: term, appData: self.appData)
        } else if let term = self.appData.glueTable.propertiesByName[name.key] {
            // look up property/elements (elements are usually looked up on context of selector call, e.g. `every document of…`, but may be directly referenced as well: `documents of…`); properties are normally looked up directly, except that `every NAME of…` allows conflicting property/element names to be explicitly disambiguated as element name (by default, conflicting property/element names are treated as property name, with exception of `text` which AS treats as element name as standard)
            return Reference(appData: self.appData, desc: RootSpecifierDescriptor.app.property(term.code))
        } else if let term = self.appData.glueTable.elementsByName[name.key] {
            return MultipleReference(appData: self.appData, desc: RootSpecifierDescriptor.app.elements(term.code))
        } else {
            return nil
        }
    }
    
}
