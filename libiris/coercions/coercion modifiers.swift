//
//  optional coercions.swift
//  iris-lang
//

import Foundation


// TO DO: need to decide naming convention

// TO DO: AsNullIntersection (empty set) that always throws on coerce/unbox

// TO DO: AsPrecis, AsVariant

// important: when catching NullCoercionError in 'optional' modifiers, always return `nullValue`, not the value that originally threw the error (in principle, the catch block could return `error.value`, but the whole point of the special `did_nothing` value throwing NullCoercionError is to ensure it degenerates to a normal `nothing` if not immediately caught by an enclosing `else` clause, in which case it triggers evaluation of the `else` operator’s alternate action [right-hand expression])


public struct AsNothing: Coercion { // used in HandlerInterface.result to return `nothing`
    
    public let name: Symbol = "nothing"
    
    public var swiftTypeDescription: String { return "" }
    
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        let _ = try asAnything.coerce(value: value, in: scope) // this still needs to evaluate value asAnything, discarding result (if value is scalar, it can be discarded immediately) // Q. how necessary is this? (i.e. we want to make sure last expr in handler evaluates, which could get funky when intersecting AsNothing with other coercions)
        return nullValue
    }
}

//


public struct MayDoNothing: SwiftCoercion {
    
    // TO DO: what should these vars return?
    
    public var swiftLiteralDescription: String { return self.coercion.swiftLiteralDescription }
    
    public var name: Symbol { return self.coercion.name }
    
    public var description: String { return self.coercion.description }
    
    public typealias SwiftType = Value
    
    public let coercion: Coercion
    
    public init(_ coercion: Coercion) {
        self.coercion = coercion
    }
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        do {
            //print("MayDoNothing evaling:", value)
            let result = try self.coercion.coerce(value: value, in: scope)
            //print("MayDoNothing got result:", result, type(of: result))
            return result
        } catch let e as NullCoercionError {
            //print("MayDoNothing caught null coercion error:", e)
            return e.value // important: whereas AsCoercion always returns nullValue, this returns the exact 'null' value that triggered the exception; thus if that value is `nullAction`, it will be passed back as-is rather than degraded to standard nullValue; on the flipside, we may want to rethrow if it's a standard nullValue as that should really be left to any AsOptional/AsDefault modifiers to deal with; at least for now it proves the mechanism by which flow control expressions (`if`, `while`, etc) may, upon not performing any action of their own, trigger the enclosing `else` operator to perform its alternate action
        }
    }
}




public struct AsOptional: SwiftCoercion { // this returns native Value; for Optional<Value> use MayBeNil
    
    public var swiftLiteralDescription: String { return "\(type(of: self))(\(self.coercion.swiftLiteralDescription))" }
    
    public let name: Symbol = "optional"
    
    public var description: String { return self.coercion.name == "value" ? "anything" : "optional \(self.coercion)" } // kludge
    
    public typealias SwiftType = Value
    
    public let coercion: Coercion
    
    public init(_ coercion: Coercion) {
        self.coercion = coercion
    }
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        do {
            // TO DO: there is a problem with null coercions not being intercepted correctly when value is a command invoking a native handler with default signature that returns nothing; the null coercion error is chained to handler error by the time it gets here, which bypasses the catch below (null coercion errors need to be caught close to point of origin, either to handle in the case of optional/default, or to promote to permanent coercion error; need to check how kiwi does it again)
            
            return try self.coercion.coerce(value: value, in: scope)
        } catch is NullCoercionError {
            return nullValue
        } catch {
       //     print(self.swiftLiteralDescription, "caught", type(of:error), error)
            throw error
        }
    }
}

public struct AsSwiftOptional<T: SwiftCoercion>: SwiftCoercion {
    
    public var swiftLiteralDescription: String { return "\(type(of: self))(\(self.coercion.swiftLiteralDescription))" }

    public let name: Symbol = "optional"
    
    public var description: String { return "\(self.coercion) or nothing" }
    
    public typealias SwiftType = T.SwiftType?
    
    private let coercion: T
    
    public init(_ coercion: T) {
        self.coercion = coercion
    }
    
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        do {
            return try self.coercion.coerce(value: value, in: scope)
        } catch is NullCoercionError {
            return nullValue
        }
    }
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        do {
            return try self.coercion.unbox(value: value, in: scope)
        } catch is NullCoercionError {
            return nil
        }
    }
    public func box(value: SwiftType, in scope: Scope) -> Value {
        guard let value = value else { return nullValue }
        return self.coercion.box(value: value, in: scope)
    }
}

