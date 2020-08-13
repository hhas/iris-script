//
//  dictionary coercions.swift
//  libiris
//

// TO DO: Uniform[Ordered/Keyed/Unique]List, where all elements are a single concrete type; this should be more efficient when returning lists built by primitive handlers, as those won't generally be mixed type; in the event that elements are also a Value, assuming type is same as coercion and no additional constraints are applied, that should eliminate the need to traverse the collection when moving between native and primitive environs, which should be significantly faster

// TO DO: lazy-evaluating coercions that return sequences

import Foundation


public struct AsHashableValue: SwiftCoercion {
    
    public let name: Symbol = "key"
    
    public var swiftLiteralDescription: String { return "asHashableValue" }
    
    public typealias SwiftType = HashableValue
    
    public init() {}
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self) }
        guard let result = try? asAnything.coerce(value, in: scope) as? HashableValue else {
            throw TypeCoercionError(value: value, coercion: self)
        }
        return result
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}
public let asHashableValue = AsHashableValue()





public struct AsDictionary<KeyType: SwiftCoercion, ValueType: SwiftCoercion>: SwiftCoercion where KeyType.SwiftType: Hashable {
    
    public typealias SwiftType = [KeyType.SwiftType:ValueType.SwiftType]
    
    public let name: Symbol = "keyed_list"
    
    public var swiftLiteralDescription: String {
        return "AsDictionary(\(self.keyType.swiftLiteralDescription), \(self.valueType.swiftLiteralDescription))"
    }
    
    private let keyType: KeyType
    private let valueType: ValueType
    
    public init(_ keyType: KeyType, _ valueType: ValueType) {
        self.keyType = keyType
        self.valueType = valueType
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        // TO DO: if an item fails to eval/unbox, catch and rethrow error describing entire list, including index of the item that failed to coerce?
        // TO DO: how/where to support constraint checking?
        var result: SwiftType
        switch value {
        case let v as SelfEvaluatingValue:
            result = try v.eval(in: scope, as: self)
        case let val as KeyedList:
            if val.data.isEmpty {
                result = [:]
            } else {
                result = SwiftType(minimumCapacity: val.data.count)
                let (k, v) = val.data.first!
                var keyType = type(of: k.value)
                var valueType = type(of: v)
                var coerceKey = self.keyType.coerceFunc(for: keyType)
                var coerceValue = self.valueType.coerceFunc(for: valueType)
                for (k, v) in val.data {
                    if type(of: k.value) != keyType {
                        keyType = type(of: k.value)
                        coerceKey = self.keyType.coerceFunc(for: keyType)
                    }
                    if type(of: v) != valueType {
                        valueType = type(of: v)
                        coerceValue = self.valueType.coerceFunc(for: valueType)
                    }
                    try result[coerceKey(k.value, scope)] = coerceValue(v, scope)
                }
            }
        default:
            throw TypeCoercionError(value: value, coercion: self)
        }
        return result
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        var result = KeyedList.SwiftType(minimumCapacity: value.count)
        for (k, v) in value {
            let key = self.keyType.wrap(k, in: scope) as! HashableValue
            result[key.dictionaryKey] = self.valueType.wrap(v, in: scope)
        }
        return KeyedList(result) // TO DO: attach self to list as its constrainedType
    }
}


// TO DO: AsKeyedList



public struct AsKeyedList: NativeCoercion {
    
    public typealias KeyType = NativeCoercion
    public typealias ValueType = NativeCoercion
    
    public let name: Symbol = "keyed_list"
    
    public var swiftTypeDescription: String {
        return "[\(self.keyType.swiftTypeDescription):\(self.valueType.swiftTypeDescription)]"
    }

    public var swiftLiteralDescription: String {
        return "AsDictionary(\(self.keyType.swiftLiteralDescription), \(self.valueType.swiftLiteralDescription))"
    }
    
    private let keyType: KeyType
    private let valueType: ValueType
    
    public init(keyType: KeyType = asHashableValue.nativeCoercion, valueType: ValueType = asAnything) {
        // TO DO: there’s no way to determine if a native coercion will return a HashableValue; therefore an inappropriate keyType can only be detected upon use
        self.keyType = keyType
        self.valueType = valueType
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        // TO DO: if an item fails to eval/unbox, catch and rethrow error describing entire list, including index of the item that failed to coerce?
        switch value {
        case let v as SelfEvaluatingValue:
            return try v.eval(in: scope, as: self.swiftCoercion)
        case let val as KeyedList:
            if val.data.isEmpty {
                return KeyedList()
            } else {
                var result = [KeyedList.Key:Value](minimumCapacity: val.data.count)
                let (k, v) = val.data.first!
                var keyType = type(of: k.value)
                var valueType = type(of: v)
                var coerceKey = self.keyType.coerceFunc(for: keyType)
                var coerceValue = self.valueType.coerceFunc(for: valueType)
                for (k, v) in val.data {
                    if type(of: k.value) != keyType {
                        keyType = type(of: k.value)
                        coerceKey = self.keyType.coerceFunc(for: keyType)
                    }
                    if type(of: v) != valueType {
                        valueType = type(of: v)
                        coerceValue = self.valueType.coerceFunc(for: valueType)
                    }
                    guard let key = try? coerceKey(k.value, scope) as? HashableValue else {
                        throw TypeCoercionError(value: k.value, coercion: asHashableValue)
                    }
                    try result[key.dictionaryKey] = coerceValue(v, scope)
                }
                return KeyedList(result)
            }
        default:
            throw TypeCoercionError(value: value, coercion: self)
        }
    }
}


public let asKeyedList = AsKeyedList()

