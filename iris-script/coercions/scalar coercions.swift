//
//  scalar.swift
//  iris-lang
//

// problem: double/triple dispatch, while consistent and predictable, is horribly expensive

// unlike sylvia, coercions aren't Values; instead use CoercionValue wrapper (Q. could coercions be ComplexValue?)

import Foundation


public protocol SwiftScalarCoercion: SwiftCoercion {}


// scalar coercions don't coerce to exact type, only to scalar (having satisfied that the value can be represented as that exact type if needed); Q. any benefit in caching exact value? what about values caching coercions in general? (particularly strings and collections, which can be large and expensive)

public struct AsValue: SwiftScalarCoercion {
    
    public let name: Symbol = "value"
    
    public typealias SwiftType = Value
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        return try value.toValue(in: scope, as: self)
    }
    
    public func intersect(with coercion: Coercion) -> Coercion {
        if let coercion = coercion as? AsOptional { return coercion.coercion }
        return asValue
    }
}

public struct AsInt: SwiftScalarCoercion {
    
    public let name: Symbol = "integer"
    
    public typealias NativeType = Int
    public typealias SwiftType = NativeType
    
    public func coerce(value: Value, in scope: Scope) throws -> Value { // this implementation preserves original value type; is there any benefit to this? (e.g. a Text value coerced to asInt remains a Text value; only its validity as an integer is checked; its constrained type could be updated to reflect this [if that provides any benefit over recalculating], or it could be otherwise annotated)
        let result: Value
        switch value {
        case is Int: return value
        case let v as ScalarValue: result = v
        default: result = try value.toScalar(in: scope, as: self)
        }
        
        if !(result is Int) { let _ = try value.toInt(in: scope, as: self) } // constraint check
        return result
    }
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        return try value.toInt(in: scope, as: self)
    }
    public func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}


public struct AsConstrainedInt: SwiftScalarCoercion {
    
    public var swiftLiteralDescription: String {
        let min: String, max: String
        if let n = self.min { min = String(n) } else { min = "nil" }
        if let n = self.max { max = String(n) } else { max = "nil" }
        return "\(type(of: self))(min: \(min), max: \(max))"
    }
    
    public let name: Symbol = "integer"
    
    public var description: String { // TO DO: code or descriptive text? (if descriptive, how to localize?)
        var result = self.name.label
        if let m = self.min { result += " from \(m)" }
        if let m = self.max { result += " up to \(m)" }
        return result
    }
    
    public typealias NativeType = Int
    public typealias SwiftType = NativeType
    
    let min: NativeType?, max: NativeType?
    
    public init(min: NativeType? = nil, max: NativeType? = nil) { // TO DO: also needs a nonZero constraint option (e.g. the denominator in division handlers)
        self.min = min
        self.max = max
    }
    
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        let result = try value.toInt(in: scope, as: self)
        if let m = self.min, result < m { throw ConstraintError(value: value, coercion: self) }
        if let m = self.max, result > m { throw ConstraintError(value: value, coercion: self) }
        return result
    }
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        return try value.toInt(in: scope, as: self)
    }
    public func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}

// TO DO: decide bignum, decimal, fractional; also quantity (although quantity will be composite of number and unit)

public struct AsDouble: SwiftScalarCoercion {
    
    public let name: Symbol = "real"
    
    public typealias NativeType = Double
    public typealias SwiftType = NativeType
    
    public func coerce(value: Value, in scope: Scope) throws -> Value { // this implementation preserves original type; is there any benefit to this? (in case of text-based numbers, it preserves original data where converting to Double would add FP rounding errors; this may be an argument in favor of using Number or other boxed value for FP numbers, as the original string can be captured too)
        let result = try value.toScalar(in: scope, as: self)
        if !(result is Double) { let _ = try value.toDouble(in: scope, as: self) }
        return result
    }
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        return try value.toDouble(in: scope, as: self)
    }
    public func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}

public struct AsString: SwiftScalarCoercion {
    
    public let name: Symbol = "string"
    
    public typealias SwiftType = String
    
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        switch value {
        case is ScalarValue: return value // int/double/string distinction should be invisible to users, so avoid potentially lossy conversions when manipulating data natively
        default: ()
        }
        return try value.toScalar(in: scope, as: self)
    }
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        return try value.toString(in: scope, as: self)
    }
    public func box(value: SwiftType, in scope: Scope) -> Value {
        return Text(value)
    }
}


public struct AsScalar: SwiftScalarCoercion {
    
    public let name: Symbol = "scalar"
    
    public typealias SwiftType = ScalarValue
    
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        return try value.toScalar(in: scope, as: self)
    }
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        return try value.toScalar(in: scope, as: self)
    }
    public func box(value: SwiftType, in scope: Scope) -> Value {
        fatalError()
    }
}

public let asScalar = AsScalar()


public let asValue = AsValue()
public let asInt = AsInt()
public let asDouble = AsDouble()
public let asString = AsString()



public struct AsNumber: SwiftScalarCoercion {
    
    public let name: Symbol = "number"
    
    public typealias NativeType = Number
    public typealias SwiftType = NativeType
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        // TO DO: is it worth using switches to reduce runtime processing of common types, or should we keep this rigorously consistent (and inefficient) and focus on performance improvement by better reasoning about types and interfaces
        switch value {
        case let v as Number: return v
        case let v as Int: return Number(v)
        case let v as Double: return Number(v)
        case let v as String: return try Number(v)
        default: ()
        }
        return try value.toNumber(in: scope, as: self)
    }
}


public let asNumber = AsNumber()

/*
 a = 0.3572920560836792
 b = 0.07959198951721191
 c1= 0.015359997749328613
 c2= 0.015278935432434082
 d1= 0.0006730556488037109
 d2= 0.0007450580596923828
 e = 0.0006870031356811523
 f = 0.0006799697875976562

 */