//

public struct AsDefault: Coercion {
    
    public var swiftLiteralDescription: String {
        return "\(type(of: self))(\(self.coercion.swiftLiteralDescription), defaultValue: \(self.defaultValue.swiftLiteralDescription))"
    }
    
    public let name: Symbol = "default"
    
    public var description: String { return "\(self.coercion) or \(self.defaultValue)" }
    
    public let coercion: Coercion
    private let defaultValue: Value

    public init(_ coercion: Coercion = asValue, defaultValue: Value) { // TO DO: should coercion be defaultValue.nominalType/constrainedType?
        self.coercion = coercion
        self.defaultValue = defaultValue // TO DO: this should be member of coercion; how/where to check this? also need to consider how collections/exprs might be used here
    }
    
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        do {
            return try self.coercion.coerce(value: value, in: scope)
        } catch is NullCoercionError {
            return try self.coercion.coerce(value: self.defaultValue, in: scope)
        }
    }
    
    // TO DO: implement call() for creating new instances natively
}


public struct AsSwiftDefault<T: SwiftCoercion>: SwiftCoercion {
    
    public var swiftLiteralDescription: String {
        return "\(type(of: self))(\(self.coercion.swiftLiteralDescription), defaultValue: \(formatSwiftLiteral(self.defaultValue)))"
    }

    public let name: Symbol = "default"
    
    public var description: String { return "\(self.coercion) default: \(self.defaultValue)" }
    
    public typealias SwiftType = T.SwiftType
    
    private let coercion: T
    private let defaultValue: SwiftType
    
    public init(_ coercion: T, defaultValue: SwiftType) {
        self.coercion = coercion
        self.defaultValue = defaultValue // TO DO: this should be member of coercion; how/where to check this? also need to consider how collections/exprs might be used here
    }

    public func coerce(value: Value, in scope: Scope) throws -> Value {
        do {
            return try self.coercion.coerce(value: value, in: scope)
        } catch is NullCoercionError {
            return self.coercion.box(value: self.defaultValue, in: scope) // TO DO: cache if memoizable
        } catch {
            print("Coercion error «\(self)»", type(of:error), error)
            throw error
        }
    }
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        do {
            return try self.coercion.unbox(value: value, in: scope)
        } catch is NullCoercionError {
            return self.defaultValue
        } catch {
            print("Coercion error", self, error)
            throw error
        }
    }
    public func box(value: SwiftType, in scope: Scope) -> Value {
        //guard let value = value else { return nullValue }
        return self.coercion.box(value: value, in: scope)
    }
}



public let asNothing = AsNothing()

public let asAnything = AsOptional(asValue) // TO DO: also define native constant as Precis(AsOptional(asValue), "anything")




public struct AsEditable: SwiftCoercion {
    
    public var swiftLiteralDescription: String { return "\(type(of: self))(\(self.coercion.swiftLiteralDescription))" }

    // experimental; in effect, environment binds a box containing the actual value, giving behavior similar to Swift's pass-by-reference semantics using structs
    
    public let name: Symbol = "editable"
    
    public var description: String { return "editable \(self.coercion)" }
    
    public typealias SwiftType = EditableValue
    
    public let coercion: Coercion // the type to which the EditableValue instance's content should be coerced when setting it
    
    public init(_ coercion: Coercion = asAnything) {
        self.coercion = coercion
    }
    
    // seems a bit odd; goal here is really to wrap value in box; Q. when value is already editable, how do we avoid double-boxing? note that coercing a boxed value to a non-editable value needs to ask the value for an immutable representation of self
    
