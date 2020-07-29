//
//  query target.swift
//  iris-script
//

// TO DO: should there be separate protocols for indexed vs named access? (similar to AttributedValue, we either implement as part of Value with default implementations that fail, or we declare only on values that support it and test/cast values for protocol conformity before applying)

// for now, implement on top of AppleEvents.framework (i.e. solve for a specific case); extract to protocols/general behaviors that can apply to strings and lists later on

// TO DO: decide public naming convention: "query" vs "reference" vs "specifier" vs whatever else


import Foundation

import AppleEvents
import SwiftAutomation

// TO DO: might be better if selector commands took element_type as Symbol and left operator parsefunc to take literal name and convert it

// TO DO: how to hint to PP when to use singular vs plural names? (and how to describe these names in easily machine-readable way)



let asDescriptor = asValue // TO DO: this won't work as NativeAppData is required to pack Symbol (short of attaching appData to scope, which will likely create its own problems)



struct RemoteCall: Handler {
    
    // for AE commands, the command name (e.g. Symbol("get")) needs to be looked up in glue; Q. should glue return HandlerInterface, or dedicated data structure (in which case `interface` will be calculated var); note that HI provides no argument processing support,
    
    var interface: HandlerInterface { return self.appData.interfaceForCommand(term: self.term) }
    let term: CommandTerm
    let appData: NativeAppData
    
    // TO DO: also pass target (this packs as keyDirectObject or keySubjectAttr)
    
    let isStaticBindable = false // TO DO: need to decide policy for methods
    
    func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        //print("Calling", command)
        let directParameter: Any
        var keywordParameters = [KeywordParameter]()
        if command.arguments.isEmpty {
            directParameter = noParameter
        } else {
            if command.arguments[0].label == nullSymbol {
                directParameter = try asValue.coerce(command.arguments[0].value, in: scope)
                for argument in command.arguments.dropFirst() {
                    guard let param = self.term.parameter(for: argument.label.key) else {
                        throw InternalError(description: "Bad parameter")
                    }
                    keywordParameters.append((param.name, param.code, try asValue.coerce(argument.value, in: scope)))
                }
            } else {
                directParameter = noParameter
                for argument in command.arguments {
                    guard let param = self.term.parameter(for: argument.label.key) else {
                        throw InternalError(description: "Bad parameter")
                    }
                    keywordParameters.append((param.name, param.code, try asValue.coerce(argument.value, in: scope)))
                }
            }
        }
        // TO DO: parentSpecifier arg is annoyingly specific about type
        let parentSpecifier = Specifier(parentQuery: nil, appData: self.appData, descriptor: RootSpecifierDescriptor.app)
        let resultDesc = try self.appData.sendAppleEvent(name: self.term.name,
                                                         event: self.term.event,
                                                         parentSpecifier: parentSpecifier, // TO DO
            directParameter: directParameter, // the first (unnamed) parameter to the command method; see special-case packing logic below
            keywordParameters: keywordParameters) as NativeResultDescriptor
        return try coercion.coerce(resultDesc, in: scope)
    }
}


// NativeAppData


struct InsertionLocation: StaticValue, SelfPacking {
    
    var description: String { return "«\(self.desc) of \(self.appData)»" } // TO DO: implement
    
    static let nominalType: NativeCoercion = asReference.nativeCoercion
    
    let appData: NativeAppData
    let desc: InsertionLocationDescriptor
    
    public func get(_ name: Symbol) -> Value? { return nil }
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        return self.desc
    }
    
}


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
            return ByIDSelector(appData: self.appData, parentDesc: self.desc)
        case "from":
            return ByRangeSelector(appData: self.appData, parentDesc: self.desc)
        case "whose":
            return ByTestSelector(appData: self.appData, parentDesc: self.desc)
        case "before", "after": // TO DO: 2 versions of this: `element_type before element of…` (relative), `before element of…` (insertion); dispatch on presence/absence of left operand (it is 2 different operators; just not sure if it should be 2 different commands, which operators could map to)
            return ByRelativeSelector(form: ByRelativeSelector.Selector(rawValue: name)!, appData: self.appData, parentDesc: self.desc as! ObjectSpecifierDescriptor) // returns either Reference or Insertion, depending on 2 args or one
        case "beginning":
            guard let desc = self.desc as? MultipleObjectSpecifierDescriptor else { return nil }
            return InsertionLocation(appData: self.appData, desc: desc.beginning)
        case "end":
            guard let desc = self.desc as? MultipleObjectSpecifierDescriptor else { return nil }
            return InsertionLocation(appData: self.appData, desc: desc.end)
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
    
    public func toValue(in scope: Scope, as coercion: NativeCoercion) throws -> Value {
        return self
    }
}



