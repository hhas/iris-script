//
//  reference selectors.swift
//  iris-script
//

// note: as long as selector arguments are correct type, building a query shouldn't throw, e.g. `foo of bar of x` can build and cache the query without knowing what `x` is or whether it has a `bar` attribute

// TO DO: what to do with coercion args?

// TO DO: could also do with call being implemented so that we don't have to force-cast Value results

import Foundation
import AppleEvents



struct BadSelectorError: NativeError { // bad arguments
    var description: String { return "BadSelectorError" }
}


func elementCode(for elementType: Symbol, in appData: NativeAppData) throws -> OSType {
    guard let term = appData.glueTable.elementsByName[elementType.key] else {
        throw UnknownNameError(name: elementType, in: nullScope) // TO DO: use appData as scope?
    }
    return term.code
}


protocol QuerySelector: Handler {}


extension QuerySelector {
    
    var isStaticBindable: Bool { return true } // need to confirm this; we should be able to construct and cache entire query on first use; however, we need to watch for mutable selector values when resolving it (e.g. `text of document at i`)
}

// 'selector' callables

struct AbsoluteOrdinalSelector: QuerySelector { // first/middle/last/any/all {element_type}
    
    enum Selector: Symbol {
        case first  = "first"
        case middle = "middle"
        case last   = "last"
        case any    = "any"
        case every  = "every"
    }
    
    let form: Selector
    let appData: NativeAppData
    let parentDesc: SpecifierDescriptor
    
    init(name: Selector, appData: NativeAppData, parentDesc: SpecifierDescriptor) {
        self.form = name
        self.appData = appData
        self.parentDesc = parentDesc
    }
    
    var interface: HandlerInterface {
        return HandlerInterface(name: self.form.rawValue,
                                parameters: [("right", "element_type", asLiteralName.nativeCoercion)], // TO DO: what labels?
                                result: asReference.nativeCoercion)
    }
    
    func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType { // e.g. `first document`
        guard command.arguments.count == 1, let elementType = command.arguments[0].value.asIdentifier() else {
            throw BadSelectorError()
        }
        // TO DO: these force-casts are not good; how should we handle coercion? (it rather depends on whether coercion to non-reference types are an error, or should force resolution of reference [but since get-ing some references may return another reference or list of references, simply coercing won't work for those; similarly, coercing to value/anything shouldn't resolve reference because reference isa value])
        let elementsDesc = self.parentDesc.elements(try elementCode(for: elementType, in: self.appData))
        switch self.form {
        case .every:  return MultipleReference(appData: self.appData, desc: elementsDesc) as! T.SwiftType
        case .first:  return Reference(appData: self.appData, desc: elementsDesc.first) as! T.SwiftType
        case .middle: return Reference(appData: self.appData, desc: elementsDesc.middle) as! T.SwiftType
        case .last:   return Reference(appData: self.appData, desc: elementsDesc.last) as! T.SwiftType
        case .any:    return Reference(appData: self.appData, desc: elementsDesc.any) as! T.SwiftType
        }
    }
}


struct ByIndexSelector: QuerySelector { // ‘at’ {element_type, selector_data}
    
    let appData: NativeAppData
    let parentDesc: SpecifierDescriptor
    
    var interface: HandlerInterface {
        return HandlerInterface(name: "at",
                                parameters: [("left", "element_type", asLiteralName.nativeCoercion),
                                             ("right", "selector_data", asValue.nativeCoercion)], // usually, but not necessarily, integer
                                result: asReference.nativeCoercion)
    }
    func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        // TO DO: this ignores argument labels (TBH, would be best if parser checked static arg labels as much as possible, followed by first-use checks, followed by full check on every use for fully dynamic dispatch)
        guard command.arguments.count == 2, let elementType = command.arguments[0].value.asIdentifier() else {
            throw BadSelectorError()
        }
        let elementsDesc = self.parentDesc.elements(try elementCode(for: elementType, in: self.appData))
        let selectorData = try asValue.coerce(command.arguments[1].value, in: scope)
        return Reference(appData: self.appData, desc: elementsDesc.byIndex(try appData.pack(selectorData))) as! T.SwiftType
    }
}

struct ByNameSelector: QuerySelector { // ‘named’ {element_type, selector_data}
    
