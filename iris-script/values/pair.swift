//
//  pair.swift
//  iris-script
//

import Foundation

// TBD: do we really want/need distinct Pair type? (it has benefit of being composable; OTOH, we need to limit its key type when used in code, to avoid creating serious complexity when parsing dict/record keys)


struct Pair: BoxedSwiftValue {
    
    var description: String { return "(\(self.data.0): \(self.data.1))" } // TO DO: not ideal
    
    let nominalType: Coercion = asPair
    
    var key: Value { return self.data.key }
    var value: Value { return self.data.value }
    
    let data: (key: Value, value: Value) // in a record, key is Symbol (field name); in keyed list (dictionary), key is any hashable Value
    
    init(_ key: Value, _ value: Value) {
        self.data = (key, value)
    }
    
    // TO DO: not sure about this; may be better for parser to transform Pairs in Blocks to `set` commands
    func eval(in scope: Scope, as coercion: Coercion) throws -> Value {
        guard let cmd = self.key as? Command, cmd.arguments.isEmpty else {
            throw UnsupportedCoercionError(value: self.key, coercion: asSymbol)
        }
        guard let context = scope as? MutableScope else { throw ImmutableScopeError(name: cmd.name, in: scope) }
        let value = try self.value.eval(in: scope, as: asAnything)
        try context.set(cmd.name, to: value)
        return nullValue
    }
}

