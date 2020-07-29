//
//  scalar coercions.swift
//  libiris
//

import Foundation

// TO DO: what about Bool<->String? (depends if we use empty values as false and non-empty as true; if so, `nothing`, false, “”, [], {} are false, and everything else is true) we do need to ensure any values roundtrip reliably, thus `false as string as boolean` must return false, i.e. `false as string` must return “” and `true as string` must return…something (“OK” “…” “#”, “*”); remember, `VALUE as text` is a conformance check, indicating VALUE may be used anywhere that a Text value is accepted (or converted to a String representation)



//***************************************************************************************//
// String

// unpack funcs take a Value of known type and return the desired type; used by unbox()

func textToString(value: Text, in scope: Scope) throws -> String {
    return value.data
}

func intToString(value: Int, in scope: Scope) throws -> String {
    return String(value)
}

func doubleToString(value: Double, in scope: Scope) throws -> String {
    return String(value) // value.literalDescription?
}

func numberToString(value: Number, in scope: Scope) throws -> String {
    return value.literalDescription
}

func stringToText(value: String, in scope: Scope) -> Value {
    return Text(value)
}

let _asString = TypeMap<String>("string", "asString", stringToText, {
    $0.add(textToString)
    $0.add(intToString)
    $0.add(doubleToString)
    $0.add(numberToString)
})

// hardcoding common cases as switch rather than lookup table gives 30-50% improvement in speed

public struct AsString: SwiftCoercion {
    
    public typealias SwiftType = String
    
    public let name: Symbol = "string"
    
    public var swiftLiteralDescription: String { return "asString" }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        switch value {
        // TO DO: if/when String conforms to Value, add extra case for it here
        case let v as Text: return v.data
        case let v as SelfEvaluatingProtocol: return try v.eval(in: scope, as: self)
        case let v as Int: return String(v)
        case let v as Double: return String(v)
        default: return try _asString.coerce(value, in: scope)
        }
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return Text(value)
    }
    
    public func coerceFunc(for valueType: Value.Type) -> CoerceFunc {
        if valueType == Text.self {
            return {(v,s) throws -> String in (v as! Text).data}
        } else if valueType == Int.self {
            return {(v,s) throws -> String in String(v as! Int)}
        } else if valueType == Double.self {
            return {(v,s) throws -> String in String(v as! Double)}
        }
        return _asString.coerceFunc(for: valueType)
    }
}


public let asString = AsString()


//***************************************************************************************//
// Text

func intToText(value: Int, in scope: Scope) throws -> Text {
    return Text(String(value))
}

func doubleToText(value: Double, in scope: Scope) throws -> Text {
    return Text(String(value)) // value.literalDescription?
}

func numberToText(value: Number, in scope: Scope) throws -> Text {
    return Text(value.literalDescription)
}


public let asText = AsText("string", "asText", {
    $0.add(intToText)
    $0.add(doubleToText)
    $0.add(numberToText)
})