    let appData: NativeAppData
    let parentDesc: SpecifierDescriptor
    
    var interface: HandlerInterface {
        return HandlerInterface(name: "named",
                                parameters: [("left", "element_type", asLiteralName.nativeCoercion),
                                             ("right", "selector_data", asValue.nativeCoercion)], // usually, but not necessarily, string
                                result: asReference.nativeCoercion)
    }
    func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        // TO DO: this ignores argument labels
        guard command.arguments.count == 2, let elementType = command.arguments[0].value.asIdentifier() else {
            throw BadSelectorError()
        }
        let elementsDesc = self.parentDesc.elements(try elementCode(for: elementType, in: self.appData))
        let selectorData = try asValue.coerce(command.arguments[1].value, in: scope)
        //print(elementType, "named:", selectorData)
        return Reference(appData: self.appData, desc: elementsDesc.byName(try appData.pack(selectorData))) as! T.SwiftType
    }
}

struct ByIDSelector: QuerySelector { // ‘id’ {element_type, selector_data}
    
    let appData: NativeAppData
    let parentDesc: SpecifierDescriptor
    
    var interface: HandlerInterface {
        return HandlerInterface(name: "id",
                                parameters: [("left", "element_type", asLiteralName.nativeCoercion),
                                             ("right", "selector_data", asValue.nativeCoercion)], // usually, but not necessarily, string
                                result: asReference.nativeCoercion)
    }
    func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        // TO DO: this ignores argument labels
        guard command.arguments.count == 2, let elementType = command.arguments[0].value.asIdentifier() else {
            throw BadSelectorError()
        }
        let elementsDesc = self.parentDesc.elements(try elementCode(for: elementType, in: self.appData))
        let selectorData = try asValue.coerce(command.arguments[1].value, in: scope)
        //print(elementType, "id:", selectorData)
        return Reference(appData: self.appData, desc: elementsDesc.byID(try appData.pack(selectorData))) as! T.SwiftType
    }
}

struct ByRelativeSelector: QuerySelector { // `ELEMENT before/after parentDesc` (relative reference), `before/after parentDesc` (insertion location)
    
    enum Selector: Symbol {
        case before  = "before"
        case after = "after"
    }
    
    let form: Selector
    let appData: NativeAppData
    let parentDesc: ObjectSpecifierDescriptor
    
    var interface: HandlerInterface {
        return HandlerInterface(name: self.form.rawValue,
                                parameters: [], // TO DO: what parameters? (strictly speaking this handler should be a multimethod, but we can probable get away with standard left+right infix arguments, where left is optional name and right is asReference)
                                result: asValue.nativeCoercion) // TO DO: returns Reference or InsertionLocation, depending on parameters (again, it's an MM issue; we may need a way for HandlerInterface to express multiple input-output pairs)
    }
    
    // TO DO: this is just nasty
    func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType { // e.g. `first document`
        // TO DO: fix
        fatalError("TODO")
        /*
        if command.arguments.count == 1 && command.arguments[0].label == "right" {
            return InsertionLocation(appData: self.appData,
                                     desc: self.form == .before ? self.parentDesc.before : self.parentDesc.after)
        } else if command.arguments.count == 2, let name = command.arguments[0].value.asIdentifier()?.key, // TO DO: check labels?
            let typeDesc = self.appData.glueTable.typesByName[name], let code = try? unpackAsFourCharCode(typeDesc),
            let parent = try? asReference.coerce(command.arguments[1].value, in: scope),
            let parentDesc = parent.desc as? ObjectSpecifierDescriptor {
            return Reference(appData: self.appData, desc: self.form == .before ? parentDesc.previous(code) : parentDesc.next(code))
        } else {
            throw BadSelectorError()
        }*/
    }
}



struct ByRangeSelector: QuerySelector { // ‘at’ {element_type, selector_data}
    
    let appData: NativeAppData
    let parentDesc: SpecifierDescriptor
    
    var interface: HandlerInterface {
        return HandlerInterface(name: "from",
                                parameters: [("left", "element_type", asLiteralName.nativeCoercion),
                                             ("right", "selector_data", asRange.nativeCoercion)], //
                                result: asReference.nativeCoercion)
    }
    
