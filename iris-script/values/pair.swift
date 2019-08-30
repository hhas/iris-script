//
//  pair.swift
//  iris-script
//

import Foundation

// TBD: do we really want/need distinct Pair type? (it has benefit of being composable; OTOH, we need to limit its key type when used in code, to avoid creating serious complexity when parsing dict/record keys)


struct Pair: BoxedSwiftValue {
    
    var swiftLiteralDescription: String { return "Pair(\(self.key.swiftLiteralDescription), \(self.value.swiftLiteralDescription))" }
    
    var description: String { return "(\(self.data.0): \(self.data.1))" } // TO DO: not ideal
    
    static let nominalType: Coercion = asPair
    
    var key: Value { return self.data.key }
    var value: Value { return self.data.value }
    
    typealias SwiftType = (key: Value, value: Value)
    
    let data: SwiftType // in a record, key is Symbol (field name); in keyed list (dictionary), key is any hashable Value
    
    init(_ key: Value, _ value: Value) {
        self.data = (key, value)
    }
    
    init(_ data: SwiftType) { // TO DO: [Swift bug] swiftc breaks without details if SwiftType isn't explicitly declared above (in theory the BoxedSwiftValue protocol should infer SwiftType from the data constant's type, but clearly there are [unplanned] limits)
        self.data = data
    }
    
    // TO DO: not sure about this; may be better for parser to transform Pairs in Blocks to `set` commands
    func eval(in scope: Scope, as coercion: Coercion) throws -> Value {
        guard let name = self.key.asIdentifier() else {
            throw UnsupportedCoercionError(value: self.key, coercion: asSymbol)
        }
        guard let context = scope as? MutableScope else { throw ImmutableScopeError(name: name, in: scope) }
        let value = try self.value.eval(in: scope, as: asAnything)
        try context.set(name, to: value)
        return nullValue
    }
}

