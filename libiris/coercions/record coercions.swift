//
//  record coercions.swift
//  iris
//

import Foundation


public protocol RecordCoercion: SwiftCoercion {
    
    typealias Field = (name: Symbol, coercion: NativeCoercion)
    
    var fields: [Field] { get }
}


let missingField: Record.Field = (nullSymbol, nullValue)


public struct AsRecord: RecordCoercion {
        
    public let name: Symbol = "record"
    
    public var swiftLiteralDescription: String {
        return "AsRecord(\(self.fields.swiftLiteralDescription))"
    }
    
    public var description: String { return "record" } // TO DO
    
    public typealias SwiftType = Record
    
    public let fields: [RecordCoercion.Field]
    
    public init(_ fields: [RecordCoercion.Field] = []) { // TO DO: what if fields is empty? (currently coerce() accepts any fields of anything); also guard against nullSymbol name? // TO DO: guard against duplicate field names, null field names(?)
        self.fields = fields
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> Record {
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        let record = try value as? Record ?? Record([(nullSymbol, value)])
  //      if record.isMemoizable, record.constrainedType.isa(iris.asRecord) { return record } // TO DO: how to test if coercion is equal or superset of record's constrained type?
        var result = [Record.Field]()
        do {
            if self.fields.isEmpty { // record can contain any fields of any type
                result = try record.data.map{
                    let (label, value) = $0
                    return (label, try asAnything.coerce(value, in: scope))
                }
            } else { // coerce the specified fields to the specified types; TO DO: should this ignore/discard any record fields not required by this coercion
                var iter = record.data.makeIterator()
                var (key, value) = iter.next() ?? missingField
                for (expectedLabel, expectedCoercion) in self.fields {
                    // catch and rethrow to indicate failed field?
                    if key == nullSymbol || key == expectedLabel {
                        // if record field is unlabeled it is always matched, otherwise it is matched if it has the expected label, otherwise it is discarded without evaluation
                        result.append((expectedLabel, try expectedCoercion.coerce(value, in: scope)))
                        (key, value) = iter.next() ?? missingField
                    } else { // record didn’t contain the required field, so treat its value as `nothing` and let coercion decide what to do with it (i.e. if field’s type is optional/default then the missing field is added using the coercion’s default value, otherwise it’s an error)
                        result.append((expectedLabel, try expectedCoercion.coerce(nullValue, in: scope)))
                    }
                }
                // think this logic is subtly wrong (i.e. what if record is `{1,2,nothing}`?) one option is to discard trailing `nothing`[s]
                if !(key == nullSymbol && value is NullValue && iter.next() == nil) {
                    throw InternalError(description: "record has unmatched field(s)") // TO DO: what error message?
                }
            }
        } catch {
            throw ConstraintCoercionError(value: record, coercion: iris.asRecord.nativeCoercion).from(error)
        }
        return Record(uniqueLabelsWithValues: result)//Record(result, as: self)
    }
}


public let asRecord = AsRecord()


/*
public struct AsStruct<StructType>: RecordCoercion { // TO DO: this needs moved to iris-glue
    
    public let name: Symbol = "record"
    
    public var swiftLiteralDescription: String { return "AsStruct()" } // TO DO:
    
    public var description: String { return "record" } // TO DO: how to describe?
    
    public typealias SwiftType = StructType
    
    public let fields: [RecordCoercion.Field]
    
    public init(_ fields: [RecordCoercion.Field]) { // TO DO: what if fields is empty? (currently coerce() accepts any fields of anything); also guard against nullSymbol name? // TO DO: guard against duplicate field names, null field names(?)
        self.fields = fields
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> StructType {
        if let v = value as? SelfEvaluatingValue {
            return try v.eval(in: scope, as: self)
        }
        let items: [Record.Field]
        if let v = value as? Record {
            items = v.data
        } else {
            items = [(nullSymbol, value)]
        }
        let _ = items
        fatalError("TODO")
    }
    
    public func wrap(_ value: StructType, in scope: Scope) -> Value {
        fatalError("TODO")
    }
}
*/

