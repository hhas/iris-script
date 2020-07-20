//
//  value protocols.swift
//  iris-lang
//

import Foundation

// TO DO: inclined to standardize `Value.literalDescription` for obtaining values’ literal representation, in which case `description` can just call that and `debugDescription` can call swiftLiteralDescription; that leaves the question of how commands and collections should be formatted, and whether literalDescription should provide operator representation where available (i.e. should we pass a shared formatter instance to literalDescription [maybe], or multiple formatting flags [probably not], or should literalDescription return only default representation and leave complex types entirely to formatter? also bear in mind that we really want to use commands’ eval path to generate scripts’ literal representation, with custom environment providing formatting services as well as standard lookups)


// TO DO: what about serialization? i.e. to what extent should Values support Codable? (we may need to limit it to AST serialization only, e.g. when sending a parsed script to a sandboxed subprocess for execution; serializing a live runtime with its environments, resources, etc. is a massively more challenging task); note that a script runner subprocess may allow code reloading following edits, in which case we need to consider what runtime data persists (e.g. superglobals such as already-loaded libraries and external resource connectors) vs what is reset each time (e.g. local 'module-level' state) (this gets rather more complicated if we support Smalltalk-style hot-[re]loading of 'sub-programs' such as individual handlers and objects; either way, we want the user to have control over what persists and what doesn't, e.g. according to code editor's current editing mode: dev/debug/run/profile/optimize/bake/whatever)
//
// in relation to this, should all packaged libraries (i.e. all primitive libraries, and native libraries packaged as distributable bundles) provide a build-time-generated GUID by which they can be reliably identified? or is it sufficient to rely on library name+version (where name must be a UTI); e.g. if sending scripts over the wire for remote execution, the server must be able to identify and obtain the script’s dependencies (loose native library files can be included in the sent bundle, or maybe hashed for caching and sent via separate request when needed) [Q. how to confirm packaged library integrity? codesigning is obvious choice, but requires paid developer account which is problematic for adoption]


// Q. what about annotations? other than developer annotations («…»; e.g. comments, user documentation, keyword/category metadata), what needs to be captured (e.g. what about constrainedType? source file name+line?) CST/AST transforms, e.g. pipe operator `A;B(x)`->`B(A,x)`, operator info, handler memoization (when command first looks up immutable non-maskable handler slot, it should be reducible to direct call on memoized handler object thereafter, although we could argue that parser should deal with this as AST is not itself mutable so cannot rewrite at runtime to replace command node with optimized equivalent, and having annotation hits every time command is evaled is needlessly expensive; suppose Command itself could have a `private var handler:Handler?` slot that contains memoized handler or nil[?] if it needs to look up dynamically every time, or put 'expensive' dynamic lookup shim in that slot by default and replace with memoized handler if possible; just bear in mind that library-defined handlers [i.e. all of them] can't be reliably bound by parser unless parser imports libraries itself; really not sure how best to tackle this); also bear in mind that in interactive [e.g. live development/debugging] execution, all memoization should be turned off; easiest way may just be to rewrite the AST with the appropriate 'plugins' rather than try to mutate it in-place

// one way to annotate would be to define a `let tag: Int32` on Value protocol, pointing into an array of annotation info (caveat: where Value extends existing structs such as Int, this would have to return 0, i.e. no tag); this could be problematic with compiled modules though

// Q. if all values do have an annotation store, can this be lazy-instantiated? (note: annotation backing store will be shared across all instances of that struct; there is no copy-on-write)

// Q. to what extent can closures over mutable vars modify the internal behavior of ostensibly immutable structs?

// Q. mutability? all values should be immutable by default; mutability is declared as constraint, e.g. `[] as editable list of string`; simplest may be to wrap value in 'Editable' class instance, although that doesn't necessarily help us in avoiding excessive copy-on-writes

// Q. to what extent is lazy eval and/or memoization safe and practical? we want to encourage stream/pipeline processing (controlled iterators, not free-for-all loops) and denoting explicit side-effects

// Q. how best to implement symbols? case-preserving, case-insensitive; (e.g. interned in case-insensitive hash?); Q. can/should symbols be able to describe ObjC-style method names? (arguably Swift func names+param labels too); what should/shouldn't be valid chars in symbols? (bear in mind that symbols may be names of anything, including operators, so all chars are legal, although how they're interpreted may depend on context, e.g. `foo:bar:baz:`)

// for booleans, define true and false, with `nothing` coercing to false and everything else coercing to true? (is this sufficient to support Icon-style chaining, e.g. `3 < x < 6`?)


// TO DO: can we get rid of swiftEval by defining native 'overlay' protocol+extension for Coercions that return Values, e.g. an AsText Coercion that returns Text would implement eval()->Text, which can be re-exported as eval()->Value, thereby satisfying both native->primitive bridging and native runtime typing. (Whereas an AsString Coercion that returns String would only be usable in bridging APIs, but can convert itself to an AsText instance when a native Coercion is required.) Main challenge is supporting generic Coercions, e.g. AsArray(T); need to prototype APIs to confirm they'll support both use-cases. [Also bear in mind that we want to get rid of eval() if we can, and have Coercion.coerce() be the entrypoint, in order to minimize the amount of double-dispatch API-bouncing.]


