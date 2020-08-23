//
//  coercion protocols.swift
//  libiris
//

import Foundation

// TO DO: Coercion.hasConforming(value:Value)->Bool method; e.g. Int and Double should conform to Text (and String) as well as Number; natively this would be `value is_a coercion`; `as` _might_ use this to skip conversion where value types are natively interchangeable (although we need to be careful about that, as bridges to external systems such as Apple events and ObjC which do rely on nominal type-checking of arguments may require such values to be explicitly cast before being passed to those systems)

// TO DO: what about `where` clause on parameter record/result type for describing more complex constraints, e.g.:
//
//    number {min as integer, max as integer} where min < max returning number where min ≤ it ≤ max
//
// this’d provide run-time checking capabilities loosely comparable to dependent types and contract programming by evaluating these clause expressions in their own restricted env before/after evaluating handler’s body; one question is what operations should/shouldn’t be allowed within the clause, e.g. we probably don't want side effects and need to be careful about permitting arbitrary commands (which brings us back to how to specify complex/external requirements in primitive handler glues)
//
// Q. should `where` clause be allowed on individual record fields, e.g. `{min as integer, max as integer where min < it}`? this would need transformed to above form as Coercions only have access to the value being coerced, not to all argument fields, plus we don’t want it sensitive to order in which argument fields are unpacked
//


public protocol Coercion: LiteralConvertible {
    
    var name: Symbol { get }
    
    var literalDescription: String { get }
    var swiftLiteralDescription: String { get }
    var swiftTypeDescription: String { get }
    
}

public extension Coercion {
    
    // default implementation for literalDescription returns coercion’s name (this is also used as slot name when adding coercions to environment); coercions that can be parameterized (e.g. `list {of: integer {min: 1, max: 10}}`) should implement their own literalDescription property that provides full description, using name-only short form when all parameters are default values; thus `optional` formats as `optional` but `optional number` formats as `optional number` (or `optional {number}` if operator syntax isn’t available)
    var literalDescription: String { return self.name.label }
    //TO DO: `var swiftLiteralDescription: String { return "\(type(of:self))()" }` as default implementation? or is that too likely to mask bugs?
}


public protocol NativeCoercion: Value, Coercion {
    
    // we can't define NativeType as subtype of SwiftCoercion [whose SwiftType is always Value] as this protocol needs to be concrete for use in APIs (e.g. NativeCoercion is used as argument+attribute in coercion errors), and code becomes hopelessly complicated if everything else has to become generic
    
    func wrap(_ value: Value, in scope: Scope) -> Value // TO DO: redundant; can/should we get rid of this?
    func coerce(_ value: Value, in scope: Scope) throws -> Value
    
    func coerceFunc(for valueType: Value.Type) -> CoerceFunc // used by AsOrdered/KeyedList to reduce overheads when unpacking arrays of [mostly/all] same element type

    var swiftCoercion: PrimitivizedCoercion { get }
}

public extension NativeCoercion {
    
    var swiftTypeDescription: String { return String(describing: Value.self) }
    
    typealias CoerceFunc = (Value, Scope) throws -> Value
    
    static var nominalType: NativeCoercion { return asCoercion.nativeCoercion }
    
    @inlinable func wrap(_ value: Value, in scope: Scope) -> Value {
        return value
    }
    
    // default coerceFunc() implementation
    @inlinable func coerceFunc(for valueType: Value.Type) -> CoerceFunc {
        return self.coerce
    }
    
    var swiftCoercion: PrimitivizedCoercion { return PrimitivizedCoercion(self) }
}


//

public protocol SwiftCoercion: Coercion {
    
    associatedtype SwiftType
    
    typealias CoerceFunc = (Value, Scope) throws -> SwiftType
    typealias Coercions  = [(t: Value.Type, fn: CoerceFunc)]
    typealias WrapFunc   = (_ value: SwiftType, _ scope: Scope) -> Value

    func coerce(_ value: Value, in scope: Scope) throws -> SwiftType
    
    func wrap(_ value: SwiftType, in scope: Scope) -> Value
    
    var nativeCoercion: NativeCoercion { get }
}

public extension SwiftCoercion {
    
    var swiftTypeDescription: String { return String(describing: SwiftType.self) }
    
    // default coerceFunc() implementation
    @inlinable func coerceFunc(for valueType: Value.Type) -> CoerceFunc {
        return self.coerce
    }
    
    var nativeCoercion: NativeCoercion { // default implementation; this just wraps the primitive coercion
        return NativizedCoercion(self)
    }
}

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


//

public protocol ConstrainableCoercion: NativeCoercion {
    
    var interface: HandlerType { get }
    
    // some native coercions (numbers, lists, etc) can be specialized with additional constraints (element type, min/max, etc)
    
    // CallableCoercion (i.e. caller) is passed here for use in errors
    func constrain(to command: Command, in scope: Scope) throws -> NativeCoercion
}
