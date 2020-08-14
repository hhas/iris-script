//
//  multihandler.swift
//  libiris
//
//  enables overloading of handler slots

import Foundation

// caution: this is kludgy, slow, and for experimental use; it does not allow mixing of handlers and non-handlers (e.g. env slots that contain non-callable values, CallableCoercion)

// TO DO: how to dispatch on, say, `find [string|pattern] in: string replacing_with: [string|callable {…} returning string]`? or should that be a single handler which does its own routing once it’s unpacked the command arguments? what about overloading `find` to search lists and dicts?

// TO DO: once coercions support is_a, can we order handlers so that the most specific argument types are tested for first?


public class MultiHandler: Handler { // caution: each multihandler is currently a mutable class instance, which could cause problems when reassigning to other slots
    
    public typealias Call = (_ command: Command, _ commandEnv: Scope, _ handler: Handler, _ handlerEnv: Scope, _ coercion: NativeCoercion) throws -> Value // all generated `procedure_NAME_PARAMS` functions in _handlers.swift glue have this signature
        
    public let interface: HandlerType // TO DO: this can only contain name, as parameter records will differ
    
    private var handlers = [Handler]()
    
    public init(named name: Symbol) {
        self.interface = HandlerType(name: name, parameters: [], result: asAnything) // TO DO: how to indicate multihandler?
    }
    
    public func add(_ handler: Handler) {
        self.handlers.append(handler)
    }
    
    // TO DO: ideally the handler lookup would be done once on first use and the best-match handler bound to command; however, there is an obvious problem with binding before all handlers are defined, so for now this will only bind the multihandler to the command, and every call to it will repeat the argument match which is crazy wasteful (that could be reduced by caching the best-matched handler)
    public let isStaticBindable = true // see also notes on other handler types
    
    
    public func call<T: SwiftCoercion>(with command: Command, in commandScope: Scope, as coercion: T) throws -> T.SwiftType {
        var result: Handler?
        var missedParams = Int.max // params that were stepped over
        var excessParams = Int.max  // params left after all args are matched
        loop: for handler in self.handlers where command.arguments.count <= handler.interface.parameters.count {
            var argIndex = 0, paramIndex = 0
            var misses = 0
            let args = command.arguments, params = handler.interface.parameters
            //print("matching", args, "to", params)
            while argIndex < args.count && paramIndex < params.count {
                let arg = args[argIndex]
                let param = params[paramIndex]
                // this is based on field matching logic in Record.Fields (ideally we’d use that implementation, but this is just kludged together for now while we work out behavior)
                //print("…matching", arg, "to", param)
                if arg.label.isEmpty || arg.label == param.label {
                    argIndex += 1
                    paramIndex += 1
                } else { // field has different label so either the requested field has been omitted from record or this is not a match; if not, break loop // TO DO: how to check if field is optional/default? (can’t test coercion’s type as any built-in/third-party coercion can choose to accept nullValue, plus the coercion itself may be masked by e.g. Precis wrapper; easiest way is to apply the coercion to the value and see if it succeeds or fails, but that doesn’t really work for lazily-evaluated params which will pass now but may fail later) [also, bear in mind that an expression-based argument may return nullValue, so the presence of an argument doesn’t guarantee it won’t be “optional” on some calls]
                    misses += 1
                    paramIndex += 1
                    if misses > missedParams { print("cont 1"); continue loop } // this is a worse partial match than the one we already have
                }
            }
            if argIndex < args.count { print("cont 2", argIndex, args.count); continue loop } // not all args were matched, so this can’t be the right handler
            let remainingParams = params.count - paramIndex
            if remainingParams > 0 { // args are fully consumed but one or more params are unmatched
                if remainingParams > excessParams { continue loop }
                if remainingParams == excessParams {
                    print("Warning: found 2 equally weighted handlers (misses: \(misses), excess: \(excessParams)): \(result!) vs. \(handler). This will be a problem if no better match is found.")
                }
            }
            result = handler
            missedParams = misses
            excessParams = remainingParams
        }
        guard let handler = result else {
            throw HandlerError(handler: self, command: command).from(InternalError(description: "No matching handler for: \(command)\nFound these candidates: \(self.handlers.map{"\n\t\($0)"}.joined(separator: ""))"))
        }
        return try handler.call(with: command, in: commandScope, as: coercion)
    }
}



