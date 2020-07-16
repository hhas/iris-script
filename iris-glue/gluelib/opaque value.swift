//
//  opaque value.swift
//  iris-glue
//

import Foundation
import iris



public class OpaqueValue<T>: Handler, Mutator {
    
    public var swiftLiteralDescription: String { return "«opaque_value»" }
        
    public static var nominalType: Coercion { return asValue } // TO DO: what should this return? (there’s no asOpaqueValue as OpaqueValue is a generic)
    
    public var description: String { return "«opaque_value»" }
    
    public var data: T // data is directly accessed from Swift code
    
    public init(_ data: T) {
        self.data = data
    }
    
    // TO DO: not sure about these:
    
    public var immutableValue: Value { return self }
    
    public func eval(in scope: Scope, as coercion: Coercion) throws -> Value {
        return try coercion.coerce(value: self, in: scope)
    }
    
    public func swiftEval<T: SwiftCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
        throw NotYetImplementedError()
    }
    
    public func call(with command: Command, in scope: Scope, as coercion: Coercion) throws -> Value {
        throw NotYetImplementedError()
    }
    
    public func swiftCall<T>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType where T : SwiftCoercion {
        throw NotYetImplementedError()
    }
}



typealias OpaqueHandlerGlues = OpaqueValue<[HandlerGlue]>

let asHandlerGlues = AsComplex<OpaqueHandlerGlues>(name: "opaque_handler_glues")

let handlerGluesName = Symbol(".handler_glues")
