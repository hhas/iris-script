//
//  type errors.swift
//  libiris
//

import Foundation



public struct MalformedRecordError: NativeError {
    
    public var description: String { return "Found duplicate name `\(self.name.label)` in record \(self.fields)" } // TO DO: format
    
    let name: Symbol
    let fields: [Record.Field]
    
    public init(name: Symbol, in fields: [Record.Field]) {
        self.name = name
        self.fields = fields
    }
}


struct BadInterfaceError: NativeError { // TO DO: where should this be defined/used?
    
    public var description: String { return "Invalid interface: \(self.interface)." }
    
    public let interface: HandlerInterface
    
    public init(_ interface: HandlerInterface) {
        self.interface = interface
    }
}


public struct BadRangeError: NativeError {
    
    public var description: String { return "Not a valid range: \(self.min) thru \(self.max)" }
    
    public let min: Value, max: Value
}
