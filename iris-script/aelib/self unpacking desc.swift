//
//  descriptor value.swift
//
//  wraps Descriptor returned by AppData.sendAppleEvent(…) as Value, allowing unpacking to be driven by Coercion
//

//  TO DO: how to pass coercion info as a parameter to all AEs? (also need ability to describe composite types [something current AE/AEOM doesn't do], including Variant [c.f. HTTP content negotiation])

import Foundation
import AppleEvents
import SwiftAutomation

// TO DO: can/should SelfPacking/SelfUnpacking be reimplemented as Codable


struct NativeDescriptor: Value, SelfPacking, SelfUnpacking { // NativeResultDescriptor
    
    static func SwiftAutomation_unpackSelf(_ desc: Descriptor, appData: AppData) throws -> NativeDescriptor {
        return NativeDescriptor(desc, appData: appData as! NativeAppData) // TO DO: where could appData be non-native? need to convert to native (alternatively, how much functionality does NativeAppData really add? might it be better to use AppData directly, with any native-specific methods provided as extensions on that?)
    }
    
    static func SwiftAutomation_noValue() throws -> NativeDescriptor {
        return NativeDescriptor(nullDescriptor, appData: nullAppData)
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
     
     func toRecord(in scope: Scope, as coercion: RecordCoercion) throws -> Record
     
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
    
    /*
    func toTag(env: Scope, coercion: Coercion) throws -> Tag {
        let code: OSType
        switch self.desc.type {
        case typeType, typeProperty, typeKeyword, typeEnumerated:
            code = try! unpackAsFourCharCode(desc)
        default:
            throw UnsupportedCoercionError(value: self, coercion: coercion)
        }
        // TO DO: worth caching Tags?
        if let name = self.appData.glueTable.typesByCode[code] {
            return Tag(name) // e.g. `#document`
        } else {
            return Tag(code) // e.g. `#‘«docu»’`
        }
    }
    */
    // unpack collections
    
    func toList(in env: Scope, as coercion: AsList) throws -> OrderedList {
        do {
            if let desc = self.desc as? ListDescriptor {
                var result = [Value]()
                for itemDesc in desc {
                    let item = NativeDescriptor(itemDesc, appData: self.appData)
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
                    let item = NativeDescriptor(itemDesc, appData: self.appData)
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
    /*
    private let classKey = Symbol("class").recordKey
    
    func toRecord(env: Scope, coercion: AsRecord) throws -> Record {
        throw NotYetImplementedError()
        /*
        if !self.desc.isRecord { throw UnsupportedCoercionError(value: self, coercion: coercion) }
        var fields = Record.Storage()
        if self.desc.type != typeAERecord {
            fields[classKey] = try self.appData.unpack(Descriptor(typeCode: self.desc.type))
        }
        for i in 1...(try! self.desc.count()) {
            let key: Tag
            let (keyCode, valueDesc) = try self.desc.item(i) // NativeDescriptor will take ownership; TO DO: what about applying [simple] value type coercions here?
            // TO DO: better to hide this table behind API that returns Tag instances, as that allows caching (alternative is to create all Tag instances up-front, but that's probably overkill as most won't be used in any given script)
            if keyCode == 0x6C697374 { // keyASUserRecordFields
                fatalError("TODO") // TO DO: unpack user fields (an AEList of form `[string,any,string,any,…]`, where each string is a field name)
            } else {
                if let tagName = self.appData.glueTable.typesByCode[keyCode] {
                    key = Tag(tagName)
                } else { // TO DO: how to represent four-char-codes as tags? easiest to use `0x_HEXACODE`, though that's not the most readable; probably sufficient to use leading underscore or other character that isn't encountered in terminology keywords [caveat it has to be legal in at least a single-quoted identifier]
                    key = Tag(keyCode)
                }
                fields[key.recordKey] = try NativeDescriptor(valueDesc, appData: self.appData).nativeEval(env: env, coercion: coercion.valueType)
            }
        }
        return Record(fields)
     */
    }
    */
    
    
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
            return try self.toRecord(in: env, as: asRecord)
        case typeType where (try? unpackAsType(self.desc)) == 0x6D736E67: // cMissingValue
            return nullValue
        case typeType, typeProperty, typeKeyword, typeEnumerated:
            //return try self.toTag(in: env, as: coercion)
            fatalError()
        case typeObjectSpecifier:
            /*
            let specifier = try self.appData.unpack(desc) as AEItem
            if let multipleSpecifier = specifier as? AEItems {
                return MultipleReference(multipleSpecifier, attributeName: "", appData: self.appData) // TO DO: what should attributeName be? (since specifier is returned by app, we assume that property/element name ambiguity is not an issue; simplest is to use empty string and check for that before throwing an error in SingleReference.toMultipleReference())
            } else {
                return SingleReference(specifier, attributeName: "", appData: self.appData) // TO DO: ditto
            }*/
            fatalError()
        case typeQDPoint, typeQDRectangle, typeRGBColor:
            return OrderedList(try self.appData.unpack(desc) as [Int])
        default:
            //if self.desc.isRecord { return try self.toRecord(in: env, as: asRecord) }
            return self
        }
    }
}

/*
extension Bool: SelfPacking {

    func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        return packAsBool(self)
    }
}

extension Int: SelfPacking {
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        return packAsInt(self)
    }
}

extension Double: SelfPacking {
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        return packAsDouble(self)
    }
}
*/

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
        guard let desc = (appData as! NativeAppData).glueTable.typesByName[self.key] else {
            throw UnsupportedCoercionError(value: self, coercion: asValue) // TO DO: what error?
        }
        return desc
    }
}

extension OrderedList: SelfPacking {
    
    public func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        return try packAsArray(self.data, using: appData.pack)
    }
}
