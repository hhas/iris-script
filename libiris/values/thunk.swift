//
//  thunk.swift
//  libiris
//

import Foundation


// SelfEvaluatingValue?

public struct Thunk<ElementType: SwiftCoercion>: Value {
    
    typealias SwiftType = Value
    
    public var description: String { return "«thunk: \(self.value) as \(self.coercion)»" }
    
    public static var nominalType: NativeCoercion { return asAnything.nativeCoercion } // TO DO: return AsThunk wrapper?
        
    private let value: Value
    private let scope: Scope
    private let coercion: ElementType
    
    public init(value: Value, in scope: Scope, as coercion: ElementType) {
        self.value = value
        self.scope = scope
        self.coercion = coercion
    }
}
