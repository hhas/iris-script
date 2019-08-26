//
//  swift literal.swift
//  iris-script
//

import Foundation


protocol SwiftLiteralConvertible {
    var swiftLiteralDescription: String { get }
}

extension Array: SwiftLiteralConvertible {
    var swiftLiteralDescription: String { return "[\(self.map(formatSwiftLiteral).joined(separator: ", "))]" }
}
extension Dictionary: SwiftLiteralConvertible {
    var swiftLiteralDescription: String { return "[\(self.map{"\(formatSwiftLiteral($0)): \(formatSwiftLiteral($1))"}.joined(separator: ", "))]" }
}
extension Set: SwiftLiteralConvertible {
    var swiftLiteralDescription: String { return "Set<\(type(of: Element.self))>([\(self.map(formatSwiftLiteral).joined(separator: ", "))])" }
}


func formatSwiftLiteral(_ value: Any) -> String {
    switch value {
    case let v as Bool: return String(v)
    case let v as Int: return String(v)
    case let v as Double: return String(v)
    case let v as String: return v.debugDescription
    case let v as SwiftLiteralConvertible: return v.swiftLiteralDescription
    //case let v as CustomDebugStringConvertible: return v.debugDescription // TO DO: not sure about Date; what else?
    default: fatalError("Can't format Swift \(type(of: value)) as literal: \(value)")
    }
}
