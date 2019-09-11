//
//  selector methods.swift
//  iris-script
//

// note: as long as selector arguments are correct type, building a query shouldn't throw, e.g. `foo of bar of x` can build and cache the query without knowing what `x` is or whether it has a `bar` attribute


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
    
    func swiftCall<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        throw NotYetImplementedError()
    }
    func swiftCallAs<T>(with command: Command, in scope: Scope, as coercion: Coercion) throws -> T {
        throw NotYetImplementedError()
    }
}

struct InsertionSelector: QuerySelector { // beginning/end
    
    let appData: NativeAppData
    let desc: InsertionLocationDescriptor
    
    var interface: HandlerInterface {
        return HandlerInterface(name: "end", // TO DO: implement name
                                parameters: [],
                                result: asQuery) // TO DO: what return type?
    }
    
    func call(with command: Command, in scope: Scope, as coercion: Coercion) throws -> Value { // e.g. `first document`
        guard command.arguments.count == 0 else { throw BadSelectorError() }
        return InsertionLocation(appData: self.appData, desc: self.desc)
    }
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
                                parameters: [("right", "element_type", asLiteralName)], // TO DO: what labels?
                                result: asQuery) // TO DO: what return type?
    }
    
    func call(with command: Command, in scope: Scope, as coercion: Coercion) throws -> Value { // e.g. `first document`
        guard command.arguments.count == 1, let elementType = command.arguments[0].value.asIdentifier() else {
            throw BadSelectorError()
        }
        let elementsDesc = self.parentDesc.elements(try elementCode(for: elementType, in: self.appData))
        switch self.form {
        case .every:  return MultipleReference(appData: self.appData, desc: elementsDesc)
        case .first:  return Reference(appData: self.appData, desc: elementsDesc.first)
        case .middle: return Reference(appData: self.appData, desc: elementsDesc.middle)
        case .last:   return Reference(appData: self.appData, desc: elementsDesc.last)
        case .any:    return Reference(appData: self.appData, desc: elementsDesc.any)
        }
    }
}


struct ByIndexSelector: QuerySelector { // ‘at’ {element_type, selector_data}
    
    let appData: NativeAppData
    let parentDesc: SpecifierDescriptor
    
    var interface: HandlerInterface {
        return HandlerInterface(name: "at",
                                parameters: [("left", "element_type", asLiteralName), ("right", "selector_data", asValue)], // usually, but not necessarily, integer; `a thru b` is also accepted, in which case by-range specifier should be constructed; anything else is by-index
                                result: asQuery) // TO DO: what return type?
    }
    func call(with command: Command, in scope: Scope, as coercion: Coercion) throws -> Value {
        // TO DO: this ignores argument labels (TBH, would be best if parser checked static arg labels as much as possible, followed by first-use checks, followed by full check on every use for fully dynamic dispatch)
        guard command.arguments.count == 2, let elementType = command.arguments[0].value.asIdentifier() else {
            throw BadSelectorError()
        }
        let elementsDesc = self.parentDesc.elements(try elementCode(for: elementType, in: self.appData))
        let selectorData = try asValue.unbox(value: command.arguments[1].value, in: scope)
        if let range = selectorData as? ElementRange {
            print(elementType, "at range:", range)
            let startDesc = RootSpecifierDescriptor.con.elements(0).first // TO DO: implement
            let endDesc = RootSpecifierDescriptor.con.elements(0).last
            return MultipleReference(appData: self.appData, desc: elementsDesc.byRange(from: startDesc, to: endDesc))
        } else {
            //print(elementType, "at index:", selectorData)
            return Reference(appData: self.appData, desc: elementsDesc.byIndex(try appData.pack(selectorData)))
        }
    }
}

struct ByNameSelector: QuerySelector { // ‘named’ {element_type, selector_data}
    
    let appData: NativeAppData
    let parentDesc: SpecifierDescriptor
    
    var interface: HandlerInterface {
        return HandlerInterface(name: "named",
                                parameters: [("left", "element_type", asLiteralName), ("right", "selector_data", asValue)], // usually, but not necessarily, string
                                result: asQuery) // TO DO: what return type?
    }
    func call(with command: Command, in scope: Scope, as coercion: Coercion) throws -> Value {
        // TO DO: this ignores argument labels
        guard command.arguments.count == 2, let elementType = command.arguments[0].value.asIdentifier() else {
            throw BadSelectorError()
        }
        let elementsDesc = self.parentDesc.elements(try elementCode(for: elementType, in: self.appData))
        
        // TO DO: asDescriptor
        
        let selectorData = try asValue.unbox(value: command.arguments[1].value, in: scope) // TO DO: as above
        //print(elementType, "named:", selectorData)
        return Reference(appData: self.appData, desc: elementsDesc.byName(try appData.pack(selectorData)))
    }
}

struct ByIDSelector: QuerySelector { // ‘id’ {element_type, selector_data}
    
    let appData: NativeAppData
    let parentDesc: SpecifierDescriptor
    
    var interface: HandlerInterface {
        return HandlerInterface(name: "id",
                                parameters: [("left", "element_type", asLiteralName), ("right", "selector_data", asValue)], // usually, but not necessarily, string
                                result: asQuery) // TO DO: what return type?
    }
    func call(with command: Command, in scope: Scope, as coercion: Coercion) throws -> Value {
        // TO DO: this ignores argument labels
        guard command.arguments.count == 2, let elementType = command.arguments[0].value.asIdentifier() else {
            throw BadSelectorError()
        }
        let elementsDesc = self.parentDesc.elements(try elementCode(for: elementType, in: self.appData))
        
        // TO DO: asDescriptor
        
        let selectorData = try asValue.unbox(value: command.arguments[1].value, in: scope) // TO DO: as above
        //print(elementType, "id:", selectorData)
        return Reference(appData: self.appData, desc: elementsDesc.byID(try appData.pack(selectorData)))
    }
}


struct ByTestSelector: QuerySelector { // ‘id’ {element_type, selector_data}
    
    let appData: NativeAppData
    let parentDesc: SpecifierDescriptor
    
    var interface: HandlerInterface {
        return HandlerInterface(name: "where",
                                parameters: [("left", "element_type", asLiteralName), ("right", "selector_data", asValue)], // usually, but not necessarily, string
                                result: asQuery) // TO DO: what return type?
    }
    func call(with command: Command, in scope: Scope, as coercion: Coercion) throws -> Value {
        // TO DO: this ignores argument labels
        guard command.arguments.count == 2, let elementType = command.arguments[0].value.asIdentifier() else {
            throw BadSelectorError()
        }
        let elementsDesc = self.parentDesc.elements(try elementCode(for: elementType, in: self.appData))
        
        
        // TO DO: scope needs extended to use RootSpecifierDescriptor.its as base
        
        let selectorData = try asValue.unbox(value: command.arguments[1].value, in: scope) // TO DO: as above
        print(elementType, "where:", selectorData)
        let desc = RootSpecifierDescriptor.its.property(0).contains(packAsString("xxxx")) // TO DO: use appData.pack()
        return Reference(appData: self.appData, desc: elementsDesc.byTest(desc))
    }
}

