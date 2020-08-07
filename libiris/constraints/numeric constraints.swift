//
//  numeric constraints.swift
//  libiris
//

import Foundation



public struct IntConstraint<ElementType: SwiftCoercion>: SwiftCoercion where ElementType.SwiftType: FixedWidthInteger {
    
    public var name: Symbol { return self.elementType.name }
    
    public typealias SwiftType = ElementType.SwiftType
    
    public var swiftLiteralDescription: String {
        var range = ""
        if let n = self.min { range += ", min: \(n)" }
        if let n = self.max { range += ", max: \(n)" }
        return "\(type(of: self))(\(self.elementType.swiftLiteralDescription)\(range))"
    }
    
    public let elementType: ElementType
    private let min: SwiftType?, max: SwiftType?
    
    public init(_ elementType: ElementType, min: SwiftType? = nil, max: SwiftType? = nil) {
        self.elementType = elementType
        self.min = min
        self.max = max
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> ElementType.SwiftType {
        let result = try self.elementType.coerce(value, in: scope)
        if let min = self.min, result < min { throw ConstraintCoercionError(value: value, coercion: self) }
        if let max = self.max, result > max { throw ConstraintCoercionError(value: value, coercion: self) }
        return result
    }
    
    public func wrap(_ value: ElementType.SwiftType, in scope: Scope) -> Value {
        return self.elementType.wrap(value, in: scope)
    }
}



public struct DoubleConstraint<ElementType: SwiftCoercion>: SwiftCoercion where ElementType.SwiftType: BinaryFloatingPoint {
    
    public var name: Symbol { return self.elementType.name }
    
    public typealias SwiftType = ElementType.SwiftType
    
    public var swiftLiteralDescription: String {
        var range = ""
        if let n = self.min { range += ", min: \(n)" }
        if let n = self.max { range += ", max: \(n)" }
        return "\(type(of: self))(\(self.elementType.swiftLiteralDescription)\(range))"
    }
    
    public let elementType: ElementType
    private let min: SwiftType?, max: SwiftType?
    
    public init(_ elementType: ElementType, min: SwiftType? = nil, max: SwiftType? = nil) {
        self.elementType = elementType
        self.min = min
        self.max = max
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> ElementType.SwiftType {
        let result = try self.elementType.coerce(value, in: scope)
        if let min = self.min, result < min { throw ConstraintCoercionError(value: value, coercion: self) }
        if let max = self.max, result > max { throw ConstraintCoercionError(value: value, coercion: self) }
        return result
    }
    
    public func wrap(_ value: ElementType.SwiftType, in scope: Scope) -> Value {
        return self.elementType.wrap(value, in: scope)
    }
}



// native

extension AsNumber: ConstrainableCoercion {
    
    public var interface: HandlerInterface { return AsNumber.interface_constrain }
    
    private static let type_constrain = (
        name: Symbol("number"),
        param_0: (Symbol("whole"), Symbol("whole"), AsSwiftDefault(asBool, false)),
        param_1: (Symbol("from"), Symbol("minimum"), AsSwiftOptional(asSwiftNumber)),
        param_2: (Symbol("to"), Symbol("maximum"), AsSwiftOptional(asSwiftNumber)), // TO DO: how to express `minimum < maximum` constraint? (this is getting into dependent types territory, which Swift doesn’t support, so would need to be checked during transpilation [if min+max are literal numbers] or else inserted into generated code as runtime checks); note that we could avoid this if we used a single "range" parameter e.g. `number 1 thru 10`- the challenge with that is how to express half-ranges, e.g. `number from 2`, `number to -1`?
        result: asCoercion
    )
    
    private static let interface_constrain = HandlerInterface(
        name: type_constrain.name,
        parameters: [
            nativeParameter(type_constrain.param_0),
            nativeParameter(type_constrain.param_1),
            nativeParameter(type_constrain.param_2),
        ],
        result: type_constrain.result.nativeCoercion
    )
    
    public func constrain(to command: Command, in scope: Scope) throws -> NativeCoercion {
        var index = 0
        let arg_0 = try command.value(for: AsNumber.type_constrain.param_0, at: &index, in: scope)
        let arg_1 = try command.value(for: AsNumber.type_constrain.param_1, at: &index, in: scope)
        let arg_2 = try command.value(for: AsNumber.type_constrain.param_2, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: self) }
        return try AsConstrainedNumber(isWhole: arg_0, min: arg_1, max: arg_2)
    }
}

