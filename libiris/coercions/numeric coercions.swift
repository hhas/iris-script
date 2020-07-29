//
//  scalar coercions.swift
//  libiris
//

import Foundation

// TO DO: need to implement String-to-Int/Double conversion that accepts same chars as literal numbers (e.g. various +/- chars)

//***************************************************************************************//
// coercions

// Int

func textToInt(value: Text, in scope: Scope) throws -> Int {
    /// The string passed as `description` may begin with a plus or minus sign
    /// character (`+` or `-`), followed by one or more numeric digits (`0-9`).
    if let result = Int(value.data) { return result } // note that Int("1.0") returns nil
    if let n = Double(value.data) { return try doubleToInt(value: n, in: scope) }
    throw ConstraintCoercionError(value: value, coercion: asInt) // TO DO: these errors should use calling coercion
}

func doubleToInt(value: Double, in scope: Scope) throws -> Int {
    if let result = Int(exactly: value) { return result }
    throw ConstraintCoercionError(value: value, coercion: asInt)
}

func numberToInt(value: Number, in scope: Scope) throws -> Int {
    return try value.toInt()
}

func boxValue<T: Value>(value: T, scope: Scope) -> Value {
    return value
}

public let _asInt = TypeMap<Int>("integer", "asInt", boxValue, {
    $0.add(doubleToInt)
    $0.add(numberToInt)
    $0.add(textToInt)
})



// Double

func intToDouble(value: Int, in scope: Scope) throws -> Double {
    return Double(value)
}

func numberToDouble(value: Number, in scope: Scope) throws -> Double {
    return try value.toDouble()
}

func textToDouble(value: Text, in scope: Scope) throws -> Double {
    /// The string passed as `description` may begin with a plus or minus sign
    /// character (`+` or `-`), followed by one or more numeric digits (`0-9`).
    if let n = Double(value.data) { return n }
    throw ConstraintCoercionError(value: value, coercion: iris.asValue)
}


public let asDouble = AsDouble("real", "asDouble", {
    $0.add(intToDouble)
    $0.add(numberToDouble)
    $0.add(textToDouble)
})



// Number

func intToNumber(value: Int, in scope: Scope) throws -> Number {
    return Number(value)
}

func doubleToNumber(value: Double, in scope: Scope) throws -> Number {
    return Number(value)
}

func textToNumber(value: Text, in scope: Scope) throws -> Number {
    return try Number(value.data)
}

public let asNumber = AsNumber("number", "asNumber", {
    $0.add(intToNumber)
    $0.add(doubleToNumber)
    $0.add(textToNumber)
})




public struct AsInt: SwiftCoercion {
    
    public typealias SwiftType = Int
    
    public let name: Symbol = "integer"
    
    public var swiftLiteralDescription: String { return "asInt" }
    
    // TO DO: less inclined to override here; main benefit is when coercing homogenous lists, where coerceFunc is more efficient
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        switch value {
        case let v as Int: return v
        case let v as Double: if let res = Int(exactly: v) { return res }
        case let v as Text: if let r = Double(v.data), let res = Int(exactly: r) { return res }
        case let v as SelfEvaluatingProtocol: return try v.eval(in: scope, as: self)
        default: ()
        }
        return try _asInt.coerce(value, in: scope)
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
    
    public func coerceFunc(for valueType: Value.Type) -> CoerceFunc {
        switch valueType {
        case is Int.Type: return { (v, _) in
            return v as! Int
            }
        case is Double.Type: return { (v, _) in
            if let res = Int(exactly: v as! Double) { return res }
            throw TypeCoercionError(value: v, coercion: self)
            }
        case is Number.Type: return { (v, _) in
            return try (v as! Number).toInt()
            }
        case is Text.Type: return { (v, _) in
            let data = (v as! Text).data
            if let result = Int(data) { return result } // note that Int("1.0") returns nil
            if let n = Double(data), let res = Int(exactly: n) { return res }
            throw TypeCoercionError(value: v, coercion: self)
            }
        default: return _asInt.coerceFunc(for: valueType)
        }
    }
}

public let asInt = AsInt()
