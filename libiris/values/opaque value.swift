//
//  opaque value.swift
//  iris-glue
//
//  encapsulates a Swift value allowing it to pass through native object system; primitive libraries should use this to exchange internal data via native Environments (which are effectively “per-interpreter”) rather than via global Swift variables (which are shared across entire host process)
//
//  TO DO: should Environment define a separate namespace for primitive libraries’ private storage? currently private names are distinguished by ad-hoc `.` prefix only (hard to use natively, but not impossible); either way, opaque values should use full UTIs as keys, e.g. "com.example.mylib.myvalue" to avoid any collisions between unrelated libraries

import Foundation


open class OpaqueValue<SwiftType>: BoxedSwiftValue {
    
    // TO DO: static var can't be overridden in subclass
    public static var nominalType: NativeCoercion { return asValue.nativeCoercion } // TO DO: what should this return? (there’s no standard asOpaqueValue coercion as OpaqueValue<SwiftType> is a generic; thus any coercions are custom-defined as needed as AsComplex<SwiftType>; however, we could define a native-only Coercion for purposes of self-description: since the value’s content is already opaque to the native runtime there’s no need to distinguish any further)
    
    open var description: String { return "«opaque_value»" }
    
    public var data: SwiftType // data is directly accessed from Swift code // TO DO: make this read-only, requiring a class instance to adapt it for read-write? or define separate OpaqueReadOnlyValue and OpaqueReadWriteValue?
    
    required public init(_ data: SwiftType) {
        self.data = data
    }
    
    // TO DO: not sure how the following should behave, or if there should be any attempt to support primitive box/unbox of wrapped data? (boxing/unboxing via coercions is only really useful for read-only values or class instances, and no good for sharing mutable instances of Swift’s collection types, which due to their pass-by-value-like semantics must remain in the box at all times)
    
    public var immutableValue: Value { return self }
}


// shim needed by e.g. `returning` command to avoid infinite recursion upon evaling (current [kludgy] eval behavior for a Command is to invoke it then coerce the result, but since command returns itself that gets re-evaled… etc); TO DO: need to give more thought to this (e.g. capture command as expression, which is effectively thunk? how else can commands self-describe as first-class values?); for now, the captured Command remains permanently boxed

public class BoxedCommand: OpaqueValue<Command> {
    
    open override var description: String { return self.data.description }

}
