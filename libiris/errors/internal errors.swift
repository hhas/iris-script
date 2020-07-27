//
//  internal errors.swift
//  libiris
//

import Foundation



public struct InternalError: NativeError {

    public let description: String
    
    public init(description: String) {
        self.description = description
    }
    
    public init(_ error: Error) {
        self.init(description: String(describing: error))
    }
}


public struct NotYetImplementedError: NativeError {
    
    internal(set) public var parent: Error?
    
    public var description: String { return "`\(self._function)` is not yet implemented." }
    
    private let _function: String
    
    public init(_ _function: String = #function) {
        self._function = _function
    }
}



