//
//  handler errors.swift
//  libiris
//

import Foundation




public protocol ArgumentError: NativeError {
    
    var index: Int { get }
    var command: Command { get }
}


public struct UnknownArgumentError: ArgumentError {
    
    public var description: String { return "Can’t match argument field \(self.index+1) in `\(self.command)`" }
    
    public let index: Int
    public let command: Command
    
    public init(at index: Int, of command: Command) {
        self.index = index
        self.command = command
    }
}

public struct BadArgumentError: ArgumentError {
    
    public var description: String { return "Can’t evaluate argument field \(self.index+1) in `\(self.command)`" } // TO DO: change message to "is missing" if index >= command.arguments.count
    
    public let index: Int
    public let command: Command
    
    public init(at index: Int, of command: Command) {
        self.index = index
        self.command = command
    }
}



public struct HandlerError: NativeError {
    
    // TO DO: how to describe the handler’s owner (defining scope) within this error message:
    public var description: String { return "\(self.handler) failed on command: \(self.command)" }
    
    let handler: Handler
    let command: Command
    
    public init(handler: Handler, command: Command) {
        self.handler = handler
        self.command = command
    }
}
