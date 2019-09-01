//
//  optional coercions.swift
//  iris-lang
//

import Foundation


// TO DO: need to decide naming convention

// TO DO: AsNullIntersection (empty set) that always throws on coerce/unbox

// TO DO: AsPrecis, AsVariant


struct AsNothing: Coercion { // used in HandlerInterface.result to return `nothing`
    
    let name: Symbol = "nothing"
    
    var swiftTypeDescription: String { return "" }
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        let _ = try asAnything.coerce(value: value, in: scope) // this still needs to evaluate value asAnything, discarding result (if value is scalar, it can be discarded immediately) // Q. how necessary is this? (i.e. we want to make sure last expr in handler evaluates, which could get funky when intersecting AsNothing with other coercions)
        return nullValue
    }
}

//

struct AsOptional: SwiftCoercion { // this returns native Value; for Optional<Value> use MayBeNil
    
    var swiftLiteralDescription: String { return "\(type(of: self))(\(self.coercion.swiftLiteralDescription))" }
    
    let name: Symbol = "optional"
    
    var description: String { return self.coercion.name == "value" ? "anything" : "optional \(self.coercion)" } // kludge
    
    typealias SwiftType = Value
    
    let coercion: Coercion
    
    init(_ coercion: Coercion) {
        self.coercion = coercion
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        do {
            return try self.coercion.coerce(value: value, in: scope)
        } catch is NullCoercionError {
            return nullValue
        }
    }
}

struct AsSwiftOptional<T: SwiftCoercion>: SwiftCoercion {
    
    var swiftLiteralDescription: String { return "\(type(of: self))(\(self.coercion.swiftLiteralDescription))" }

    let name: Symbol = "optional"
    
    var description: String { return "\(self.coercion) or nothing" }
    
    typealias SwiftType = T.SwiftType?
    
    let coercion: T
    
    init(_ coercion: T) {
        self.coercion = coercion
    }
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        do {
            return try self.coercion.coerce(value: value, in: scope)
        } catch is NullCoercionError {
            return nullValue
        }
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        do {
            return try self.coercion.unbox(value: value, in: scope)
        } catch is NullCoercionError {
            return nil
        }
    }
    func box(value: SwiftType, in scope: Scope) -> Value {
        guard let value = value else { return nullValue }
        return self.coercion.box(value: value, in: scope)
    }
}

//

struct AsDefault: Coercion {
    
    var swiftLiteralDescription: String {
        return "\(type(of: self))(\(self.coercion.swiftLiteralDescription), defaultValue: \(self.defaultValue.swiftLiteralDescription))"
    }
    
    let name: Symbol = "default"
    
    var description: String { return "\(self.coercion) or \(self.defaultValue)" }
    
    let coercion: Coercion
    let defaultValue: Value
    
    init(_ coercion: Coercion = asValue, defaultValue: Value) { // TO DO: should coercion be defaultValue.nominalType/constrainedType?
        self.coercion = coercion
        self.defaultValue = defaultValue // TO DO: this should be member of coercion; how/where to check this? also need to consider how collections/exprs might be used here
    }
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        do {
            return try self.coercion.coerce(value: value, in: scope)
        } catch is NullCoercionError {
            return try self.coercion.coerce(value: self.defaultValue, in: scope)
        }
    }
    
    // TO DO: implement call() for creating new instances natively
}


struct AsSwiftDefault<T: SwiftCoercion>: SwiftCoercion {
    
    var swiftLiteralDescription: String {
        return "\(type(of: self))(\(self.coercion.swiftLiteralDescription), defaultValue: \(formatSwiftLiteral(self.defaultValue)))"
    }

    let name: Symbol = "default"
    
    var description: String { return "\(self.coercion) default: \(self.defaultValue)" }
    
    typealias SwiftType = T.SwiftType
    
    let coercion: T
    let defaultValue: SwiftType
    
    init(_ coercion: T, defaultValue: SwiftType) {
        self.coercion = coercion
        self.defaultValue = defaultValue // TO DO: this should be member of coercion; how/where to check this? also need to consider how collections/exprs might be used here
    }

    func coerce(value: Value, in scope: Scope) throws -> Value {
        do {
            return try self.coercion.coerce(value: value, in: scope)
        } catch is NullCoercionError {
            return self.coercion.box(value: self.defaultValue, in: scope) // TO DO: cache if memoizable
        } catch {
            print("Coercion error «\(self)»", type(of:error), error)
            throw error
        }
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        do {
            return try self.coercion.unbox(value: value, in: scope)
        } catch is NullCoercionError {
            return self.defaultValue
        } catch {
            print("Coercion error", self, error)
            throw error
        }
    }
    func box(value: SwiftType, in scope: Scope) -> Value {
        //guard let value = value else { return nullValue }
        return self.coercion.box(value: value, in: scope)
    }
}



let asNothing = AsNothing()

let asAnything = AsOptional(asValue) // TO DO: also define native constant as Precis(AsOptional(asValue), "anything")




struct AsEditable: SwiftCoercion {
    
    var swiftLiteralDescription: String { return "\(type(of: self))(\(self.coercion.swiftLiteralDescription))" }

    // experimental; in effect, environment binds a box containing the actual value, giving behavior similar to Swift's pass-by-reference semantics using structs
    
    let name: Symbol = "editable"
    
    var description: String { return "editable \(self.coercion)" }
    
    typealias SwiftType = EditableValue
    
    let coercion: Coercion // the type to which the EditableValue instance's content should be coerced when setting it
    
    init(_ coercion: Coercion = asAnything) {
        self.coercion = coercion
    }
    
    // seems a bit odd; goal here is really to wrap value in box; Q. when value is already editable, how do we avoid double-boxing? note that coercing a boxed value to a non-editable value needs to ask the value for an immutable representation of self
    
    // really need to think this through: AsEditable boxes the value; the resulting box is then bound in environment; getting the stored box retrieves it, evaling the boxed value updates the box's content to the resulting value and returns it (this is something to be aware of when passing the box between scopes)
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
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


let asEditable = AsEditable()




// nominal type checks

struct AsLiteral<T: Value>: SwiftCoercion {
    
    var swiftLiteralDescription: String { return "\(type(of: self))()" }

    var name: Symbol { return T.nominalType.name } // TO DO: what should this be?
    
    var description: String { return "\(self.name.label) \(T.nominalType)" } 
    
    // if the input Value is an instance of T, it is passed thru as-is without evaluation, otherwise an error is thrown // TO DO: Value.eval() will bypass this (another reason it needs to go away)
    
    typealias SwiftType = T
    
    func unbox(value: Value, in env: Scope) throws -> SwiftType {
        guard let result = value as? SwiftType else {
            if value is NullValue { // TO DO: kludgy
                throw NullCoercionError(value: value, coercion: self)
            }
            throw UnsupportedCoercionError(value: value, coercion: self)
        }
        return result
    }
}


struct AsLiteralName: SwiftCoercion { // TO DO: as above, this currently won't work as Command.[swift]eval() intercepts and performs handler lookup, only applying this coercion to handler's result; moving Command evaluation down to toTYPE() should fix this
    
    var name: Symbol = "name" // TO DO: what to call this? "literal_name"? "identifier"?
    
    typealias SwiftType = Symbol
    
    func unbox(value: Value, in env: Scope) throws -> SwiftType {
        guard let result = value.asIdentifier() else { throw BadSyntax.missingName }
        return result
    }
}


let asLiteralName = AsLiteralName()

