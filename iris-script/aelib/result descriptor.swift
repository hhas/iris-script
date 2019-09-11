//
//  result descriptor.swift
//
//  wraps Descriptor returned by AppData.sendAppleEvent(…) as Value, allowing unpacking to be driven by Coercion
//
//  (this is not intended for use as a general-purpose AEDesc value as `toValue` unpacks to a native Value rather than returning as-is)

//  TO DO: how to pass coercion info as a parameter to all AEs? (also need ability to describe composite types [something current AE/AEOM doesn't do], including Variant [c.f. HTTP content negotiation])

import Foundation
import AppleEvents
import SwiftAutomation

// TO DO: can/should SelfPacking/SelfUnpacking be reimplemented as Codable


func unpackDescriptor(_ desc: Descriptor, in scope: Scope = nullScope, as coercion: Coercion = asAnything, appData: NativeAppData) throws -> Value {
    return try coercion.coerce(value: NativeResultDescriptor(desc, appData: appData), in: scope)
}

struct NativeResultDescriptor: Value, SelfPacking, SelfUnpacking {
    
    static func SwiftAutomation_unpackSelf(_ desc: Descriptor, appData: AppData) throws -> NativeResultDescriptor {
        return NativeResultDescriptor(desc, appData: appData as! NativeAppData) // TO DO: where could appData be non-native? need to convert to native (alternatively, how much functionality does NativeAppData really add? might it be better to use AppData directly, with any native-specific methods provided as extensions on that?)
    }
    
