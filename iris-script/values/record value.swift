//
//  record value.swift
//  iris-lang
//

import Foundation


// struct-tuple hybrid; syntactically similar to AppleScript record, except field order is significant as field names may be omitted

// e.g. {foo: 1, "hello", baz: nothing}


struct Record: Value, Accessor {
    
    var description: String { return "\(self.fields)" } // TO DO: format
    
    typealias Field = (name: Name, value: Value) // nullSymbol = unnamed field

    let nominalType: Coercion = asRecord
    
    let isMemoizable: Bool // true if all field names are given and all values are memoizable

    let constrainedType: RecordCoercion
    
    let fields: [Field]
    private var namedFields = [Name: Value]() // Q. any performance benefit over `first(where:…)`? (bearing in mind a typical record would have <20 slots) if not, get rid of this
    
    init(_ fields: [Field]) throws { // field names may be omitted, but must be unique
        var isMemoizable = true
        var nominalFields = [AsRecord.Field]()
        self.fields = fields
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
    
    internal init(_ fields: [Field], as coercion: RecordCoercion) {
        self.fields = fields
        self.constrainedType = coercion
        self.isMemoizable = true // TO DO: check this (e.g. what if field values are thunked?)
    }
    
    func get(_ name: Name) -> Value? { // TO DO: what about getting by index? or should we provide pattern-matching/eval only?
        return self.namedFields[name]
    }
    
    func toValue(in scope: Scope, as coercion: Coercion) throws -> Value {
        throw NotYetImplementedError()
    }
    
    func toRecord(in scope: Scope, as coercion: RecordCoercion) throws -> Record {
        return self
    }
    
    // TO DO: what about mapping to Swift structs/classes? that'll require generated glue (c.f. stdlib_handlers)
    
}


