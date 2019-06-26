//
//  record value.swift
//  iris-lang
//

import Foundation



struct Record: Value, Accessor {
    
    var description: String { return "\(self.fields)" }
    
    typealias Field = (label: Symbol?, value: Value)

    let nominalType: Coercion = asRecord
    
    func toValue(in scope: Scope, as coercion: Coercion) throws -> Value {
        throw NullCoercionError(value: self, coercion: coercion)
    }

    let fields: [Field]
    
    init(_ fields: [Field]) {
        self.fields = fields
    }
    
    func get(_ key: Symbol) -> Value? {
        return self.fields.first(where: { $0.label == key })?.value
    }
}


