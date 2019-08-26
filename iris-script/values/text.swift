//
//  text.swift
//  iris-script
//

// from user's POV, scalars are one datatype ('text')

// TO DO: how should Equatable and Hashable be implemented? (particularly if we treat numbers and strings as interchangeable, as normalization and localization issues could make this extremely complicated)


import Foundation


// Q. need to decide on interpolated strings - should they be a distinct datatype with literal representation, or library-defined `format_text {template, …}`; it may help to compare 'interpolated' lists, where list items may be resolved at runtime by commands, e.g. `["foo",bar,"baz",fub-2]`


struct Text: BoxedScalarValue, ExpressibleByStringLiteral {
    
    public var description: String { return self.data.debugDescription } // temporary
    
    public typealias StringLiteralType = String
    
    public let nominalType: Coercion = asString
    
    // TO DO: what about constrained type[s]?
    
    let data: String // TO DO: what about capturing 'skip' indexes, e.g. linebreak indexes, for faster processing in common operations, e.g. slicing string using integer indexes (Q. how often are random access operations really performed? and to what extent are those the result of naive/poor idioms/expressibility vs actual need); also cache length if known? (depends on String's internal implementation, but it's probably O(n))
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(_ data: String) {
        self.data = data
    }
    
    func toInt(in scope: Scope, as coercion: Coercion) throws -> Int {
        guard let result = Int(self.data) else { // Int("0.0") returns nil, so need additional fallback
            if let n = Double(self.data), let result = Int(exactly: n) { return result } 
            throw ConstraintError(value: self, coercion: coercion)
        }
        return result
    }
    func toDouble(in scope: Scope, as coercion: Coercion) throws -> Double {
        guard let result = Double(self.data) else { throw ConstraintError(value: self, coercion: coercion) }
        return result
    }
    func toString(in scope: Scope, as coercion: Coercion) throws -> String {
        return self.data
    }
    func toNumber(in scope: Scope, as coercion: Coercion) throws -> Number {
        return try Number(self.data)
    }
}


extension Text: KeyConvertible {
    
    func hash(into hasher: inout Hasher) {
        self.data.hash(into: &hasher)
    }
    
    static func == (lhs: Text, rhs: Text) -> Bool {
        return lhs.data == rhs.data //lhs.data.localizedCaseInsensitiveCompare(rhs.data) == .orderedSame
    }
    

}


// Date (use ISO8601 format when coercing to/from Text/String)


// URL (slightly tricky in that we want it to support FS paths too without requiring explicit `file:// localhost` or URL encoding); Q. URL or URI?
