//
//  record.swift
//  iris-lang
//
//  tuple/struct hybrid
//
//  syntactically similar to an AppleScript record, except field order is significant as field names may be omitted, e.g.:
//
//  {foo: 1, "hello", baz: nothing}
//


import Foundation


// TO DO: should record be BoxedCollectionValue/BoxedComplexValue? the problem is that fields require unique labels, which Swift type system can't enforce so we rely on runtime checking with throws, but the boxed protocol requires a non-throwing init, which record can't provide

public struct Record: ComplexValue, Accessor, Sequence {

    public var swiftLiteralDescription: String { return "(try! Record([\(self.data.map{ "(\($0.swiftLiteralDescription), \($1.swiftLiteralDescription))" }.joined(separator: ", "))])" }
    
    // TO DO: `description` should return Swift representation (we need a separate visitor-style API for pretty-printing native values, as formatting needs to be customizable [e.g. when reformatting script's code, where line-wrapping and reindentation is automatic, command arguments can omit record punctuation for low-noise AS-like appearance, and commands can be formatted with or without using custom operator syntax; plus, of course, literate formatting where visual emphasis is assigned to high-level structures rather than low-level token types]; TBH generating Swift representations should probably also be done using same PP API, e.g. for use by cross-compiler when generating [human-readable] Swift code, with `description` invoking that with default formatting options when displaying values for debugging/troubleshooting)
    
    public var description: String { return "{\(self.data.map{ $0 == nullSymbol ? "\($1)" : "\($0.label): \($1)"}.joined(separator: ", "))}" }
    
    public typealias Field = (label: Symbol, value: Value) // nullSymbol = unnamed field
    public typealias Fields = [Field]

    public static let nominalType: Coercion = asRecord
    
    public let isMemoizable: Bool // true if all field names are given and all values are memoizable

    public let constrainedType: RecordCoercion
    
    public let data: Fields // TO DO: why is this not named data as per BoxedSwiftValue?
    private var namedFields = [Symbol: Value]() // Q. any performance benefit over `first(where:…)`? (bearing in mind a typical record would have <20 slots) if not, get rid of this
    
    // TO DO: would it be better to collapse duplicate keys (i.e. discard all but first/last) rather than throw error? (depends on what, if any, commands we provide for joining/splicing records)
    
    public init(_ fields: Fields) throws { // field names may be omitted, but must be unique
        var isMemoizable = true
        var nominalFields = [AsRecord.Field]()
        self.data = fields
        for (key, value) in fields {
            if key == nullSymbol {
                isMemoizable = false
            } else {
                if self.namedFields[key] != nil { throw MalformedRecordError(name: key, in: fields) }
                self.namedFields[key] = value // TO DO: this might be problematic, as now we've two instances of struct value
                if isMemoizable {
                    if !value.isMemoizable { isMemoizable = false }
                    nominalFields.append((key, value.nominalType))
                }
            }
        }
        self.isMemoizable = isMemoizable
        self.constrainedType = isMemoizable ? AsRecord(nominalFields) : asRecord
    }
    
    public init() {
        self.init([], as: asRecord)
    }
    
    internal init(_ fields: Fields, as coercion: RecordCoercion) {
        self.data = fields
        self.constrainedType = coercion
        self.isMemoizable = true // TO DO: check this (e.g. what if field values are thunked?)
    }
    
    public __consuming func makeIterator() -> IndexingIterator<Fields> {
        return self.data.makeIterator()
    }
    
    public func get(_ name: Symbol) -> Value? { // TO DO: what about getting by index? or should we provide pattern-matching/eval only?
        return self.namedFields[name]
    }
    
    public func toValue(in scope: Scope, as coercion: Coercion) throws -> Value {
        return self.isMemoizable ? self : Record(try self.data.map{($0, try asAnything.coerce(value: $1, in: scope))},
                                                 as: self.constrainedType)
    }
    
    public func toRawRecord(in scope: Scope, as coercion: RecordCoercion) throws -> Record {
        return self
    }
    
    // TO DO: what about mapping to Swift structs/classes? that'll require generated glue (c.f. stdlib_handlers)
    
}


