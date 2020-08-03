//
//  coercion protocols.swift
//  libiris
//

import Foundation

// TO DO: Coercion.hasConforming(value:Value)->Bool method; e.g. Int and Double should conform to Text (and String) as well as Number; natively this would be `value is_a coercion`; `as` _might_ use this to skip conversion where value types are natively interchangeable (although we need to be careful about that, as bridges to external systems such as Apple events and ObjC which do rely on nominal type-checking of arguments may require such values to be explicitly cast before being passed to those systems)


public protocol Coercion: LiteralConvertible {
    
    var name: Symbol { get }
    
    var literalDescription: String { get }
    var swiftLiteralDescription: String { get }
    
}

public extension Coercion {
    
    // default implementation for literalDescription returns coercion’s name (this is also used as slot name when adding coercions to environment); coercions that can be parameterized (e.g. `list {of: integer {min: 1, max: 10}}`) should implement their own literalDescription property that provides full description, using name-only short form when all parameters are default values; thus `optional` formats as `optional` but `optional number` formats as `optional number` (or `optional {number}` if operator syntax isn’t available)
    var literalDescription: String { return self.name.label }
    //TO DO: `var swiftLiteralDescription: String { return "\(type(of:self))()" }` as default implementation? or is that too likely to mask bugs?
}


public protocol NativeCoercion: Value, Coercion {
    
    // we can't define NativeType as associated type as this protocol needs to be concrete (e.g. NativeCoercion is used as argument+slot type in coercion errors); we could define a var/let that returns the native Value.Type, e.g. `Text.self`, if needed
    
    func wrap(_ value: Value, in scope: Scope) -> Value // TO DO: redundant; can/should we get rid of this?
    func coerce(_ value: Value, in scope: Scope) throws -> Value
}

public extension NativeCoercion {
    
    static var nominalType: NativeCoercion { return asCoercion.nativeCoercion }
    
    @inlinable func wrap(_ value: Value, in scope: Scope) -> Value {
        return value
    }
}


//

public protocol SwiftCoercion: Coercion {
    
    associatedtype SwiftType
    
    typealias CoerceFunc = (Value, Scope) throws -> SwiftType
    typealias Coercions  = [(t: Value.Type, fn: CoerceFunc)]
    typealias WrapFunc   = (_ value: SwiftType, _ scope: Scope) -> Value

    func coerce(_ value: Value, in scope: Scope) throws -> SwiftType
    
    func wrap(_ value: SwiftType, in scope: Scope) -> Value
    
    func coerceFunc(for valueType: Value.Type) -> CoerceFunc // used by AsArray to reduce overheads when unpacking arrays of [mostly/all] same element type
    
    var nativeCoercion: NativeCoercion { get }
}


public extension SwiftCoercion {
    
    // default coerceFunc() implementation
    @inlinable func coerceFunc(for valueType: Value.Type) -> CoerceFunc {
        return self.coerce
    }
    
    var nativeCoercion: NativeCoercion { // default implementation; this just wraps the primitive coercion
        return NativizedCoercion(self)
    }
}


//

public extension SwiftCoercion where SwiftType: Value {
    
    func coerce(_ value: Value, in scope: Scope) throws -> Value {
        return try self.coerce(value, in: scope) as SwiftType
    }
    @inlinable func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}

public extension SwiftCoercion where SwiftType == Value {
    
    @inlinable func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}



public protocol ConstrainableCoercion: NativeCoercion {
    
    // some native coercions (numbers, lists, etc) can be specialized with additional constraints (element type, min/max, etc)

    //var callableInterface: HandlerInterface { get }
    
    // CallableCoercion (i.e. caller) is passed here for use in errors
    func constrain(with command: Command, in scope: Scope, as coercion: CallableCoercion) throws -> Self
}
