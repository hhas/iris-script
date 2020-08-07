//
//  native coercion wrapper.swift
//  libiris
//

import Foundation

// TO DO: Coercion.primitiveCoercion? (it'd be better if we could avoid mutually recursive conversions between Native and Swift coercions; the problem is how to make one a subtype of the other without getting type conflicts between primitive and native versions of coerce methods [i.e. this is how we ended up with separate coerce and unbox methods last time, which degenerates into separate eval+call+coerce and swiftEval+swiftCall+unbox execution paths throughout the entire codebase, which is just horrible in every way])


public struct NativizedCoercion<ElementType: SwiftCoercion>: NativeCoercion {
    
    // TO DO: printing value description has a tendency to infinitely recurse when printing handler interface if interface contains nativized coercions (which it often does); for now, we break this cycle by printing primitive representation, but this requires further thought (in theory, every SwiftCoercion should return a true native equivalent, but in practice that may not always be possible/desirable, plus it’s more implementation overhead for coercions that are unlikely to be introspected outside of documentation [where descriptions can be elided/summarized for human readability only])
    
    public typealias SwiftType = Value
    
    public var name: Symbol { return self.elementType.name }
    
    // TO DO: the returned Swift code may or may not be appropriate to context
    public var swiftLiteralDescription: String { return self.elementType.swiftLiteralDescription }
    public var literalDescription: String { return self.elementType.literalDescription }
    
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
}


public struct PrimitivizedCoercion: SwiftCoercion {
    
    public typealias SwiftType = Value
    
    public var name: Symbol { return self.elementType.name }
    
    // TO DO: the returned Swift code may or may not be appropriate to context
    public var swiftLiteralDescription: String { return self.elementType.swiftLiteralDescription }
    public var literalDescription: String { return self.elementType.literalDescription }
    
    public let elementType: NativeCoercion
    
    public init(_ elementType: NativeCoercion) {
        self.elementType = elementType
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        return try self.elementType.coerce(value, in: scope)
    }
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}


// a callable wrapper that allows the encapsulated NativeCoercion to be specialized via command, e.g. `list {of: integer {min: 0, max: 100}, length: 4}`; once constrained, the wrapper is discarded to prevent an already constrained coercion being called twice (having NativeCoercions conform to Callable makes storing and retrieving them a right pain, since an environment lookup is performed using an arg-less command, which a directly-callable coercion couldn’t distinguish from a constraint call, causing it to replace the previous constraints with new, default constraints)

public struct CallableCoercion: NativeCoercion, Callable {
    
    public var interface: HandlerInterface { return self.elementType.interface }
    
    public typealias SwiftType = Value
    
    public var name: Symbol { return self.elementType.name }
    
    // TO DO: the returned Swift code may or may not be appropriate to context
    public var swiftLiteralDescription: String { return self.elementType.swiftLiteralDescription }
    public var literalDescription: String { return self.elementType.literalDescription }
    
    public let elementType: ConstrainableCoercion
    
    public init(_ elementType: ConstrainableCoercion) {
        self.elementType = elementType
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        return try self.elementType.coerce(value, in: scope)
    }
    
    public func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        return try coercion.coerce(command.arguments.isEmpty ? self.elementType
            : self.elementType.constrain(to: command, in: scope), in: scope)
    }
}
