//
//  record.swift
//  libiris
//
//  tuple/struct hybrid
//
//  syntactically similar to an AppleScript record, except field order is significant as field names may be omitted, e.g.:
//
//  {foo: 1, "hello", baz: nothing}
//


import Foundation


// TO DO: should record be BoxedCollectionValue/BoxedComplexValue? the problem is that labeled fields require unique labels, which Swift type system can't enforce, so we rely on runtime checking with throws, but the boxed protocol requires a non-throwing init, which record can't provide (there is `Record(uniqueLabelsWithValues:)` but that has a different signature)

func literal(for value: Value) -> String { // TO DO: temporary; see also formatting
    if let v = value as? LiteralConvertible {
        return v.literalDescription
    } else {
        return "«object: \(value)»"
    }
}

public extension Record.Fields { // also used as Command.Arguments
    
    var swiftLiteralDescription: String {
        return "[\(self.map{ "(\($0.isEmpty ? "nullSymbol" : $0.swiftLiteralDescription), \($1.swiftLiteralDescription))" }.joined(separator: ", "))]"
    }
    
    var literalDescription: String {
        return "{\(self.map{ "\($0.isEmpty ? "" : "\($0.label): ")\(literal(for: $1))" }.joined(separator: ", "))}"
    }
    
    // TO DO: better error messages
    
    private func value(labeled label: Symbol, at index: inout Int) -> Value {
        if index < self.count {
            let arg = self[index]
            // TO DO: should this skip over unrecognized labels, i.e. ignore unwanted fields? i.e. if arg is unlabeled or matches, use current field else call firstIndex{$0.label==label} to search for field in remaining record
            if arg.label.isEmpty || arg.label == label { // always match unlabeled field, else match if label is same
                index += 1
                return arg.value
            } // else field has different label so assume the requested field has been omitted from record
        }
        return nullValue // default value for a missing field is `nothing`; this allows coercion to decide if that field is required or not (note that this is different behavior to environment slot lookups, which always fail with NameNotFoundError if slot isn’t found; TO DO: should we unify behavior or not?)
    }
    
    
    func coerce<T: SwiftCoercion>(param: (label: Symbol, binding: Symbol, coercion: T),
                                  at index: inout Int, in scope: Scope) throws -> T.SwiftType {
        // if field was matched, index is incremented on return
        // (caution: if caller rethrows an unbox() error, don't use the returned index in error message)
        let currentIndex = index
        let value = self.value(labeled: param.label, at: &index)
        do {
            return try param.coercion.coerce(value, in: scope)
        } catch { // TO DO: what to trap here? e.g. should it catch NullCoercionError directly, which can occur if field was not found or if field contains `nothing` but coercion isn't optional/default
            if self.contains(where: {$0.label == param.label})
                || (currentIndex < self.count && self[currentIndex].label == nullSymbol) { // TO DO: if labeled field is in record but is in wrong order, the error message should reflect that, so use firstIndex() rather than contains() to determine its position relative to currentIndex (“expected ‘LABEL’ field at X index but found it at Y”)
                throw BadFieldValueError(at: currentIndex, of: self).from(error)
            } else {
                throw UnknownFieldError(at: currentIndex, of: self).from(error)
            }
        }
    }
}



public struct Record: ComplexValue, Accessor, Sequence {
    
    public var swiftLiteralDescription: String {
        // TO DO: what about including constrainedType?
        return "Record(uniqueLabelsWithValues: \(self.data.swiftLiteralDescription))"
    }
    
    // TO DO: `description` should return Swift representation (we need a separate visitor-style API for pretty-printing native values, as formatting needs to be customizable [e.g. when reformatting script's code, where line-wrapping and reindentation is automatic, command arguments can omit record punctuation for low-noise AS-like appearance, and commands can be formatted with or without using custom operator syntax; plus, of course, literate formatting where visual emphasis is assigned to high-level structures rather than low-level token types]; TBH generating Swift representations should probably also be done using same PP API, e.g. for use by cross-compiler when generating [human-readable] Swift code, with `description` invoking that with default formatting options when displaying values for debugging/troubleshooting)
    
    public var description: String { return "{\(self.data.map{ $0 == nullSymbol ? "\($1)" : "\($0.label): \($1)"}.joined(separator: ", "))}" }
    
    public typealias Field = (label: Symbol, value: Value) // nullSymbol = unnamed field
    public typealias Fields = [Field]

    public static let nominalType: NativeCoercion = asRecord.nativeCoercion
    
    public let isMemoizable: Bool // true if all field names are given and all values are memoizable

    public let constrainedType: NativeCoercion
    
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
        self.constrainedType = (isMemoizable ? AsRecord(nominalFields) : asRecord).nativeCoercion
    }
    
    public init() {
        self.init([], as: asRecord.nativeCoercion)
    }
    
    public init(uniqueLabelsWithValues fields: Fields) {
        try! self.init(fields)
    }
    
    internal init(_ fields: Fields, as coercion: NativeCoercion) {
        self.data = fields
        self.constrainedType = coercion
        self.isMemoizable = true // TO DO: check this (e.g. what if field values are thunked?)
    }
    
    internal init<T: SwiftCoercion>(_ fields: Fields, as coercion: T) {
        self.init(fields, as: coercion.nativeCoercion)
    }
    
    
    public __consuming func makeIterator() -> IndexingIterator<Fields> {
        return self.data.makeIterator()
    }
    
    public func get(_ name: Symbol) -> Value? { // TO DO: what about getting by index? or should we provide pattern-matching/eval only?
        return self.namedFields[name]
    }
    
    /*
    public func toValue(in scope: Scope, as coercion: Coercion) throws -> Value {
        return self.isMemoizable ? self : Record(try self.data.map{($0, try asAnything.coerce($1, in: scope))},
                                                 as: self.constrainedType)
    }
    */
}


