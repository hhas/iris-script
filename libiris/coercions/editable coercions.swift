//
//  editable coercions.swift
//  libiris
//

import Foundation


/*


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
     
     public func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
         print("AsEditable<\(self.coercion)>.unbox() received \(type(of: value)) value: \(value)")
         let result = try self.coercion.coerce(value, in: scope)
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

 */

public typealias AsEditable = TypeMap<EditableValue> // TO DO: how to implement?

public let asEditable = AsEditable("editable", "asEditable") // TO DO: needs to be parameterized, so define as struct
