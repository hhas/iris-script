//
//  enum coercions.swift
//  libiris
//

import Foundation


public struct AsChoice: NativeCoercion { // TO DO: support >1 type here? (if so, limit to HashableValue) or define separate versions for strings vs symbols? e.g. Shortcuts glue uses string values for enums
    
    public let name: Symbol = "choice"
    
    public var swiftTypeDescription: String { return "Symbol" } // this is imprecise, as valid values are a finite subset of all possible symbols, but sufficient to satisfy Swift parameter/attribute static typing (combined with dynamic membership checks), and bridging code should generally use Swift enums with generated glues anyway
    
    public var swiftLiteralDescription: String {
        return "AsChoice([\(self.options.map{$0.swiftLiteralDescription}.joined(separator: ", "))]).swiftCoercion"
    }
    
    public var literalDescription: String {
        return "\(self.name.label) [\(self.options.map{$0.literalDescription}.joined(separator: ", "))]"
    }
    
    private let options: Set<Symbol> // TO DO: ideally should capture the original ordered list for documentation purposes
    
    public init(_ options: Set<Symbol>) {
        self.options = options
    }
    
    public init(_ options: [Symbol]) {
        self.options = Set<Symbol>(options)
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        if let v = value as? SelfEvaluatingValue { return try v.eval(in: scope, as: self.swiftCoercion) }
        if let result = try? asSymbol.coerce(value, in: scope), self.options.contains(result) { return result }
        throw TypeCoercionError(value: value, coercion: self)
    }
}


let asChoice = AsChoice([])
