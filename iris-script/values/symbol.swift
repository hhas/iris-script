//
//  symbol.swift
//  iris-lang
//

import Foundation


// TO DO: need a better name than Symbol (ideally we want to talk about 'symbols' as syntax, not as semantics; e.g. `≠` is the Unicode symbol meaning 'not-equal', which stdlib defines as an infix operator for performing numerical comparisons); 'Hashtag' would avoid the immediate confusion, although 'hashtag' has its own common meaning which could mislead in other ways


public struct Symbol: ComplexValue, KeyConvertible, Comparable, ExpressibleByStringLiteral {
    
    public var description: String { return "#‘\(self.label)’" } // note: pp should only quote label if it's an operator name
    
    public var isEmpty: Bool { return self.label.isEmpty }
    
    public typealias StringLiteralType = String
    
    let nominalType: Coercion = asName
    
    public let label: String
    internal let key: String // interning symbols would enable more efficient key representation, but for now it's sufficient to use case-normalized string
    
    // if interning, need to make these inits private and provide public class method as constructor instead (one downside of this is that ExpressibleByStringLiteral will no longer be allowable, as the constructor needs to look for existing symbols in cache and return those when found; also need to decide what to use as keys - it may be an idea to move all state out of Symbol struct and store only an integer key - this'll reduce symbol comparisons to simple integer == test and eliminate string wrangling overheads; getting the label/description string will involve a cache hit each time, but that's a much less frequent operation than hash lookups and comparisons)
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(_ name: String) {
        self.label = name
        self.key = name.lowercased()
    }
    
    //
    
    public static func < (lhs: Symbol, rhs: Symbol) -> Bool {
        return lhs.key < rhs.key
    }
    
    public static func == (lhs: Symbol, rhs: Symbol) -> Bool {
        return lhs.key == rhs.key
    }
    
    public func hash(into hasher: inout Hasher) {
        self.key.hash(into: &hasher)
    }
}



let nullSymbol = Symbol("")

