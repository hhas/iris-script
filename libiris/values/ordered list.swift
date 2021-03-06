//
//  list.swift
//  libiris
//

import Foundation

// TO DO: OrderedUniformList<ElementType:SwiftCoercion> where all elements are a single type?

// TO DO: implement Accessor for `item(s)`; Q. how to implement Mutators on top? (this is getting into chunk exprs; need to decide how those are constructed using commands, which can then be skimmed with operator syntax)


// foo; of bar; of baz


public struct OrderedList: BoxedCollectionValue, LiteralConvertible { // ExpressibleByArrayLiteral?
    
    public var swiftLiteralDescription: String { return self.data.swiftLiteralDescription }
    
    public var literalDescription: String { return "[\(self.data.map{ literal(for: $0) }.joined(separator: ", "))]" }
    
    public static let nominalType: NativeCoercion = asOrderedList
    
    // TO DO: rename `constrainedType` to `structuralType`/`reifiedType`? make it public on Value?
    
    public let constrainedType: AsOrderedList // TO DO: how/when is best to specialize this (bear in mind that list may contain commands and other exprs that are not guaranteed to eval to same type/value every time)
    
    public var isMemoizable: Bool { return false } // TO DO: lists are memoizable only if all elements are; how/when should we determine this? (we want to avoid iterating long lists more than is necessary); should we also take opportunity to determine minimally constrained type? (e.g. if all items are numbers, constrained type could be inferred as AsArray(asNumber), although whether we want to enforce this when editing list is another question)
    
    public let data: [Value] // TO DO: what about Array<Element>? boxing an array of Swift primitives and boxing each item upon use might have performance advantage in some situations (if so, we probably want to implement that as a GenericList<Element> struct which is natively polymorphic with OrderedList; however, that will mean chunk expressions and library commands can't operate directly on OrderedList.data all access to list contents must go via methods on CollectionValue/OrderedList, which adds an extra level of indirection to an already Swift-stack-heavy AST-walking interpreter)
    
    public init(_ data: [Value] = [], ofType: AsOrderedList = asOrderedList) {
        self.data = data
        self.constrainedType = ofType
    }
    
    public init(_ data: [Value] = []) {
        self.init(data, ofType: asOrderedList)
    }
    
    public __consuming func makeIterator() -> IndexingIterator<[Value]> {
        return self.data.makeIterator()
    }
    
}

