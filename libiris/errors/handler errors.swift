//
//  handler errors.swift
//  libiris
//

import Foundation


// TO DO: calling a non-handler results in rather confusing error message, e.g. ‘nothing’ {4} -> “Can’t match argument field 1 of ‘nothing’ {1} for handler: ‘’ {} returning anything”


public protocol ArgumentError: NativeError { // TO DO: would it be better to have a single ArgumentError that uses an enum to describe the exact issue? or should we rely more on error chaining?
    
    var index: Int { get }
    var command: Command { get }
    var handlerInterface: HandlerInterface { get } // for now, only the handler's interface is held here (to capture the full Handler in usable form we'd need to copy it into a closure; however, with the Swift stack unwinding on returning errors there’s no easy way to support interactive correct-and-resume, so that’d only be wasted effort)
}


public struct UnknownArgumentError: ArgumentError {
    
    public var description: String {
        return "Can’t match argument field \(self.index+1) of \(self.command) to handler: \(self.handlerInterface)"
    }
    
    public let index: Int
    public let command: Command
    public let handlerInterface: HandlerInterface
    
    public init(at index: Int, of command: Command, to handler: Callable) {
        self.index = index
        self.command = command
        self.handlerInterface = handler.interface
    }
    
    public init(at index: Int, of command: Command, to coercion: ConstrainableCoercion) {
        self.init(at: index, of: command, to: CallableCoercion(coercion))
    }
}

public struct BadArgumentError: ArgumentError {
     // TO DO: change message to "is missing" if index >= command.arguments.count
    public var description: String {
        return "Can’t evaluate argument field \(self.index+1) of \(self.command) for handler: \(self.handlerInterface)"
    }
    
    public let index: Int
    public let command: Command
    public let handlerInterface: HandlerInterface
    
    public init(at index: Int, of command: Command, to handler: Callable) {
        self.index = index
        self.command = command
        self.handlerInterface = handler.interface
    }
    
    public init(at index: Int, of command: Command, to coercion: ConstrainableCoercion) {
        self.init(at: index, of: command, to: CallableCoercion(coercion))
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


public struct NotAHandlerError: NativeError {
    
    public var description: String { return "The \(self.command) command could not be handled by \(self.value.nominalType): \(self.value)" }
    
    let command: Command
    let value: Value
    
    public init(command: Command, value: Value) {
        self.command = command
        self.value = value
    }
}