    func unpackRangeSelector(value: Value, in scope: Scope, elementCode: OSType) throws -> QueryDescriptor {
        let value = try asValue.coerce(value, in: scope)
        if let name = value as? String {
            return RootSpecifierDescriptor.con.elements(elementCode).byName(packAsString(name))
        } else if let n = try? asInt.coerce(value, in: scope) {
            return RootSpecifierDescriptor.con.elements(elementCode).byIndex(packAsInt(n))
        } else {
            return try asReference.coerce(value, in: scope).desc
        }
    }
    
    func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        // TO DO: this ignores argument labels (TBH, would be best if parser checked static arg labels as much as possible, followed by first-use checks, followed by full check on every use for fully dynamic dispatch)
        guard command.arguments.count == 2, let elementType = command.arguments[0].value.asIdentifier() else {
            throw BadSelectorError()
        }
        let code = try elementCode(for: elementType, in: self.appData)
        let elementsDesc = self.parentDesc.elements(code)
        let selectorData = try asRange.coerce(command.arguments[1].value, in: scope)
        let subscope = TargetScope(target: Reference(appData: self.appData, desc: RootSpecifierDescriptor.con),
                                   parent: (scope as? MutableScope) ?? MutableShim(scope))
        let startDesc = try self.unpackRangeSelector(value: selectorData.start, in: subscope, elementCode: code)
        let endDesc = try self.unpackRangeSelector(value: selectorData.stop, in: subscope, elementCode: code)
        return MultipleReference(appData: self.appData, desc: elementsDesc.byRange(from: startDesc, to: endDesc)) as! T.SwiftType
    }
}

struct ByTestSelector: QuerySelector { // ‘whose’ {element_type, test}
    
    let appData: NativeAppData
    let parentDesc: SpecifierDescriptor
    
    var interface: HandlerInterface {
        return HandlerInterface(name: "whose",
                                parameters: [("left", "element_type", asLiteralName.nativeCoercion),
                                             ("right", "selector_data", asTestClause.nativeCoercion)], // TO DO: left may also be [deferred] selector command
                                result: asReference.nativeCoercion)
    }
    func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        // TO DO: what about coercion arg?
        // TO DO: this ignores argument labels
        // TO DO: left argument can also be a selector, e.g. `first document where test`
        guard command.arguments.count == 2, let left = command.arguments[0].value as? Command else {
            throw BadSelectorError()
        }
        let elementType: Symbol
        if left.arguments.isEmpty {
            elementType = left.asIdentifier()!
        } else if left.arguments.count == 2,
                ["at", "named", "id"].contains(left.name), // TO DO: these names should be defined as constants
                let name = left.arguments[0].value.asIdentifier() {
            elementType = name
        } else if left.arguments.count == 1,
                ["first", "middle", "last", "any", "every"].contains(left.name),
                let name = left.arguments[0].value.asIdentifier(){ // TO DO: ditto
            elementType = name
        } else {
            throw BadSelectorError()
        }
        let elementsDesc = self.parentDesc.elements(try elementCode(for: elementType, in: self.appData))
        let target = TestClauseScope(appData: self.appData) // constructs its-based references and test selectors
        let subscope = TargetScope(target: target, parent: (scope as? MutableScope) ?? MutableShim(scope))
        let selectorData = try asValue.coerce(command.arguments[1].value, in: subscope)
        guard let testDesc = (selectorData as? TestClause)?.desc else {
            throw BadSelectorError()
        }
        var result = elementsDesc.byTest(testDesc)
        if !left.arguments.isEmpty {
            let subSelector: QuerySelector
            switch left.name {
            case "at":
                subSelector = ByIndexSelector(appData: appData, parentDesc: result)
            case "named":
                subSelector = ByNameSelector(appData: appData, parentDesc: result)
            case "id":
                subSelector = ByIDSelector(appData: appData, parentDesc: result)
            default:
                subSelector = AbsoluteOrdinalSelector(name: AbsoluteOrdinalSelector.Selector(rawValue: left.name)!,
                                                      appData: appData, parentDesc: result)
            }
            result = (try subSelector.call(with: left, in: scope, as: coercion) as! Reference).desc as! ObjectSpecifierDescriptor // TO DO: what about coercion arg?
        }
        return Reference(appData: self.appData, desc: result) as! T.SwiftType
    }
}

