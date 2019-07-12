//
//  collection.swift
//  iris-lang
//

import Foundation


protocol CollectionCoercion: Coercion {
    var item: Coercion { get }
}



struct AsList: CollectionCoercion {
    
    let name: Name = "list"
    
    let item: Coercion
    
    init(_ item: Coercion) { // TO DO: optional min/max length constraints
        self.item = item
    }
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        return try value.toList(in: scope, as: self)
    }
}


// TO DO: what should AsDictionary's SwiftType be? (c.f. Dictionary.Element, which is a `(key:Key,value:Value)` tuple)

protocol SwiftCollectionCoercion: SwiftCoercion {
    
    associatedtype ElementCoercion: SwiftCoercion
    
    var item: ElementCoercion { get }
}


struct AsArray<ElementCoercion: SwiftCoercion>: SwiftCollectionCoercion {
    
    let name: Name = "list" // TO DO
    
    typealias SwiftType = [ElementCoercion.SwiftType]
    
    let item: ElementCoercion
    
    init(_ item: ElementCoercion) { // TO DO: optional min/max length constraints
        self.item = item
    }
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        throw NotYetImplementedError()
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        fatalError()
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        throw NotYetImplementedError()
    }
}


// AsTable/AsDictionary<T>; keys will always be scalar and/or symbol (Q. define `Atom` to represent scalar, symbol, bool, and nothing; this makes sense as scalars describe variable quantities whereas the others are absolutes)



let asList = AsList(asValue)