// TO DO: should Values adopt Accessor rather than Mutator?

public protocol Value: Mutator, SwiftLiteralConvertible, CustomStringConvertible { // TO DO: Codable (Q. use Codable for AE bridging?)
        
    var description: String { get }
    
    static var nominalType: Coercion { get }
    var nominalType: Coercion { get }
    
    var isMemoizable: Bool { get }
    
    var immutableValue: Value { get } // experimental
    
    
    func eval(in scope: Scope, as coercion: Coercion) throws -> Value
    func swiftEval<T: SwiftCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType
    
    func toTYPE<T>(in scope: Scope, as coercion: Coercion) throws -> T
    
    func toValue(in scope: Scope, as coercion: Coercion) throws -> Value // any value except `nothing`
    func toScalar(in scope: Scope, as coercion: Coercion) throws -> ScalarValue // text/number/date/URL
    func toNumber(in scope: Scope, as coercion: Coercion) throws -> Number
    
    func toBool(in scope: Scope, as coercion: Coercion) throws -> Bool
    func toInt(in scope: Scope, as coercion: Coercion) throws -> Int
    func toDouble(in scope: Scope, as coercion: Coercion) throws -> Double
    func toString(in scope: Scope, as coercion: Coercion) throws -> String
    
    // Q. implement toArray in terms of iterator (or possibly even `toIterator`?)
    func toList(in scope: Scope, as coercion: CollectionCoercion) throws -> OrderedList
    func toArray<T: SwiftCollectionCoercion>(in scope: Scope, as coercion: T) throws -> [T.ElementCoercion.SwiftType]

    //func toEditable(in scope: Scope, as coercion: AsEditable) throws -> EditableValue
    
    func toRawRecord(in scope: Scope, as coercion: RecordCoercion) throws -> Record // record fields will be evaluated by RecordCoercion upon return
    
}


extension Value { // default implementations

    public var swiftLiteralDescription: String { fatalError("\(type(of: self)).swiftLiteralDescription is not supported.") } // TO DO: any use-cases where it should be?
    
    public var nominalType: Coercion { return type(of: self).nominalType }
    
    public var isMemoizable: Bool { return false }
    
    public var immutableValue: Value { return self } // default implementation as most Value types are inherently immutable; caution: mutable values MUST override this; TO DO: move this to ScalarValue, forcing collection and complex values to provide their own implementation?
    
    // TO DO: rethrow errors as EvaluationError (in particular, null coercion errors must not propagate)
    
    public func eval(in scope: Scope, as coercion: Coercion) throws -> Value {
        return try coercion.coerce(value: self, in: scope)
    }
    public func swiftEval<T: SwiftCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
        //print("Value.swiftEval()", self, coercion, T.self)
        return try coercion.unbox(value: self, in: scope)
    }
    
    // accessors
    
    public func get(_ name: Symbol) -> Value? {
        return name == nullSymbol ? self : nil
    }

    public func set(_ name: Symbol, to value: Value) throws {
        throw ImmutableValueError(name: name, in: self) // TO DO: check if/where name can be nullSymbol (e.g. when setting an environment slot, ideally we want the error message to give the slot name)
    }
    
    // TO DO: also implement default `call`/`swiftCall` for non-callable values?
    
    
    //
    
    public func toValue(in scope: Scope, as coercion: Coercion) throws -> Value { // evaluate value as its preferred type; important: concrete types that require evaluation override this as necessary // TO DO: having this as default behavior easily masks implementation bugs, move this to ScalarValue and other literal types that always return self, ensuring other types (lists, commands, etc) provide their own implementations [enforced by swiftc type checker]
        return self
    }
    
    // TO DO: should default implementations of toTYPE forward to one or more [@inlinable?] generic implementations? if we want to eliminate Value.eval/swiftEval then this will be easiest way to do it, as types that currently override eval can override the generic method[s] instead of every single one of the following
    
    public func toTYPE<T>(in scope: Scope, as coercion: Coercion) throws -> T {
        throw UnsupportedCoercionError(value: self, coercion: coercion)
    }
    
    public func toScalar(in scope: Scope, as coercion: Coercion) throws -> ScalarValue {
        return try self.toTYPE(in: scope, as: coercion)
    }
    public func toNumber(in scope: Scope, as coercion: Coercion) throws -> Number {
        return try self.toTYPE(in: scope, as: coercion)
    }
    
    public func toBool(in scope: Scope, as coercion: Coercion) throws -> Bool { // TBC
        return try self.toTYPE(in: scope, as: coercion)
    }
    public func toInt(in scope: Scope, as coercion: Coercion) throws -> Int {
        return try self.toTYPE(in: scope, as: coercion)
    }
    public func toDouble(in scope: Scope, as coercion: Coercion) throws -> Double {
        return try self.toTYPE(in: scope, as: coercion)
    }
    public func toString(in scope: Scope, as coercion: Coercion) throws -> String {
        return try self.toTYPE(in: scope, as: coercion)
    }
    
    // Q. implement toArray in terms of iterator (or possibly even `toIterator`?); A. best not to, as cached/memoized values can be returned as-is
    
    // note that these should be overridden in OrderedList, and possibly in KeyedList+UniqueList too; anywhere else?
    public func toList(in scope: Scope, as coercion: CollectionCoercion) throws -> OrderedList {
        return OrderedList([try self.eval(in: scope, as: coercion.item)])
    }
    public func toArray<T: SwiftCollectionCoercion>(in scope: Scope, as coercion: T) throws -> [T.ElementCoercion.SwiftType] {
        return try [self.swiftEval(in: scope, as: coercion.swiftItem)]
    }
    
    //func toEditable(in scope: Scope, as coercion: AsEditable) throws -> EditableValue {
    //    return EditableValue(try coercion.coercion.coerce(value: self, in: scope))
    //}
    
    // TO DO: is this appropriate? (probably, c.f. Value->OrderedList(Value), but need to check corner cases for command args/handler sigs - may need to distinguish record literals, as `foo`, `foo {}`, `foo nothing`, and `foo {nothing}` have different meanings) // as with toList/toArray, this implementation isn't suitable for commands/blocks; Q. what about pair?
    public func toRawRecord(in scope: Scope, as coercion: RecordCoercion) throws -> Record {
        return try Record([(nullSymbol, self.eval(in: scope, as: asAnything))]) // TO DO: need to eval self; TO DO: this is also wrong for commands (move to ScalarValue extension?)
    }
}

