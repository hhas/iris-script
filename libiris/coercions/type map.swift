//
//  type map.swift
//  libiris
//

// TO DO: regarding rountripping, should there be one rule for implicit coercions and another for explicit casts; e.g. `false as string` could cast to “false”; or should we use separate conversion command? part of the problem is how to convert values to string representation, e.g. `"the value of foo is: " & foo`; however, we could argue that unless *all* values will coerce to string in this use case then there is no benefit to having only some of them coerce (and a big negative, since the behavior will be inconsistent, meaning the same code may succeed or fail entirely due to the type of value being passed—which is the sort of unpredictability we *really* want to avoid); best to use a `format` command to convert any value to its literal representation string (the converse being `parse`, which takes a literal representation string and converts it to a value; c.f. kiwi), with the option to pass a string into which the value[s] can be interpolated

// TO DO: if we stick with coercion tables (which are currently global), they will need to move into Scope

import Foundation

// TO DO: problem here is that we need to be able to parameterize coercions with constraints (e.g. min/max)


// TO DO: what about switch-based dispatch for common cases; how will that compare for speed?

public class TypeMap<SwiftType>: SwiftCoercion {
    
    public typealias CoerceFunc = (Value, Scope) throws -> SwiftType
    public typealias Coercions  = [(t: Value.Type, fn: CoerceFunc)]
    public typealias WrapFunc   = (_ value: SwiftType, _ scope: Scope) -> Value

    private(set) public var coercions = Coercions()
    
    public let name: Symbol
    
    public let swiftLiteralDescription: String
    
    public let wrapFunc: WrapFunc // inability to declare abstract methods means we must either define `wrap` method as `let wrap: WrapFunc` or else bounce wrap() calls off here; in theory we could define placeholder method as extension to TypeMap and concrete method as extension to TypeMap<ConcreteType>, but Swift then chooses former over latter which is no damn use at all
    
    public required init(_ name: Symbol, _ swiftName: String,
                         _ boxFunc: @escaping WrapFunc, _ addUnboxFuncs: (TypeMap<SwiftType>)->Void = {_ in ()}) {
        //assert(!(SwiftType.self is SelfEvaluatingValue.Type))
        self.name = name
        self.swiftLiteralDescription = swiftName
        self.wrapFunc = boxFunc
        addUnboxFuncs(self)
    }
    
    public func add<T: Value>(_ coerceFunc: @escaping (T, Scope) throws -> SwiftType) {
        self.coercions.append((T.self, { try coerceFunc($0 as! T, $1) })) // this is annoying as we have to wrap each typed function in a closure in order to place it in coercions array, when the whole point of this alternate design was to reduce the depth of nested calls compared to the previous double/triple dispatch design
    }
    
    @inlinable public func coerceFunc(for valueType: Value.Type) -> CoerceFunc {
        if valueType == SwiftType.self { return { (v: Value, s: Scope) throws -> SwiftType in v as! SwiftType } }
        return self.coercions.first(where: {$0.t == valueType})?.fn ?? self.coerce
    }
    
    public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        switch value {
        case let v as SelfEvaluatingValue: return try v.eval(in: scope, as: self)
        case let v as SwiftType: return v
        default:
            if let t = self.coercions.first(where: {$0.t == type(of: value)}) { return try t.fn(value, scope) }
            throw TypeCoercionError(value: value, coercion: self)
        }
    }
}


public extension TypeMap where SwiftType: Value {
    
    @inlinable convenience init(_ name: Symbol, _ swiftName: String, _ add: (TypeMap<SwiftType>)->Void = {_ in ()}) {
        self.init(name, swiftName, {(v,_) in v}, add)
    }
    
    @inlinable func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return value
    }
    
    // this is no good as some Values (e.g. ElementRange) need to be used by Swift
//    @inlinable func coerce(_ value: Value, in scope: Scope) throws -> Value {
//        return try self.coerce(value, in: scope) as SwiftType
//    }
}


public extension TypeMap {
   
    @inlinable func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return self.wrapFunc(value, scope)
    }
}


//***************************************************************************************//


public typealias AsBool   = TypeMap<Bool>
public typealias AsSymbol = TypeMap<Symbol>


public typealias AsText = TypeMap<Text> // should allow bridging and native coercion

public typealias AsBlock = TypeMap<Block>
public typealias AsCommand = TypeMap<Command>


public let asBlock = AsBlock("block", "asBlock")
public let asCommand = AsCommand("command", "asCommand") // TO DO: needed? (used as Command.nominalType, but see also asLiteralCommand)
public let asBool = AsBool("boolean", "asBool")
public let asSymbol = AsSymbol("symbol", "asSymbol") // TO DO: should we support Text->Symbol? what about Symbol->Text?



public struct AsItself: Value, SwiftCoercion, NativeCoercion {

    public var swiftTypeDescription: String { return String(describing: SwiftType.self) }
    
    // “magical” coercion type; may be used as a handler return type to indicate that the handler should return the calling command (after boxing it so it can be passed around safely), e.g. defining a handler for the `returning` operator avoids confusing errors if `foo returning bar` is executed outside of a handler interface definition; compare `nothing`
    
    public typealias SwiftType = Value
    
    public static var nominalType: NativeCoercion = asCoercion.nativeCoercion
    
    public let name: Symbol = "itself"
    
    public let swiftLiteralDescription: String = "asItself"
    
    public let literalDescription: String = "itself"
    
    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        throw NotYetImplementedError()
    }
    
    public func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        return nullValue
    }
    
    public var nativeCoercion: NativeCoercion { // caution: glue generator filters by `HandlerType.result is AsItself`, so make sure handler interface hasn't wrapped it in NativizedCoercion or that test will fail
        return self
    }
    
    @inlinable public func coerceFunc(for valueType: Value.Type) -> CoerceFunc {
        return self.coerce
    }
}

public let asItself = AsItself()
