//
//  record coercion.swift
//  iris-script
//

import Foundation


// implement iterator over defined fields; Record.toRecord should use this to eval its fields (in the case of AsAnyRecord, the iterator always returns wildcard)

protocol RecordCoercion: Coercion {
    
    typealias Field = (name: Symbol, coercion: Coercion)
    
    var fields: [Field] { get }
}



struct AsRecord: RecordCoercion {
    
    let name: Symbol = "record"
    
    var description: String { return "record" } // TO DO
    
    typealias SwiftType = Record
    
    let fields: [RecordCoercion.Field]
    
    init(_ fields: [RecordCoercion.Field]) { // TO DO: what if fields is empty? also guard against nullSymbol name?
        self.fields = fields
    }
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        let record = try value.toRecord(in: scope, as: self)
        if record.isMemoizable, record.constrainedType.isa(self) { return record } // TO DO: how to test if coercion is equal or superset of record's constrained type?
        var result = [Record.Field]()
        do {
            if self.fields.isEmpty {
                result = try record.fields.map{($0, try $1.eval(in: scope, as: asAnything))}
            } else {
                var iter = record.fields.makeIterator()
                var (key, value) = iter.next() ?? (nullSymbol, nullValue) // record may be empty record
                for (asSymbol, asType) in self.fields {
                    // catch and rethrow to indicate failed field?
                    if key == nullSymbol || key == asSymbol {
                        result.append((asSymbol, try value.eval(in: scope, as: asType)))
                        (key, value) = iter.next() ?? (nullSymbol, nullValue)
                    } else { // assume missed field
                        result.append((asSymbol, try nullValue.eval(in: scope, as: asType)))
                    }
                }
                // think this logic is subtly wrong (i.e. what if record is `{1,2,nothing}`?) one option is to discard trailing `nothing`[s]
                if !(key == nullSymbol && value is NullValue && iter.next() == nil) {
                    throw InternalError(description: "record has unmatched field(s)") // TO DO: what error message?
                }
            }
        } catch {
            throw ConstraintError(value: record, coercion: self).from(error)
        }
        return Record(result, as: self)
    }
}


let asRecord = AsRecord([])
