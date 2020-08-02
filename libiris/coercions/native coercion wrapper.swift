//
//  native coercion wrapper.swift
//  libiris
//

import Foundation

// TO DO: Coercion.primitiveCoercion? (it'd be better if we could avoid mutually recursive conversions between Native and Swift coercions; the problem is how to make one a subtype of the other without getting type conflicts between primitive and native versions of coerce methods [i.e. this is how we ended up with separate coerce and unbox methods last time, which degenerates into separate eval+call+coerce and swiftEval+swiftCall+unbox execution paths throughout the entire codebase, which is just horrible in every way])


public struct NativizedCoercion<ElementType: SwiftCoercion>: ConstrainableNativeCoercion {
    
    // TO DO: printing value description has a tendency to infinitely recurse when printing handler interface if interface contains nativized coercions (which it often does); for now, we break this cycle by printing primitive representation, but this requires further thought (in theory, every SwiftCoercion should return a true native equivalent, but in practice that may not always be possible/desirable, plus it’s more implementation overhead for coercions that are unlikely to be introspected outside of documentation [where descriptions can be elided/summarized for human readability only])
    
    public var description: String { return "«\(self.swiftLiteralDescription)»" }
    
    public typealias SwiftType = Value
    
    public var name: Symbol { return self.elementType.name }
    
    // TO DO: the returned Swift code may or may not be appropriate to context
    public var swiftLiteralDescription: String { return self.elementType.swiftLiteralDescription }
    
    public let elementType: ElementType
    
    public init(_ elementType: ElementType) {
        self.elementType = elementType
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        return try self.elementType.wrap(self.elementType.coerce(value, in: scope), in: scope)
    }
    
    public func wrap(_ value: Value, in scope: Scope) -> Value {
        return value
    }
    
    public func call<T>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType where T : SwiftCoercion {
        if command.arguments.isEmpty {
            return try coercion.coerce(self, in: scope)
        } else {
            guard let nativeCoercion = self.elementType.nativeCoercion as? ConstrainableNativeCoercion,
                !(nativeCoercion is NativizedCoercion<ElementType>) else {
                throw NotAHandlerError(command: command, value: self)
            }
            return try nativeCoercion.call(with: command, in: scope, as: coercion)
        }
    }
}


public struct PrimitivizedCoercion: SwiftCoercion {
    
    public typealias SwiftType = Value
    
    public var name: Symbol { return self.elementType.name }
    
    // TO DO: the returned Swift code may or may not be appropriate to context
    public var swiftLiteralDescription: String { return self.elementType.swiftLiteralDescription }
    
    public let elementType: NativeCoercion
    
    public init(_ elementType: NativeCoercion) {
        self.elementType = elementType
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        return try self.elementType.coerce(value, in: scope)
    }
    public func wrap(_ value: Value, in scope: Scope) -> Value {
        return value
    }
}

