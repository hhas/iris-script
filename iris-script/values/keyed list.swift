//
//  key-value list.swift
//  iris-script
//


import Foundation


// TO DO: given that ScalarValue types are meant to be interchangeable (i.e. differences in underlying implementation—Int,Double,Number,Text—etc are private implementation details that weak typing is meant to hide from user code), can/should ScalarValue types that describe an integer (e.g. `-42`, `-42.0`, `“-42”`, `“-4.2e+1”`, etc) or real (e.g. `27.5`, `“27.5”`, etc) generate identical hashes and compare as equal? (not to mention case-insensitivity by default) in practice, this might be a bit tricky to pull off, requiring lots of speculative normalization of ScalarValues' data to arrive at their canonical representation); and this is before we even contemplate enabling l10n in scripts (e.g. when is `“27,5”` a number as opposed to character sequence?); plus, of course, if we normalize dictionary keys then roundtripping them becomes lossy, which is not ideal either; a possible solution is for Key to capture both the original Value and its normalized representation, and use Coercions to provide the normalization, c.f. kiwi's `case-sensitive text` (e.g. `set my_table to [:] as [real:value]`, `set my_table to [:] as [text(ignoring:#case):anything]`)


protocol HashableValue: Value {
    var dictionaryKey: KeyedList.Key { get }
}

protocol KeyConvertible: HashableValue, Hashable { } // Values that can be used as hash keys (Int, Double, Text, Symbol, etc) must implement Hashable+Equatable and adopt KeyConvertible

extension KeyConvertible {
    
    var dictionaryKey: KeyedList.Key { return KeyedList.Key(self) } // TO DO: how/where do we perform normalizations (e.g. case-sensitivity) defined by Record's key Coercion
}



struct KeyedList: BoxedCollectionValue { // ExpressibleByDictionaryLiteral? // TO DO: what should be its native name?
    
    var swiftLiteralDescription: String { return self.data.isEmpty ? "[:]" : "[\(self.data.map{"\($0.key): \($0.value)"}.joined(separator: ", "))]" } // TO DO: will type be inferred, or should it be explicit?

    typealias KeyConvertibleValue = Value & KeyConvertible
    
    typealias SwiftType = [Key: Value]
    
    struct Key: Hashable { // type-safe wrapper around AnyHashable that ensures non-Value types can't get into Record's internal storage by accident, while still allowing mixed-type keys (the alternative would be to use an enum, but that isn't extensible; Q. what was reasoning for not using KeyConvertible as dictionary key type? [probably because we don't want to implement `==` directly on Values, nor recalculate keys on every use; TO DO: how can this decoupling facilitate records custom-normalizing hash keys, e.g. for case-sensitive vs case-insensitive storage]) // TO DO: what about ExpressibleBy…Literal?
        
        var value: Value { return self.key.base as! Value }
        
        private let key: AnyHashable
        
        public init<T: KeyConvertibleValue>(_ value: T) {
            self.key = AnyHashable(value)
        }
        
        public func hash(into hasher: inout Hasher) { self.key.hash(into: &hasher) }
        public static func == (lhs: Key, rhs: Key) -> Bool { return lhs.key == rhs.key }
    }
    
    //
    
    var description: String { return "\(self.data)" }
    
    static let nominalType: Coercion = asList
    
    // TO DO: rename `constrainedType` to `structuralType`/`reifiedType`? make it public on Value?
    
    private var constrainedType: Coercion = asList // TO DO: how/when is best to specialize this (bear in mind that list may contain commands and other exprs that are not guaranteed to eval to same type/value every time)
    
    var isMemoizable: Bool { return false } // TO DO: lists are memoizable only if all elements are; how/when should we determine this? (we want to avoid iterating long lists more than is necessary); should we also take opportunity to determine minimally constrained type? (e.g. if all items are numbers, constrained type could be inferred as AsArray(asNumber), although whether we want to enforce this when editing list is another question)
    
    let data: SwiftType // TO DO: what about Array<Element>? boxing an array of Swift primitives and boxing each item upon use might have performance advantage in some situations (if so, we probably want to implement that as a GenericList<Element> struct which is natively polymorphic with OrderedList; however, that will mean chunk expressions and library commands can't operate directly on OrderedList.data all access to list contents must go via methods on CollectionValue/OrderedList, which adds an extra level of indirection to an already Swift-stack-heavy AST-walking interpreter)
    
    init(_ data: SwiftType = [:]) {
        self.data = data
    }
    
    __consuming func makeIterator() -> SwiftType.Iterator {
        return self.data.makeIterator()
    }
    
    func toValue(in scope: Scope, as coercion: Coercion) throws -> Value { // TO DO: is coercion argument appropriate here?
        return try self.toList(in: scope, as: asList)
    }
    
    /*
    func toKeyedList(in scope: Scope, as coercion: CollectionCoercion) throws -> KeyedList {
        return try OrderedList(self.map{ try $0.eval(in: scope, as: coercion.item) })
    }
    
    func toDictionary<T: SwiftCollectionCoercion>(in scope: Scope, as coercion: T) throws -> [T.ElementCoercion.SwiftType] {
        return try self.map{ try $0.swiftEval(in: scope, as: coercion.item) }
    }
    */
}
