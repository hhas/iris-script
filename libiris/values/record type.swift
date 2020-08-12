//
//  record type.swift
//  libiris
//

import Foundation



public struct RecordType: ComplexValue, StaticValue {
    
    public typealias Field = (label: Symbol, binding: Symbol, coercion: NativeCoercion)
    public typealias Fields = [Field]
    
    public static var nominalType: NativeCoercion = asRecordType.nativeCoercion
    
    public var swiftLiteralDescription: String { return self.literalValue.swiftLiteralDescription }
    public var literalDescription: String { return self.literalValue.literalDescription }
    public var description: String { return self.literalDescription }
    
    public let fields: Fields
    
    public init(_ fields: Fields) { // caution: this does not check that all fields have unique label/binding names
        self.fields = fields
    }
    
    private var literalValue: Record { // reconstructs the record literal passed to `record` coercion’s constructor
        return try! Record(self.fields.map{ (label: Symbol, binding: Symbol, coercion: NativeCoercion) in
            let binding = (binding == nullSymbol) ? label : binding
            let label = (label == nullSymbol || label == binding) ? nullSymbol : label
            let value = Command("as", [(nullSymbol, Command(binding)), (nullSymbol, coercion)])
            return (label, value)
        })
    }
}


public extension RecordType.Fields {
    
    var literalDescription: String {
        return "{\(self.map{ "\($0.label == $0.binding ? "" : "\($0.label.label): ")\($0.binding.label) as \($0.coercion.literalDescription)" }.joined(separator: ", "))}"
    }
}


public let anyRecordType = RecordType([]) // if no fields declared, record can have any fields of any type
