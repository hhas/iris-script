//
//  pair.swift
//  iris-script
//

import Foundation



struct Pair: BoxedSwiftValue {
    
    var description: String { return "\(self.data.0):\(self.data.1)" }
    
    let nominalType: Coercion = asPair
    
    var key: Value { return self.data.key }
    var value: Value { return self.data.value }
    
    let data: (key: Value, value: Value) // in a record, key is Symbol (field name); in keyed list (dictionary), key is any hashable Value
    
    init(_ key: Value, _ value: Value) {
        self.data = (key, value)
    }
}