// TO DO: can/should all scalars be BoxedValues? what functionality can be defined on BoxedValue extension?

public protocol BoxedSwiftValue: Value {
    
    associatedtype SwiftType
    
    init(_ data: SwiftType) // used by swiftLiteralDescription
    
    var data: SwiftType { get }

}

extension BoxedSwiftValue {
    
    public var swiftLiteralDescription: String { return "\(type(of: self))(\(formatSwiftLiteral(self.data)))" }
    
    public var description: String { return String(describing: self.data) }
}



// hashable Values (numbers, strings, symbols) should implement KeyConvertible protocol, which in turn requires the Value conform to Swift's generic Hashable protocol (i.e. must implement `hash(into:)` and `==`)

// to cast or check if a Value can be used as a hash key, use `value as? HashableValue` or `value is HashableValue`, not KeyConvertible (which is a generic protocol)

public protocol HashableValue: Value {
    var dictionaryKey: KeyedList.Key { get }
}

public protocol KeyConvertible: HashableValue, Hashable { } // Values that can be used as hash keys (Int, Double, Text, Symbol, etc) must implement Hashable+Equatable and adopt KeyConvertible

extension KeyConvertible {
    
    public var dictionaryKey: KeyedList.Key { return KeyedList.Key(self) } // TO DO: how/where do we perform normalizations (e.g. case-sensitivity) defined by Record's key Coercion
}



public protocol AtomicValue: Value { // e.g. nothing, true/false, Symbol
    
}

extension AtomicValue {

}



public protocol ScalarValue: Value {
}



extension ScalarValue {
    
    public var isMemoizable: Bool { return true }
    
    public func toScalar(in scope: Scope, as coercion: Coercion) throws -> ScalarValue { // TO DO: toScalar? (as long as Text can represent all scalars, we should be OK; this does mean that boolean and symbol are not scalars though)
        return self
    }
}


public typealias BoxedScalarValue = ScalarValue & BoxedSwiftValue



// TO DO: what about quantities (length, weight, currency, etc)? these will always hold `(number,unit)` (how do we define units in a way that's extensible?); Q: should multiplying two lengths return area? (yes, behaviors should fit end-user expectations; OTOH multiplying two weights is always an error, while dividing two weights returns number); could do with making this stuff data-driven


public protocol CollectionValue: Value, Sequence {
    
    // itemType: Coercion; repeat expansions can be avoided if return type is subset of itemType
    
}

extension CollectionValue {
    
/*
    func toValue(in scope: Scope, as coercion: Coercion) throws -> Value {
        return try type(of:self).init(data: self.map{ try $0.toValue(in: scope, as: coercion) })
    }
*/
}

public typealias BoxedCollectionValue = CollectionValue & BoxedSwiftValue



public protocol ComplexValue: Value { // e.g. command, handler; presumably swiftEval doesn't reduce down to raw Swift values
    
}

extension ComplexValue {

}


public typealias BoxedComplexValue = ComplexValue & BoxedSwiftValue


