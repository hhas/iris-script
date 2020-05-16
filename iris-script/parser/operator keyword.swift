//
//  operator keyword.swift
//  iris-script
//
//  an operator-defined keyword (including any aliases); used in patterns

import Foundation


// TO DO: how/where to ensure keyword names are all-letters or all-symbols? (best not to do it as runtime check, as operator tables are pre-generated; best to implement it in glue reader and any meta-commands [if someone managers to spanner the tables, worst that should happen is that operator never matches any token])


extension Symbol {

    var isSymbolic: Bool { return symbolCharacters ~= self.key }
}


struct Keyword: CustomDebugStringConvertible, ExpressibleByStringLiteral { // each operator keyword has a canonical (preferred) name and zero or more aliases, e.g. the division operator has the canonical name `÷` but can also be referred to by aliases `/` and `divided_by` (`/` is for convenience when entering code via ASCII keyboard while `divided_by` facilitates entering code via dictation; the PP will rewrite user's code to use the canonical name except when instructed otherwise)
    
    var debugDescription: String {
        return "Kw(\"\(self.name.label)\"\(self.aliases.map{ ", \"\($0.label)\"" }.joined(separator: "")))"
    }
    
    let name: Symbol
    let aliases: [Symbol] // TO DO: is it worth formally describing the motivation for adding each alias? (e.g. ASCII compatibility, dictation support, popular synonym)
    
    init(_ name: Symbol, aliases: [Symbol] = []) {
        self.name = name
        self.aliases = aliases
    }
    
    public init(_ name: Symbol, _ aliases: Symbol...) {
        self.init(name, aliases: aliases)
    }
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(Symbol(value))
    }
    
    func matches(_ name: Symbol) -> Bool {
        return self.name == name || self.aliases.contains(name)
    }
    
    func hasCanonicalName(_ name: Symbol) -> Bool {
        return self.name == name
    }
    func hasAliasName(_ name: Symbol) -> Bool {
        return self.aliases.contains(name)
    }
}