    // really need to think this through: AsEditable boxes the value; the resulting box is then bound in environment; getting the stored box retrieves it, evaling the boxed value updates the box's content to the resulting value and returns it (this is something to be aware of when passing the box between scopes)
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        print("AsEditable<\(self.coercion)>.unbox() received \(type(of: value)) value: \(value)")
        let result = try self.coercion.coerce(value: value, in: scope)
        // if value is already editable then update in-place
        if let editable = value as? EditableValue { // bit dicey (e.g. value could be an EditableValue, but wrapped in a Thunk)
            try editable.set(nullSymbol, to: result)  // TO DO: this is wrong assumes that the original value's underlying type is same as self.coercion, which it may not be; e.g. `set foo to 3 as editable number, set bar to foo as editable list of string` is legal code, but is going to break #foo slot's value; not sure what best answer is - perhaps only share the box if both types are identical, else create a new box? (that's probably not ideal either, as the point of using runtime coercions is to allow flexibility when a value isn't of the exact [nominal] type required but can be coerced to that type)
            // safe behavior passing in would be outertype isa innertype, but passing out would be innertype isa outertype, thus any mismatch between types means a constraint error may occur (type errors are acceptable from a dynamic typing POV - where the goal is to detect and raise early and clearly, not to avoid completely - although would be flagged as warning/error when linting/baking); given that common usage pattern is to type handler interfaces and leave bound values untyped, the outertype will normally be `editable [anything]`, unless the assignment operation parameterizes `EditableValue` with the bound value's nominal/constrained type
            return editable
        } else {
            return EditableValue(result, as: self.coercion)
        }
    }
}


public let asEditable = AsEditable()




// nominal type checks

public struct AsLiteral<T: Value>: SwiftCoercion { // caution: this only works for values that have native syntax (number, string, list, command, etc), not for values that require a constructor command (e.g. range/thru) // TO DO: also define AsLiteralCommand that allows command name and operands to be matched? (while this will be limited due to lack of vararg support in generics, in practice we really only need unary and binary matching as its main use will be matching operator exprs, most of which take one or two operands; alternatively, we could take AsRecord as argument, although that wouldn't support unboxing)
    
    public var swiftLiteralDescription: String { return "\(type(of: self))()" }

    public var name: Symbol { return T.nominalType.name } // TO DO: what should this be?
    
    public var description: String { return "literal \(self.name.label)" }
    
    // if the input Value is an instance of T, it is passed thru as-is without evaluation, otherwise an error is thrown // TO DO: Value.eval() will bypass this (another reason it needs to go away)
    
    public typealias SwiftType = T
    
    public init() { }
    
    public func unbox(value: Value, in env: Scope) throws -> SwiftType {
        guard let result = value as? SwiftType else {
            if value is NullValue { // TO DO: kludgy
                throw NullCoercionError(value: value, coercion: self)
            }
            throw UnsupportedCoercionError(value: value, coercion: self)
        }
        return result
    }
}


public struct AsLiteralName: SwiftCoercion { // TO DO: as above, this currently won't work as Command.[swift]eval() intercepts and performs handler lookup, only applying this coercion to handler's result; moving Command evaluation down to toTYPE() should fix this
    
    public let name: Symbol = "name" // TO DO: what to call this? "literal_name"? "identifier"?
    
    public typealias SwiftType = Symbol
    
    public func unbox(value: Value, in env: Scope) throws -> SwiftType {
        guard let result = value.asIdentifier() else { throw BadSyntax.missingName }
        return result
    }
}


public let asLiteralName = AsLiteralName()



    
public struct AsSwiftPrecis<T: SwiftCoercion>: SwiftCoercion { // allows a complex coercion’s true technical name to be replaced with a simple, custom name; e.g. used to rename `optional value` to `anything`, or `list {of: integer from: 0 to: 100, min: 4, max: 4}` to `CMYK_color`
    
    public var swiftLiteralDescription: String {
        return "\(type(of: self))(\(self.coercion.swiftLiteralDescription), \(self.precis.debugDescription))"
    }
    
    public var name: Symbol { return Symbol(self.precis) } // TO DO: what should this be?
    
    public var description: String { return "«type: \(self.precis)»" } // TO DO: what should this be?
    
    public typealias SwiftType = T.SwiftType
    
    private let coercion: T
    
    private let precis: String
    
    public init(_ coercion: T, _ precis: String) { // precis is the custom name under which the wrapped coercion appears; TO DO: this does not currently check that precis string is a valid command/slot name; should it do so and apply escape syntax if not?
        self.coercion = coercion
        self.precis = precis
    }
    
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        return try self.coercion.coerce(value: value, in: scope)
    }
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        return try self.coercion.unbox(value: value, in: scope)
    }
    public func box(value: SwiftType, in scope: Scope) -> Value {
        return self.coercion.box(value: value, in: scope)
    }
}