    static func SwiftAutomation_noValue() throws -> NativeResultDescriptor {
        return NativeResultDescriptor(nullDescriptor, appData: nullAppData)
    }
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        return self.desc
    }
    
    
    var description: String { return "«\(self.desc)»" }
    
    static var nominalType: Coercion { return asAnything } // TO DO: asDescriptor
    
    private let desc: Descriptor
    private let appData: NativeAppData
    
    init(_ desc: Descriptor, appData: NativeAppData) {
        self.desc = desc
        self.appData = appData
    }
    
    /*
     
     func toTYPE<T>(in scope: Scope, as coercion: Coercion) throws -> T
     
     func toValue(in scope: Scope, as coercion: Coercion) throws -> Value // any value except `nothing`
     func toScalar(in scope: Scope, as coercion: Coercion) throws -> ScalarValue // text/number/date/URL
     func toNumber(in scope: Scope, as coercion: Coercion) throws -> Number
     
     func toBool(in scope: Scope, as coercion: Coercion) throws -> Bool
     func toInt(in scope: Scope, as coercion: Coercion) throws -> Int
     func toDouble(in scope: Scope, as coercion: Coercion) throws -> Double
     func toString(in scope: Scope, as coercion: Coercion) throws -> String
     
     // Q. implement toArray in terms of iterator (or possibly even `toIterator`?)
     func toList(in scope: Scope, as coercion: CollectionCoercion) throws -> OrderedList
     func toArray<T: SwiftCollectionCoercion>(in scope: Scope, as coercion: T) throws -> [T.ElementCoercion.SwiftType]
     
     //func toEditable(in scope: Scope, as coercion: AsEditable) throws -> EditableValue
     
     func toRawRecord(in scope: Scope, as coercion: RecordCoercion) throws -> Record
     
    */
    // TO DO: toSymbol?
    
    // unpack atomic types
    
    func toBool(in env: Scope, as coercion: Coercion) throws -> Bool {
        // TO DO: rework this (should it follow AE coercion rules or native? e.g. 0 = true or false?)
        guard let result = try? unpackAsBool(self.desc) else { throw UnsupportedCoercionError(value: self, coercion: asBool) }
        return result
    }
        
    func toScalar(in scope: Scope, as coercion: Coercion) throws -> ScalarValue {
        switch self.desc.type {
        // common AE types
        case typeSInt32, typeSInt16, typeUInt16, typeSInt64, typeUInt64, typeUInt32:
            return try unpackAsInt(self.desc)
        // TO DO: other integer types
        case typeIEEE64BitFloatingPoint, typeIEEE32BitFloatingPoint, type128BitFloatingPoint: // 128-bit will be coerced down (lossy)
            guard let result = try? unpackAsDouble(self.desc) else {
                throw UnsupportedCoercionError(value: self, coercion: coercion) // message: "Can't coerce 128-bit float to double."
            }
            return result
        case typeChar, typeIntlText, typeUTF8Text, typeUTF16ExternalRepresentation, typeStyledText, typeUnicodeText, typeVersion:
            guard let result = try? unpackAsString(self.desc) else {
                throw InternalError(description: "Corrupt descriptor: \(self.desc)")
            }
            return Text(result)
        default:
            guard let result = try? unpackAsString(self.desc) else {
                throw UnsupportedCoercionError(value: self, coercion: coercion)
            }
            return Text(result)
        }
    }
    
    // unpack collections
    
    func toList(in env: Scope, as coercion: AsList) throws -> OrderedList {
        do {
            if let desc = self.desc as? ListDescriptor {
                var result = [Value]()
                for itemDesc in desc {
                    let item = NativeResultDescriptor(itemDesc, appData: self.appData)
                    do {
                        result.append(try coercion.item.coerce(value: item, in: env))
                    } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
                        throw UnsupportedCoercionError(value: item, coercion: coercion.item).from(error)
                    }
                }
                return OrderedList(result)
            } else {
                return OrderedList([try coercion.item.coerce(value: self, in: env)])
            }
        } catch {
            throw UnsupportedCoercionError(value: self, coercion: coercion).from(error)
        }
    }
    
    func toArray<T: SwiftCollectionCoercion>(in scope: Scope, as coercion: T) throws -> [T.ElementCoercion.SwiftType] {
        do {
            if let desc = self.desc as? ListDescriptor {
                var result = [T.ElementCoercion.SwiftType]()
                for itemDesc in desc {
                    let item = NativeResultDescriptor(itemDesc, appData: self.appData)
                    do {
                        result.append(try coercion.swiftItem.unbox(value: item, in: env))
                    } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
                        throw UnsupportedCoercionError(value: item, coercion: coercion.item).from(error)
                    }
                }
                return result
            } else {
                return [try coercion.swiftItem.unbox(value: self, in: env)]
            }
        } catch {
            throw UnsupportedCoercionError(value: self, coercion: coercion).from(error)
        }
    }
    
    private let classKey = Symbol("class")
    
    func toRawRecord(env: Scope, coercion: AsRecord) throws -> Record {
        guard let recordDesc = self.desc as? RecordDescriptor else { // TO DO: need to implement ScalarDescriptor.toRecord() and call that here; for now, record descs with descriptorType other than typeAERecord will not unpack correctly
            return try Record([(nullSymbol, self)])
        }
        var fields = Record.Fields()
        if self.desc.type != typeAERecord {
            fields.append((classKey, self.appData.symbol(for: self.desc.type)))
        }
        for (key, descriptor) in recordDesc {
            if key == 0x6C697374 { // keyASUserRecordFields contains AEList of form [key1,value1,key2,value2,…]
                throw NotYetImplementedError() // TO DO: how to distinguish user-defined names from SDEF-defined names?
            } else {
                fields.append((self.appData.symbol(for: key), NativeResultDescriptor(descriptor, appData: self.appData)))
            }
        }
        return try Record(fields)
    }
    
    // unpack as anything
    
    func toValue(in scope: Scope, as coercion: Coercion) throws -> Value { // quick-n-dirty implementation
        switch self.desc.type {
        case typeBoolean, typeTrue, typeFalse:
            return try self.toBool(in: env, as: coercion)
        case typeSInt32, typeSInt16, typeIEEE64BitFloatingPoint, typeIEEE32BitFloatingPoint, type128BitFloatingPoint,
             typeSInt64, typeUInt64, typeUInt32, typeUInt16,
             typeChar, typeIntlText, typeUTF8Text, typeUTF16ExternalRepresentation, typeStyledText, typeUnicodeText, typeVersion:
            return try self.toScalar(in: env, as: coercion)
        case typeAEList:
            return try self.toList(in: env, as: asList)
        case typeAERecord:
            return try self.toRawRecord(in: env, as: asRecord)
        case typeType where (try? unpackAsType(self.desc)) == 0x6D736E67: // cMissingValue
            return nullValue
        case typeType, typeProperty, typeKeyword, typeEnumerated:
            let code = try! unpackAsFourCharCode(self.desc)
            return self.appData.symbol(for: code)
        case typeObjectSpecifier:
            //print("unpack", desc)
            return Reference(appData: self.appData, desc: self.desc as! SpecifierDescriptor)
        case typeQDPoint, typeQDRectangle, typeRGBColor:
            return OrderedList(try self.appData.unpack(desc) as [Int])
        default:
            //if self.desc.isRecord { return try self.toRawRecord(in: env, as: asRecord) }
            return self
        }
    }
}

extension Number: SelfPacking {
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        switch self {
        case .integer(let n, radix: _): return packAsInt(n)
        case .floatingPoint(let n): return packAsDouble(n)
        default: throw InternalError(description: "Can't pack Number: \(self)")
        }
    }
}

extension Text: SelfPacking {
    
    public func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        return packAsString(self.data)
    }
}

extension Symbol: SelfPacking {
    
    public func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        // TO DO: check that glue table keys are normalized
        if let desc = (appData as! NativeAppData).descriptor(for: self) {
            return desc
        } else if self.key.hasPrefix("0x") && self.key.count == 10, let code = UInt32(self.key.dropFirst(2), radix: 16) {
            return packAsType(code)
        } else {
            throw UnsupportedCoercionError(value: self, coercion: asValue) // TO DO: what error?
        }
    }
}

extension OrderedList: SelfPacking {
    
    public func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        return try packAsArray(self.data, using: appData.pack)
    }
}

extension Record: SelfPacking {
    
    public func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor { // TO DO: this is a mess
        return try packAsRecord(self.fields.map{ (label: Symbol, value: Value) throws -> (AEKeyword, Value) in
            guard let desc = (appData as! NativeAppData).descriptor(for: label) else {
                throw UnsupportedCoercionError(value: self, coercion: asValue) // TO DO: what error?
            }
            return (try unpackAsFourCharCode(desc), value)
        }, using: appData.pack)
    }
}
