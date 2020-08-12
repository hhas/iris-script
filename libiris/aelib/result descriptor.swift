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




struct RemoteCall: Handler {
    
    // for AE commands, the command name (e.g. Symbol("get")) needs to be looked up in glue; Q. should glue return HandlerType, or dedicated data structure (in which case `interface` will be calculated var); note that HI provides no argument processing support,
    
    var interface: HandlerType { return self.appData.interfaceForCommand(term: self.term) }
    let term: CommandTerm
    let appData: NativeAppData
    
    // TO DO: also pass target (this packs as keyDirectObject or keySubjectAttr)
    
    let isStaticBindable = false // TO DO: need to decide policy for methods
    
    func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        //print("Calling", command)
        let directParameter: Any
        var keywordParameters = [KeywordParameter]()
        if command.arguments.isEmpty {
            directParameter = noParameter
        } else {
            if command.arguments[0].label == nullSymbol {
                directParameter = try asValue.coerce(command.arguments[0].value, in: scope)
                for argument in command.arguments.dropFirst() {
                    guard let param = self.term.parameter(for: argument.label.key) else {
                        throw InternalError(description: "Bad parameter")
                    }
                    keywordParameters.append((param.name, param.code, try asValue.coerce(argument.value, in: scope)))
                }
            } else {
                directParameter = noParameter
                for argument in command.arguments {
                    guard let param = self.term.parameter(for: argument.label.key) else {
                        throw InternalError(description: "Bad parameter")
                    }
                    keywordParameters.append((param.name, param.code, try asValue.coerce(argument.value, in: scope)))
                }
            }
        }
        // TO DO: parentSpecifier arg is annoyingly specific about type
        let parentSpecifier = Specifier(parentQuery: nil, appData: self.appData, descriptor: RootSpecifierDescriptor.app)
        let resultDesc = try self.appData.sendAppleEvent(name: self.term.name,
                                                         event: self.term.event,
                                                         parentSpecifier: parentSpecifier, // TO DO
            directParameter: directParameter, // the first (unnamed) parameter to the command method; see special-case packing logic below
            keywordParameters: keywordParameters) as NativeResultDescriptor
        return try coercion.coerce(resultDesc, in: scope)
    }
}


// TO DO: this is an awful awful KLUDGE that needs replaced once a coherent coercion/bridging architecture is found

public struct NativeResultDescriptor: Value, SelfPacking, SelfUnpacking, SelfEvaluatingValue {
    
    // AppData.sendAppleEvent(…) calls this, passing result as descriptor
    public static func SwiftAutomation_unpackSelf(_ desc: Descriptor, appData: AppData) throws -> NativeResultDescriptor {
        return NativeResultDescriptor(desc, appData: appData as! NativeAppData) // TO DO: where could appData be non-native? need to convert to native (alternatively, how much functionality does NativeAppData really add? might it be better to use AppData directly, with any native-specific methods provided as extensions on that?)
    }
    
    public static func SwiftAutomation_noValue() throws -> NativeResultDescriptor {
        return NativeResultDescriptor(nullDescriptor, appData: nullAppData)
    }
    
