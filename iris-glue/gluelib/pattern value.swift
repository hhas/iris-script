//
//  pattern value.swift
//  iris-glue
//

import Foundation
import iris



public class PatternValue: OpaqueValue<iris.Pattern> { // basic wrapper for parser’s Pattern enum, allowing it to be returned by pattern constructors used in `operator` syntax definitions

    public override var description: String { return "«pattern: \(self.data)»" }

}


public struct AsPattern: SwiftCoercion {
    
    public let name: Symbol = "pattern"
    
    public let swiftLiteralDescription = "asPattern"
    
    public typealias SwiftType = iris.Pattern
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        switch value {
        case let v as SelfEvaluatingValue: return try v.eval(in: scope, as: self)
        case let v as OrderedList: return try .sequence(v.data.map{ try asPattern.coerce($0, in: scope) })
        case let v as PatternValue: return v.data
        default: throw TypeCoercionError(value: value, coercion: self)
        }
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return PatternValue(value)
    }
}

let asPattern = AsPattern()


/*
struct AsScope: SwiftCoercion { // for now, this is purely to enable Swift func stubs to be generated with correct commandEnv/handlerEnv param types
    
    var swiftLiteralDescription: String { return "asScope" }
    
    let name: Symbol = "scope"
    
    typealias SwiftType = Scope
    
    func coerce(_ value: Value, in scope: Scope) throws -> Value {
        fatalError("Not yet implemented.")
    }
    
    func wrap(_ value: Scope, in scope: Scope) -> Value {
        fatalError("Not yet implemented.")
    }
    
    func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        fatalError("Not yet implemented.")
    }
}

let asScope = AsScope()
*/
