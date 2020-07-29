//
//  errors.swift
//  libiris
//

// TO DO: localization

// TO DO: how to generalize error throwing to provide interactive runtime hooks (e.g. rather than call [NativeError].init directly, call a function that allows a custom hook to be installed over default throw behavior; while AST-walking interpreter precludes halting evaluator and breaking out of its main loop, threaded code could block on interpreter thread while separate user-interaction thread allows user inspection of issue; in an ideal world, the user could directly amend problem state and resume execution, although that may be require a more sophisticated interpreter architecture to enable; however, even being able to inspect errors at point of origin without having to set explicit breakpoints manually throughout code may be of help in getting code to work right)

// note that commands should use operator syntax when available (i.e. parser should annotate Command instance with PatternDefinition); as with message localization, how to provide modifiable/live view onto error attributes? (might consider developing a native DSL for transformable data composition, c.f. glue generator; e.g. once we have a form library that transforms handler interfaces to GUI forms, it shouldn't be much of a step to define error constructors as native handlers, complete with PP hinting, canonical [interpolated] error messages with hand/machine localization support, etc)

import Foundation


public protocol NativeError: Value, Error {
    
}

public extension NativeError {
    
    static var nominalType: NativeCoercion { return asError.nativeCoercion }

    func from(_ parent: Error) -> Error {
        return ChainedError(error: self, parent: parent)
    }
    
    func toValue(in scope: Scope, as coercion: NativeCoercion) throws -> Value {
        return self
    }
}


public struct ChainedError: NativeError { // problem with this approach is that it requires unwrapping to determine actual error type (defining a `parent:Error?` slot on every native error struct avoids this problem, but gets messy); main reason for chained exceptions is to construct native stack traces from chained HandlerError instances, so it might be simpler to limit error chaining support to HandlerError
    
    public var description: String { return "\(self.error)\n• \(self.parent)" }
    
    var error: Error
    var parent: Error
    
    public init(error: Error, parent: Error) {
        self.error = error
        self.parent = parent
    }
}