struct Reference: ReferenceProtocol {
    
    static let nominalType: NativeCoercion = asReference.nativeCoercion
    
    let appData: NativeAppData
    let desc: SpecifierDescriptor // TO DO: ObjectSpecifierDescriptor
    
    var description: String {
        let parent: String
        let parentDesc = self.desc.from
        if let rootDesc = parentDesc as? RootSpecifierDescriptor {
            switch rootDesc.type {
            case typeNull:
                switch self.appData.target {
                case .name(let name):                    parent = " of app \(name.debugDescription)" // TO DO: may want to avoid using name only, and require full path/bundle ID/pid/eppc URL/nil
                case .url(let url):
                    parent = " of app \(url.isFileURL ? url.path.debugDescription : "“\(url)”")"
                case .bundleIdentifier(let bundleID, _): parent = " of app \(bundleID.debugDescription)"
                case .processIdentifier(let pid):        parent = " of app \(pid)"
                case .Descriptor(let desc):              parent = " of \(desc)"
                case .current:                           parent = " of current_app"
                case .none:                              parent = ""
                }
            case typeCurrentContainer: parent = ""
            case typeObjectBeingExamined: parent = ""
            default: parent = " of \(rootDesc)" // TO DO
            }
        } else if let desc = parentDesc as? ObjectSpecifierDescriptor {
            parent = " of \(Reference(appData: self.appData, desc: desc).description)"
        } else {
            parent = " of «\(parentDesc)»"
        }
        if let desc = self.desc as? ObjectSpecifierDescriptor {
            switch desc.form {
            case .property:
                if let code = try? unpackAsFourCharCode(desc.seld),
                    let name = self.appData.glueTable.propertiesByCode[code] {
                    return "\(name)\(parent)"
                }
            case .userProperty:
                fatalError("not yet implemented")
            default: () // element refs are formatted below
            }
            if let names = self.appData.glueTable.elementsByCode[desc.want],
                let seld = try? unpackDescriptor(desc.seld, appData: appData) { // kludge
                switch desc.form {
                case .absolutePosition:
                    if let symbol = seld as? Symbol, ["first", "middle", "last", "any", "every"].contains(symbol) {
                        return "\(symbol.label) \(names.singular)\(parent)"
                    } else {
                        return "\(names.singular) at \(seld)\(parent)"
                    }
                case .name:
                    return "\(names.singular) named \(seld)\(parent)"
                case .uniqueID:
                    return "\(names.singular) id \(seld)\(parent)"
                case .relativePosition:
                    return "\(names.singular) \((seld as! Symbol).label) \(parent)"
                case .range:
                    return "\(names.plural) from \(seld)\(parent)"
                case .test:
                    return "\(names.plural) where \(seld)\(parent)" // TO DO: left operand may also be a selector, e.g. "first document where …"
                default: () // fallthru
                }
            }
        } else if let desc = self.desc as? InsertionLocationDescriptor { // TO DO: this smells; typeInsertionLoc should unpack as InsertionLocation
            switch desc.position {
            case .beginning:
                return "beginning of \(parent)"
            case .end:
                return "end of \(parent)"
            case .before:
                return "before \(parent)"
            case .after:
                return "after \(parent)"
            }
        }
        return "«\(self.desc) of \(self.appData)»"
    }
    
    
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


typealias MultipleReference = Reference



struct Application: ReferenceProtocol {
    
    static let nominalType: NativeCoercion = asReference.nativeCoercion // TO DO: what type? asApplication?
    
    var description: String { return "Application(\(self.appData)" }

    let appData: NativeAppData
    let desc: SpecifierDescriptor = RootSpecifierDescriptor.app
    
    init(bundleIdentifier: String) throws {
        self.appData = try NativeAppData(bundleIdentifier: bundleIdentifier)
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


