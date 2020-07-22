//
//  symbol.swift
//  iris-lang
//

import Foundation

// TO DO: should init validate string? (almost any character is allowed but there are exceptions, e.g. quotes and linebreaks; see quotedNameCharacters)

// TO DO: need a better name than Symbol (ideally we want to talk about 'symbols' as syntax, not as semantics; e.g. `≠` is the Unicode symbol meaning 'not-equal', which stdlib defines as an infix operator for performing numerical comparisons); 'Hashtag' would avoid the immediate confusion, although 'hashtag' has its own common meaning which could mislead in other ways
// (naming convention is also confounded by internal use of Symbol for identifiers [command/argument/field names] in addition to representing type/enum names as native values ['class' and 'constant' in AS])

public struct Symbol: AtomicValue, KeyConvertible, Comparable, ExpressibleByStringLiteral, SwiftLiteralConvertible { // TO DO: Identifiable
    
    public var swiftLiteralDescription: String { return self.label.debugDescription }
    
    public var description: String { return "#‘\(self.label)’" } // note: pp should only quote label if it contains non-identifier chars
    public var isEmpty: Bool { return self.label.isEmpty }
    
    public typealias StringLiteralType = String
    
    public static let nominalType: Coercion = asSymbol
    
    public let label: String
    public let key: String // interning symbols would enable more efficient key representation, but for now it's sufficient to use case-normalized string
    
    // if interning, need to make these inits private and provide public class method as constructor instead (one downside of this is that ExpressibleByStringLiteral will no longer be allowable, as the constructor needs to look for existing symbols in cache and return those when found; also need to decide what to use as keys - it may be an idea to move all state out of Symbol struct and store only an integer key - this'll reduce symbol comparisons to simple integer == test and eliminate string wrangling overheads; getting the label/description string will involve a cache hit each time, but that's a much less frequent operation than hash lookups and comparisons)
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(_ name: String) {
        self.label = name
        self.key = name.lowercased()
    }
    
    public init(_ name: Substring) { // convenience
        self.init(String(name))
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



public let nullSymbol = Symbol("")
