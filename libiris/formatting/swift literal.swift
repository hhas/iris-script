//
//  swift literal.swift
//  iris-script
//

import Foundation


public protocol SwiftLiteralConvertible {
    var swiftLiteralDescription: String { get }
}

public protocol LiteralConvertible: SwiftLiteralConvertible {
    var literalDescription: String { get }
}
public extension LiteralConvertible {
    //var description: String { return self.literalDescription }
}


extension Array: SwiftLiteralConvertible {
    public var swiftLiteralDescription: String {
        return "[\(self.map(formatSwiftLiteral).joined(separator: ", "))]"
    }
}
extension Dictionary: SwiftLiteralConvertible {
    public var swiftLiteralDescription: String {
        return self.isEmpty ? "[:]"
            : "[\(self.map{"\(formatSwiftLiteral($0)): \(formatSwiftLiteral($1))"}.joined(separator: ", "))]"
    }
}
extension Set: SwiftLiteralConvertible {
    public var swiftLiteralDescription: String {
        return "Set<\(type(of: Element.self))>([\(self.map(formatSwiftLiteral).joined(separator: ", "))])"
    }
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
