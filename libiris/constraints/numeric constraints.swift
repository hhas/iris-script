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
    
    private static let type_number = (
        name: Symbol("number"),
        param_0: (Symbol("whole"), Symbol("whole"), AsSwiftDefault(asBool, false)),
        param_1: (Symbol("from"), Symbol("minimum"), AsSwiftOptional(asSwiftNumber)),
        param_2: (Symbol("to"), Symbol("maximum"), AsSwiftOptional(asSwiftNumber)), // TO DO: how to express `minimum < maximum` constraint?
        result: asCoercion
    )
    
    private static let interface_number = HandlerInterface(
        name: type_number.name,
        parameters: [
            nativeParameter(type_number.param_0),
            nativeParameter(type_number.param_1),
            nativeParameter(type_number.param_2),
        ],
        result: type_number.result.nativeCoercion
    )
    
    public func constrain(with command: Command, in scope: Scope, as coercion: CallableCoercion) throws -> NativeCoercion {
        var index = 0
        let arg_0 = try command.value(for: AsNumber.type_number.param_0, at: &index, in: scope)
        let arg_1 = try command.value(for: AsNumber.type_number.param_1, at: &index, in: scope)
        let arg_2 = try command.value(for: AsNumber.type_number.param_2, at: &index, in: scope)
        if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: coercion) }
        if let min = arg_1, let max = arg_2, min > max { throw BadArgumentError(at: index, of: command, to: coercion) } // TO DO: how to insert custom checks into generated code? or should initializer perform check and throw on failure?
        return AsConstrainedNumber(isWhole: arg_0, min: arg_1, max: arg_2)
    }
}

