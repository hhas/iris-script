//
//  editable coercions.swift
//  libiris
//

// TO DO: there should be one model for mutability that covers both name bindings and value contents, where mutability is effectively a scope-based “permission” (this avoids Swift’s confusing “mutable let” behavior where an “immutable” `let` binding to a class instance does not stop that instance changing internally, which is surprising behavior to novices when they come to use that object again later on, especially since String, Array, Dictionary, etc values do behave as immutable when bound with `let`); e.g. if a list is bound to an immutable slot, the list’s elements are immutable; if a record is bound to a mutable slot, changes to the record’s fields should propagate as far as that record remains inside an editable container: thus, given `editable record` -> `editable record` -> `record` -> `editable record`, changes to the first instance are seen in the second, but not in third or fourth; note that scope-like objects are liable to break this rule - we can ask them to respect it and provide them the boundary notifications they need to enforce it internally, but we can't really enforce it (certainly not for third-party objects that are implemented in Swift, which can do anything that Swift allows them to do)

import Foundation


public struct AsEditable: NativeCoercion {
    
    public var swiftLiteralDescription: String { return "\(type(of: self))(\(self.elementType.swiftLiteralDescription))" }
    
    public var literalDescription: String { return "‘editable’ {\(literal(for: self.elementType))}" }
    
    public let name: Symbol = "editable"
    
    public typealias SwiftType = EditableValue
    
    public let elementType: NativeCoercion // the type to which the EditableValue instance's content should be coerced when setting it
    
    public init(_ elementType: NativeCoercion = defaultCoercion) {
        self.elementType = elementType
    }
    
    // seems a bit odd; goal here is really to wrap value in box; Q. when value is already editable, how do we avoid double-boxing? note that coercing a boxed value to a non-editable value needs to ask the value for an immutable representation of self
    
    // really need to think this through: AsEditable boxes the value; the resulting box is then bound in environment; getting the stored box retrieves it, evaling the boxed value updates the box's content to the resulting value and returns it (this is something to be aware of when passing the box between scopes)
    
    public func coerce(_ value: Value, in scope: Scope) throws -> Value {
        //print("AsEditable<\(self.elementType)>.coerce() received \(type(of: value)) value: \(value)")
        let result = try self.elementType.coerce(value, in: scope)
        // if value is already editable then update in-place
        if let editable = value as? EditableValue { // bit dicey (e.g. value could be an EditableValue, but wrapped in a Thunk [although thunks really shouldn't capture mutable values])
            editable.set(to: result)  // TO DO: this is wrong assumes that the original value's underlying type is same as self.coercion, which it may not be; e.g. `set foo to 3 as editable number, set bar to foo as editable list of string` is legal code, but is going to break #foo slot's value; not sure what best answer is - perhaps only share the box if both types are identical, else create a new box? (that's probably not ideal either, as the point of using runtime coercions is to allow flexibility when a value isn't of the exact [nominal] type required but can be coerced to that type)
            // safe behavior passing in would be outertype isa innertype, but passing out would be innertype isa outertype, thus any mismatch between types means a constraint error may occur (type errors are acceptable from a dynamic typing POV - where the goal is to detect and raise early and clearly, not to avoid completely - although would be flagged as warning/error when linting/baking); given that common usage pattern is to type handler interfaces and leave bound values untyped, the outertype will normally be `editable [anything]`, unless the assignment operation parameterizes `EditableValue` with the bound value's nominal/constrained type
            return editable
        } else {
            return EditableValue(result, as: self.elementType)
        }
    }
}

public let asEditable = AsEditable()



//public typealias AsEditable = TypeMap<EditableValue> // TO DO: how to implement?

//public let asEditable = AsEditable("editable", "asEditable") // TO DO: needs to be parameterized, so define as struct