    public func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        return self.desc
    }
    
    
    public var description: String { return "«\(self.desc)»" }
    
    public static var nominalType: NativeCoercion { return asAnything.nativeCoercion } // TO DO: what type?
    
    public let desc: Descriptor
    private let appData: NativeAppData
    
    init(_ desc: Descriptor, appData: NativeAppData) {
        self.desc = desc
        self.appData = appData
    }
    
    // TO DO: how/where to unpack AEDescs (NativeResultDescriptor is a holdover from double-dispatch design; it should be possible to reduce it to opaque wrapper for unbridged AEDescs only, and perform the unpacking at end of AE dispatch; see `RemoteCall.call()`)
    
    public func eval<T: SwiftCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
        if self.desc.type == typeNull || (self.desc.type == typeType && self.desc.data == missingValueDescriptor.data) {
            return try coercion.coerce(nullValue, in: scope)
        }
        switch T.SwiftType.self {
        case is ScalarValue.Type:
            return try coercion.coerce(self.toScalar(in: scope, as: coercion.nativeCoercion), in: scope)
        case is Bool.Type:
            return try coercion.coerce(self.toBool(in: scope, as: coercion.nativeCoercion), in: scope)
        case is Symbol.Type:
            return try coercion.coerce(self.appData.unpack(self.desc), in: scope)
        default: ()
        }
        if T.SwiftType.self == Value.self {
            let v = try self.toValue(in: scope, as: coercion.nativeCoercion)
            if v is NativeResultDescriptor { return v as! T.SwiftType } // kludge, otherwise coerce() infinitely recurses when toValue returns wrapped descriptor as-is
            return try coercion.coerce(v, in: scope)
        }
        switch coercion {
        case let c as AsOrderedList:
            return try coercion.coerce(self.toList(in: scope, as: c), in: scope)
        case let c as AsRecord:
            return try coercion.coerce(self.toRawRecord(in: scope, as: c), in: scope)
        default: ()
        }
        throw TypeCoercionError(value: self, coercion: coercion)
    }
    
    // unpack atomic types
    
    private func toBool(in env: Scope, as coercion: NativeCoercion) throws -> Bool {
        // TO DO: rework this (should it follow AE coercion rules or native? e.g. 0 = true or false?)
        if let result = try? unpackAsBool(self.desc) { return result }
        throw TypeCoercionError(value: self, coercion: coercion)
    }
        
    private func toScalar(in scope: Scope, as coercion: NativeCoercion) throws -> ScalarValue {
        switch self.desc.type {
        // common AE types
        case typeSInt32, typeSInt16, typeUInt16, typeSInt64, typeUInt64, typeUInt32:
            return try unpackAsInt(self.desc)
        // TO DO: other integer types
        case typeIEEE64BitFloatingPoint, typeIEEE32BitFloatingPoint, type128BitFloatingPoint: // 128-bit will be coerced down (lossy)
            if let result = try? unpackAsDouble(self.desc) { return result }
        case typeChar, typeIntlText, typeUTF8Text, typeUTF16ExternalRepresentation, typeStyledText, typeUnicodeText, typeVersion:
            if let result = try? unpackAsString(self.desc) { return Text(result) }
        default:
            if let result = try? unpackAsString(self.desc) { return Text(result) }
        }
        throw TypeCoercionError(value: self, coercion: coercion)
    }
    
    // unpack collections
    
    private func toList(in env: Scope, as coercion: AsOrderedList) throws -> OrderedList {
        do {
            if let desc = self.desc as? ListDescriptor {
                var result = [Value]()
                for itemDesc in desc {
                    let item = NativeResultDescriptor(itemDesc, appData: self.appData)
                    do {
                        result.append(try coercion.elementType.coerce(item, in: env))
                    } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
                        throw TypeCoercionError(value: item, coercion: coercion.elementType).from(error)
                    }
                }
                return OrderedList(result)
            } else {
                return OrderedList([try coercion.elementType.coerce(self, in: env)])
            }
        } catch {
            throw TypeCoercionError(value: self, coercion: coercion).from(error)
        }
    }
    /*
    public func toArray<T: SwiftCollectionCoercion>(in scope: Scope, as coercion: T) throws -> [T.ElementCoercion.SwiftType] {
        do {
            if let desc = self.desc as? ListDescriptor {
                var result = [T.ElementCoercion.SwiftType]()
                for itemDesc in desc {
                    let item = NativeResultDescriptor(itemDesc, appData: self.appData)
                    do {
                        result.append(try coercion.swiftItem.coerce(item, in: scope))
                    } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
                        throw TypeCoercionError(value: item, coercion: coercion.elementType).from(error)
                    }
                }
                return result
            } else {
                return [try coercion.swiftItem.coerce(self, in: scope)]
            }
        } catch {
            throw TypeCoercionError(value: self, coercion: coercion).from(error)
        }
    }
    */
    private let classKey = Symbol("class")
    
    private func toRawRecord(in env: Scope, as coercion: AsRecord) throws -> Record {
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
    
    private func toValue(in scope: Scope, as coercion: NativeCoercion) throws -> Value { // quick-n-dirty implementation
        switch self.desc.type {
        case typeBoolean, typeTrue, typeFalse:
            return try self.toBool(in: scope, as: coercion)
        case typeSInt32, typeSInt16, typeIEEE64BitFloatingPoint, typeIEEE32BitFloatingPoint, type128BitFloatingPoint,
             typeSInt64, typeUInt64, typeUInt32, typeUInt16,
             typeChar, typeIntlText, typeUTF8Text, typeUTF16ExternalRepresentation, typeStyledText, typeUnicodeText, typeVersion:
            return try self.toScalar(in: scope, as: coercion)
        case typeAEList:
            return try self.toList(in: scope, as: asOrderedList)
        case typeAERecord:
            return try self.toRawRecord(in: scope, as: asRecord)
        case typeType where (try? unpackAsType(self.desc)) == 0x6D736E67: // cMissingValue
            return nullValue
        case typeType, typeProperty, typeKeyword, typeEnumerated:
            let code = try! unpackAsFourCharCode(self.desc)
            return self.appData.symbol(for: code)
        case typeObjectSpecifier:
            //print("unpack", desc)
            return Reference(appData: self.appData, desc: self.desc as! SpecifierDescriptor)
        // TO DO: typeInsertionLoc, comparison/logical test, range
        case typeQDPoint, typeQDRectangle, typeRGBColor:
            return OrderedList(try self.appData.unpack(desc) as [Int])
        default:
   //         if self.desc.isRecord { return try self.toRawRecord(in: scope, as: asRecord) }
            return self
        }
    }
}

extension Number: SelfPacking {
    
    public func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        switch self {
        case .integer(let n, radix: _): return packAsInt(n)
        case .floatingPoint(let n): return packAsDouble(n)
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
            throw TypeCoercionError(value: self, coercion: asSymbol) // TO DO: what error?
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
        return try packAsRecord(self.data.map{ (label: Symbol, value: Value) throws -> (AEKeyword, Value) in
            guard let desc = (appData as! NativeAppData).descriptor(for: label) else {
                throw TypeCoercionError(value: self, coercion: asRecord) // TO DO: what error?
            }
            return (try unpackAsFourCharCode(desc), value)
        }, using: appData.pack)
    }
}
