//
//  record errors.swift
//  libiris
//

// TO DO: consolidate under common protocol that covers both Command and Record

// TO DO: change message to "is missing" if index >= command.arguments.count

// TO DO: error messages need more work: if last field label is mismatched, the error is reported as “missing field”, but we really need the full record type as argument so we can actually analyse the mismatch here

import Foundation


public protocol FieldError: NativeError {
    
    var index: Int { get }
    var fields: Record.Fields { get }
}


public struct UnknownFieldError: FieldError {
    
    public var description: String {
        return "Can’t match field \(self.index+1) in `\(self.fields.literalDescription)`\(self.fieldType == nil ? "" : " to \(self.fieldType!.label)")"
    }

    public let index: Int
    public let fields: Record.Fields
    public let fieldType: RecordType.Field?
    
    public init(at index: Int, of fields: Record.Fields, to fieldType: RecordType.Field? = nil) {
        self.index = index
        self.fields = fields
        self.fieldType = fieldType
    }
}


public struct BadFieldValueError: FieldError {
    
    public var description: String {
        return "Can’t evaluate field \(self.index+1) in `\(self.fields.literalDescription)`\(self.fieldType == nil ? "" : " as \(self.fieldType!.coercion)")"
    }
    
    public let index: Int
    public let fields: Record.Fields
    public let fieldType: RecordType.Field?
    
    public init(at index: Int, of fields: Record.Fields, to fieldType: RecordType.Field? = nil) {
        self.index = index
        self.fields = fields
        self.fieldType = fieldType
    }
}

