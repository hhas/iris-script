//
//  text.swift
//  iris-script
//

// from user's POV, scalars are one datatype ('text')

// TO DO: how should Equatable and Hashable be implemented? (particularly if we treat numbers and strings as interchangeable, as normalization and localization issues could make this extremely complicated)


import Foundation

// TO DO: String should conform to Value, providing basic interchange for free; if we need a “smarter” native string (e.g. one that stores text as array of single paragraphs, allowing quicker random access) then define that as struct/class as below and have coercions treat it as interchangeable with String, same as Int/Double/Number

// Q. need to decide on interpolated strings - should they be a distinct datatype with literal representation, or library-defined `format_text {template, …}`; it may help to compare 'interpolated' lists, where list items may be resolved at runtime by commands, e.g. `["foo",bar,"baz",fub-2]` (also bear in mind that ScalarValues, being literal values, are meant to evaluate as themselves; an interpolated string value would be a non-literal expression whose value depends on where and when it's evaluated); also worth considering whether to use texttemplate as foundation for interpolation command


public struct Text: BoxedScalarValue, ExpressibleByStringLiteral, LiteralConvertible {
    
    public var swiftLiteralDescription: String { return self.data.debugDescription }
    
    public typealias StringLiteralType = String
    
    public static let nominalType: NativeCoercion = asString.nativeCoercion
    
    // TO DO: what about constrained type[s]?
    
    public let data: String // TO DO: what about capturing 'skip' indexes, e.g. linebreak indexes, for faster processing in common operations, e.g. slicing string using integer indexes (Q. how often are random access operations really performed? and to what extent are those the result of naive/poor idioms/expressibility vs actual need); also cache length if known? (depends on String's internal implementation, but it's probably O(n))
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(_ data: String) {
        self.data = data
    }
    
    //
    
    public var literalDescription: String {
        var result = ""
        for c in self.data { // escape double quotes
            result.append(c)
            if quotedStringDelimiterCharacters.contains(c) { result.append(c) }
        }
        return "“\(result)”"
    }
    
    // coercion
}


extension Text: KeyConvertible {
    
    public func hash(into hasher: inout Hasher) {
        self.data.hash(into: &hasher)
    }
    
    public static func == (lhs: Text, rhs: Text) -> Bool {
        return lhs.data == rhs.data //lhs.data.localizedCaseInsensitiveCompare(rhs.data) == .orderedSame
    }
}


// Date (use ISO8601 format when coercing to/from Text/String)


// URL (slightly tricky in that we want it to support FS paths too without requiring explicit `file:// localhost` or URL encoding); Q. URL or URI?
