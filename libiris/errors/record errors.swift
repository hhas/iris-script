//
//  record errors.swift
//  libiris
//

// TO DO: consolidate under common protocol that covers both Command and Record

import Foundation




public protocol FieldError: NativeError {
    
    var index: Int { get }
    var fields: Record.Fields { get }
}


public struct UnknownFieldError: FieldError {
    
    public var description: String { return "Can’t match field \(self.index+1) in `\(self.fields)`" }
    
    public let index: Int
    public let fields: Record.Fields
    
    public init(at index: Int, of fields: Record.Fields) {
        self.index = index
        self.fields = fields
    }
}

public struct BadFieldValueError: FieldError {
    
    public var description: String { return "Can’t evaluate field \(self.index+1) in `\(self.fields)`" } // TO DO: change message to "is missing" if index >= command.arguments.count
    
    public let index: Int
    public let fields: Record.Fields
    
    public init(at index: Int, of fields: Record.Fields) {
        self.index = index
        self.fields = fields
    }
}

