//
//  name value.swift
//  iris-lang
//

import Foundation



public struct Name: ComplexValue, ExpressibleByStringLiteral, Comparable, Hashable {
    
    public var description: String { return "#\(self.label)" }
    
    public typealias StringLiteralType = String
    
    // TO DO: rename Name? (for consistency with UnknownNameError)? not sure about this: symbols are also used as first-class values ("class"/"enum"/typeType/typeEnumerated)
    
    let nominalType: Coercion = asName
    
    public let label: String
    private let key: String // interning symbols would enable more efficient key representation, but for now it's sufficient to use case-normalized string
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(_ name: String) {
        self.label = name
        self.key = name.lowercased()
    }
    
    //
    
    public static func < (lhs: Name, rhs: Name) -> Bool {
        return lhs.key < rhs.key
    }
    
    public static func == (lhs: Name, rhs: Name) -> Bool {
        return lhs.key == rhs.key
    }
    
    public func hash(into hasher: inout Hasher) {
        self.key.hash(into: &hasher)
    }
}



let nullSymbol = Name("")

