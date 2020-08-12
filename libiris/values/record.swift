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


// TO DO: should record be BoxedCollectionValue/BoxedComplexValue? the problem is that labeled fields require unique labels, which Swift type system can't enforce, so we rely on runtime checking with throws, but the boxed protocol requires a non-throwing init, which record can't provide (there is `Record(uniqueLabelsWithValues:)` but that has a different signature and doesn’t validate); only option would be to raise fatalError()

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
        return "{\(self.map{ "\($0.isEmpty ? "" : "\($0.label): ") \(literal(for: $1))" }.joined(separator: ", "))}"
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
    
    // TO DO: how should records treat mutability?
    
    func toRecordType(in scope: Scope) throws -> RecordType { // coercion names are looked up in the given scope
        // if label is omitted, binding name is used for both; if coercion is omitted, asAnything is used
        var uniqueLabels = Set<Symbol>(), uniqueBindings = Set<Symbol>() // all labels must be unique; ditto all binding names
        let result = try self.map{ (label: Symbol, value: Value) throws -> RecordType.Field in
            // label may be nullSymbol, in which case use binding name
            var label = label, binding: Symbol, coercion: NativeCoercion
            switch value {
            case let command as Command:
                if command.name == "as" { // e.g. {foo as list} // TO DO: this assumes record definition using standard operator syntax; it is awkward to construct using literal command syntax and isn’t suitable for metaprogramming
                    let args = command.arguments
                    // TO DO: need simpler way to convert command to identifier
                    guard args.count == 2, let name = args[0].value.asIdentifier() else {
                        print("Bad `as` operator:",command) // DEBUG
                        throw TypeCoercionError(value: Record(self, as: asRecord), coercion: asRecordType)
                    }
                    binding = name
                    coercion = try asCoercion.coerce(args[1].value, in: scope)
                } else { // e.g. {bar}
                    guard let name = command.asIdentifier() else {
                        print("Bad name:",command) // DEBUG
                        throw TypeCoercionError(value: Record(self, as: asRecord), coercion: asRecordType)
                    }
                    binding = name
                    coercion = asAnything // if no parameter type is specified, accept any value or `nothing`
                }
            default:
                print("toRecordType() failed on", type(of:value),value) // DEBUG
                throw TypeCoercionError(value: try Record(self), coercion: asRecordType)
            }
            if binding == nullSymbol { binding = label }
            if label == nullSymbol { label = binding }
            uniqueLabels.insert(label)
            uniqueBindings.insert(binding)
            return (label, binding, coercion)
        }
        //
        if uniqueLabels.contains(nullSymbol) || uniqueLabels.count != self.count || uniqueBindings.count != self.count {
            print("toRecordType() found bad labels") // DEBUG
            throw TypeCoercionError(value: Record(self, as: asRecord), coercion: asRecordType)
        }
        return RecordType(result)
    }

}



public struct Record: ComplexValue, LiteralConvertible, Accessor, Sequence {
    
    public var swiftLiteralDescription: String {
        // TO DO: what about including constrainedType?
        return "Record(uniqueLabelsWithValues: \(self.data.swiftLiteralDescription))"
    }
    
    public var literalDescription: String {
        return "{\(self.data.map{ $0 == nullSymbol ? "\($1)" : "\($0.label): \(literal(for: $1))"}.joined(separator: ", "))}"
    }

    // TO DO: `description` should return Swift representation (we need a separate visitor-style API for pretty-printing native values, as formatting needs to be customizable [e.g. when reformatting script's code, where line-wrapping and reindentation is automatic, command arguments can omit record punctuation for low-noise AS-like appearance, and commands can be formatted with or without using custom operator syntax; plus, of course, literate formatting where visual emphasis is assigned to high-level structures rather than low-level token types]; TBH generating Swift representations should probably also be done using same PP API, e.g. for use by cross-compiler when generating [human-readable] Swift code, with `description` invoking that with default formatting options when displaying values for debugging/troubleshooting)
    
    public typealias Field = (label: Symbol, value: Value) // nullSymbol = unnamed field
    public typealias Fields = [Field]

    public static let nominalType: NativeCoercion = asRecord
    
    public let isMemoizable: Bool // true if all field names are given and all values are memoizable

    public let constrainedType: NativeCoercion
    
    public let data: Fields // TO DO: why is this not named data as per BoxedSwiftValue?
    
    // TO DO: would it be better to collapse duplicate keys (i.e. discard all but first/last) rather than throw error? (depends on what, if any, commands we provide for joining/splicing records)
    
    public init(_ fields: Fields) throws { // field names may be omitted, but must be unique
        var fieldLabels = Set<Symbol>()
        var isMemoizable = true
        var fieldTypes = RecordType.Fields()
        self.data = fields
        for (key, value) in fields {
            if key == nullSymbol {
                isMemoizable = false
            } else {
                if fieldLabels.contains(key) { throw MalformedRecordError(name: key, in: fields) }
                fieldLabels.insert(key)
                if isMemoizable {
                    if !value.isMemoizable { isMemoizable = false }
                    fieldTypes.append((key, key, value.nominalType))
                }
            }
        }
        self.isMemoizable = isMemoizable
        self.constrainedType = isMemoizable ? AsRecord(fieldTypes) : asRecord
    }
    
    public init() {
        self.init([], as: asRecord)
    }
    
    public init(uniqueLabelsWithValues fields: Fields, as coercion: NativeCoercion = asRecord) {
        // caution: this does not verify that labels are unique
        self.init(fields, as: coercion)
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
    
    public func get(_ name: Symbol) -> Value? {
        return name == nullSymbol ? self : self.data.first{ $0.label == name }?.value
    }
    
    /*
    public func toValue(in scope: Scope, as coercion: Coercion) throws -> Value {
        return self.isMemoizable ? self : Record(try self.data.map{($0, try asAnything.coerce($1, in: scope))},
                                                 as: self.constrainedType)
    }
    */
}


