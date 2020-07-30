//
//  array coercion.swift
//  libiris
//

import Foundation

// TO DO: As[Lazy]Sequence

public struct AsArray<ElementType: SwiftCoercion>: SwiftCoercion {
    
    public typealias SwiftType = [ElementType.SwiftType]
    
    public let name: Symbol = "list" // TO DO
    
    public var swiftLiteralDescription: String { return "AsArray(\(self.elementType.swiftLiteralDescription))" }
    
    public let elementType: ElementType
    
    public init(_ elementType: ElementType) {
        self.elementType = elementType
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        // TO DO: if an item fails to eval/unbox, catch and rethrow error describing entire list, including index of the item that failed to coerce?
        // TO DO: how/where to support constraint checking?
        let result: SwiftType
        switch value {
        case let v as SelfEvaluatingProtocol:
            result = try v.eval(in: scope, as: self)
        case let v as OrderedList:
            if v.data.isEmpty {
                result = []
            } else {
                // if list items are of same type and elementType.coerceFunc returns optimized closure, this is 50% quicker than calling elementType.unbox() every time
                var coerceFunc = self.elementType.coerceFunc(for: type(of: v.data[0]))
                var itemType = type(of: v.data[0])
                var i = 0 // significantly quicker than enumerated()
                result = try v.data.map { item in
                    i += 1
                    if type(of: item) != itemType {
                        itemType = type(of: item)
                        coerceFunc = self.elementType.coerceFunc(for: itemType)
                    }
                    do {
                        return try coerceFunc(item, scope)
                    } catch {
                        print("Can't coerce item", i, "to", self.elementType)
                        throw TypeCoercionError(value: item, coercion: self)
                    }
                }
            }
        default:
            result = [try self.elementType.coerce(value, in: scope)]
        }
        return result
    }
}

extension AsArray where SwiftType.Element: Value {
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        // TO DO: attach self to list as its constrainedType
        return OrderedList(value)
    }
}

extension AsArray {
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        // TO DO: attach self to list as its constrainedType
        return OrderedList(value.map{ self.elementType.wrap($0, in: scope) })
    }
}



//public typealias AsList = TypeMap<OrderedList>

public struct AsList: NativeCoercion {
    
    public var name: Symbol = "list" // TO DO: parameterize
    
    public var swiftLiteralDescription: String { return "AsArray(\(self.elementType.swiftLiteralDescription))" }
    
    public let elementType: NativeCoercion
    
    public init(_ elementType: NativeCoercion = asAnything.nativeCoercion) {
        self.elementType = elementType
    }

    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        // TO DO: if an item fails to eval/unbox, catch and rethrow error describing entire list, including index of the item that failed to coerce?
        // TO DO: how/where to support constraint checking?
        let result: [Value]
        switch value {
        case let v as SelfEvaluatingProtocol:
            result = try v.eval(in: scope, as: AsArray(PrimitivizedCoercion(self.elementType)))
        case let v as OrderedList:
            if v.data.isEmpty {
                result = []
            } else {
                var i = 0
                result = try v.data.map { item in
                    do {
                        i += 1
                        return try self.elementType.coerce(item, in: scope)
                    } catch {
                        print("Can't coerce item", i, "to", self.elementType)
                        throw TypeCoercionError(value: item, coercion: self)
                    }
                }
            }
        default:
            result = [try self.elementType.coerce(value, in: scope)]
        }
        return OrderedList(result)
    }
}

public let asList = AsList() // TO DO: implement as struct
