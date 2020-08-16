//
//  array coercions.swift
//  libiris
//

import Foundation

// TO DO: As[Lazy]Sequence

public struct AsArray<ElementType: SwiftCoercion>: SwiftCoercion {
    
    public typealias SwiftType = [ElementType.SwiftType]
    
    public let name: Symbol = "ordered_list"
    
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
        case let v as SelfEvaluatingValue:
            result = try v.eval(in: scope, as: self)
        case let v as OrderedList:
            if v.data.isEmpty {
                result = []
            } else {
                // if list items are of same type and elementType.coerceFunc returns optimized closure, this is 50% quicker than calling elementType.unbox() every time
                var itemType = type(of: v.data[0])
                var coerceFunc = self.elementType.coerceFunc(for: itemType)
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



public struct AsOrderedList: NativeCoercion {
    
    public let name: Symbol = "ordered_list"
    
    public var swiftTypeDescription: String { return "[\(self.elementType.swiftTypeDescription)]" }
    
    public var swiftLiteralDescription: String { return "AsArray(\(self.elementType.swiftLiteralDescription))" }
    
    public var literalDescription: String {
        var arguments = [String]()
        if !(self.elementType is AsValue) { arguments.append("of: \(self.elementType.literalDescription)") }
        if self.minLength != 0 { arguments.append("from: \(self.minLength)") }
        if self.maxLength != Int.max { arguments.append("to: \(self.maxLength)") }
        return arguments.isEmpty ? self.name.label : "\(self.name.label) {\(arguments.joined(separator: ", "))}"
    }
    
    public let elementType: NativeCoercion
    private let minLength: Int, maxLength: Int
    
    public init(_ elementType: NativeCoercion = defaultCoercion, minLength: Int? = nil, maxLength: Int? = nil) throws {
        if let min = minLength, let max = maxLength, min > max { throw BadRangeError(min: min, max: max) }
        self.elementType = elementType
        self.minLength = minLength ?? 0
        self.maxLength = maxLength ?? Int.max
    }
    
    public init(_ elementType: NativeCoercion = defaultCoercion) {
        self.elementType = elementType
        self.minLength = 0
        self.maxLength = Int.max
    }

    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        // TO DO: if an item fails to coerce, catch and rethrow error describing entire list, including index of the item that failed to coerce? (Q. should failed item be described using chunk expression, e.g. `item 3 of […]`? depends on how integral chunk exprs are to language: being library-defined, what would be fallback if/when they’re not loaded?)
        let result: [Value]
        switch value {
        case let v as SelfEvaluatingValue:
            result = try v.eval(in: scope, as: AsArray(self.elementType.swiftCoercion)) // TO DO: pass min/max to AsArray()?
        case let v as OrderedList:
            if v.data.isEmpty {
                result = []
            } else {
                var itemType = type(of: v.data[0])
                var coerceFunc = self.elementType.coerceFunc(for: itemType)
                var i = 0
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
        // TO DO: would it be better to verify list length before processing its items?
        if result.count < self.minLength || result.count > self.maxLength {
            throw ConstraintCoercionError(value: value, coercion: self)
        }
        return OrderedList(result)
    }
}

public let asOrderedList = AsOrderedList()
