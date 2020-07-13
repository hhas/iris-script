//
//  collection.swift
//  iris-lang
//

// TO DO: AsDict (AsKeyedList?), AsDictionary<T> keys will always be scalar and/or symbol (Q. define `Atom` to represent scalar, symbol, bool, and nothing; this makes sense as scalars describe variable quantities whereas the others are absolutes)


import Foundation


public protocol CollectionCoercion: Coercion {
    var item: Coercion { get }
}



public struct AsList: CollectionCoercion {
    
    // TO DO: rename AsOrderedList?
    
    public let name: Symbol = "list"
    
    public let item: Coercion
    
    public init(_ item: Coercion) { // TO DO: optional min/max length constraints
        self.item = item
    }
    
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        return try value.toList(in: scope, as: self)
    }
}


// TO DO: what should AsDictionary's SwiftType be? (c.f. Dictionary.Element, which is a `(key:Key,value:Value)` tuple)

public protocol SwiftCollectionCoercion: SwiftCoercion, CollectionCoercion {
    
    associatedtype ElementCoercion: SwiftCoercion
    
    var swiftItem: ElementCoercion { get }
}


public struct AsArray<ElementCoercion: SwiftCoercion>: SwiftCollectionCoercion {
    
    public var swiftLiteralDescription: String { return "AsArray(\(self.item.swiftLiteralDescription))" }
    
    public let name: Symbol = "list" // TO DO
    
    public typealias SwiftType = [ElementCoercion.SwiftType]
    
    public let swiftItem: ElementCoercion
    public var item: Coercion { return self.swiftItem }
    
    public init(_ item: ElementCoercion) { // TO DO: optional min/max length constraints
        self.swiftItem = item
    }
    
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        return try value.toList(in: scope, as: self)
    }
    
    public func box(value: SwiftType, in scope: Scope) -> Value {
        return OrderedList(value.map{ self.swiftItem.box(value: $0, in: scope) })
    }
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        return try value.toArray(in: scope, as: self)
    }
}




public let asList = AsList(asValue)
