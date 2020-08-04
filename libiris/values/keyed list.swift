//
//  key-value list.swift
//  iris-script
//


import Foundation

// caution: when transpiling KeyedList to Dictionary, keys must be unique (this won’t be a problem as long as Dictionary is created from an existing KeyedList instance, as reducefunc for keyed lists automatically overwrites duplicate entries)

// TO DO: given that ScalarValue types are meant to be interchangeable (i.e. differences in underlying implementation—Int,Double,Number,Text—etc are private implementation details that weak typing is meant to hide from user code), can/should ScalarValue types that describe an integer (e.g. `-42`, `-42.0`, `“-42”`, `“-4.2e+1”`, etc) or real (e.g. `27.5`, `“27.5”`, etc) generate identical hashes and compare as equal? (not to mention case-insensitivity by default) in practice, this might be a bit tricky to pull off, requiring lots of speculative normalization of ScalarValues' data to arrive at their canonical representation); and this is before we even contemplate enabling l10n in scripts (e.g. when is `“27,5”` a number as opposed to character sequence?); plus, of course, if we normalize dictionary keys then roundtripping them becomes lossy, which is not ideal either; a possible solution is for Key to capture both the original Value and its normalized representation, and use Coercions to provide the normalization, c.f. kiwi's `case-sensitive text` (e.g. `set my_table to [:] as [real:value]`, `set my_table to [:] as [text(ignoring:#case):anything]`)



public struct KeyedList: BoxedCollectionValue, LiteralConvertible { // TO DO: implement ExpressibleByDictionaryLiteral? // TO DO: what should be value's native name? (currently it's referred to 'key-value list', but that's awkward to write as underscored name; however, 'dictionary' is already used to refer to application dictionaries in ae_lib and might also be used as the term for library documentation)
    
    public var swiftLiteralDescription: String { return self.data.swiftLiteralDescription }
    
    public var literalDescription: String {
        if self.data.isEmpty {
            return "[:]"
        } else {
            return "[\(self.data.map{ "\(literal(for: $0.key.value)): \(literal(for: $0.value))" }.joined(separator: ", "))]"
        }
    }
    
    public typealias SwiftType = [Key: Value]
    
    public struct Key: Hashable, SwiftLiteralConvertible, CustomStringConvertible { // type-safe wrapper around AnyHashable that ensures non-Value types can't get into Record's internal storage by accident, while still allowing mixed-type keys (the alternative would be to use an enum, but that isn't extensible; TO DO: how can this decoupling facilitate records custom-normalizing hash keys, e.g. for case-sensitive vs case-insensitive storage])
        
        public var swiftLiteralDescription: String { return "AnyHashable(\(self.value.swiftLiteralDescription))" }

        public var description: String { return "\(self.value)" }
        
        var value: Value { return self.key.base as! Value }
        
        private let key: AnyHashable
        
        public typealias KeyConvertibleValue = Value & KeyConvertible
        
        public init<T: KeyConvertibleValue>(_ value: T) {
            self.key = AnyHashable(value)
        }
        
        public func hash(into hasher: inout Hasher) { self.key.hash(into: &hasher) }
        public static func == (lhs: Key, rhs: Key) -> Bool { return lhs.key == rhs.key }
    }
    
    //
    
    public static let nominalType: NativeCoercion = asOrderedList
    
    // TO DO: rename `constrainedType` to `structuralType`/`reifiedType`? make it public on Value?
    
    private var constrainedType: NativeCoercion = asOrderedList // TO DO: how/when is best to specialize this (bear in mind that list may contain commands and other exprs that are not guaranteed to eval to same type/value every time)
    
    public var isMemoizable: Bool { return false } // TO DO: lists are memoizable only if all elements are; how/when should we determine this? (we want to avoid iterating long lists more than is necessary); should we also take opportunity to determine minimally constrained type? (e.g. if all items are numbers, constrained type could be inferred as AsArray(asNumber), although whether we want to enforce this when editing list is another question)
    
    public let data: SwiftType // TO DO: what about Array<Element>? boxing an array of Swift primitives and boxing each item upon use might have performance advantage in some situations (if so, we probably want to implement that as a GenericList<Element> struct which is natively polymorphic with OrderedList; however, that will mean chunk expressions and library commands can't operate directly on OrderedList.data all access to list contents must go via methods on CollectionValue/OrderedList, which adds an extra level of indirection to an already Swift-stack-heavy AST-walking interpreter)
    
    public init(_ data: SwiftType = [:]) {
        self.data = data
    }
    
    public __consuming func makeIterator() -> SwiftType.Iterator {
        return self.data.makeIterator()
    }
    
    /*
    public func toValue(in scope: Scope, as coercion: Coercion) throws -> Value { // TO DO: is coercion argument appropriate here?
        //return try self.toList(in: scope, as: asOrderedList)
        return try self.toKeyedList(in: scope, as: asOrderedList)
    }
    
    public func toKeyedList(in scope: Scope, as coercion: CollectionCoercion) throws -> KeyedList {
        return try KeyedList([Key:Value](uniqueKeysWithValues: self.data.map{ ($0, try $1.eval(in: scope, as: coercion.item)) }))
    }
    */
    /*
    func toDictionary<T: SwiftCollectionCoercion>(in scope: Scope, as coercion: T) throws -> [T.ElementCoercion.SwiftType] {
        return try self.map{ try $0.swiftEval(in: scope, as: coercion.item) }
    }*/
    
}
