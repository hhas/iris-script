//
//  types.swift
//  sclib
//

import Foundation
import iris

typealias Action = Value
typealias Actions = Block


public extension Environment {
    
    func getVariable(_ name: String) throws -> VariableName {
        let name = Symbol(name)
        if let value = self.get(name) {
            if let variable = value as? VariableName { return variable }
            throw TypeCoercionError(value: value, coercion: asLiteralName)
        } else {
            throw UnknownNameError(name: name, in: self)
        }
    }
        
    func setVariable(_ name: String, isActionOutput: Bool) throws -> VariableName {
        let name = Symbol(name)
        let variable = VariableName(name: name, isActionOutput: isActionOutput)
        try self.set(name, to: variable)
        return variable
    }
}



/*
 <key>WFWorkflowActionIdentifier</key>
 <string>is.workflow.actions.getvariable</string>
 <key>WFWorkflowActionParameters</key>
 <dict>
     <key>WFVariable</key>
     <dict>
         <key>WFSerializationType</key>
         <string>WFTextTokenAttachment</string>
         <key>Value</key>
         <dict>
             <key>OutputName</key>
             <string>URLs</string>
             <key>OutputUUID</key>
             <string>AFE9CEB0-DE6F-4E8B-833E-BC808C619A14</string>
             <key>Type</key>
             <string>ActionOutput</string>
         </dict>
     </dict>
 </dict>
 
 <dict>
     <key>WFWorkflowActionIdentifier</key>
     <string>is.workflow.actions.setvariable</string>
     <key>WFWorkflowActionParameters</key>
     <dict>
         <key>WFVariableName</key>
         <string>URL</string>
         <key>WFVariable</key>
         <dict>
             <key>WFSerializationType</key>
             <string>WFTextTokenAttachment</string>
             <key>Value</key>
             <dict>
                 <key>VariableName</key>
                 <string>link</string>
                 <key>VariableUUID</key>
                 <string>BFAEFFBC-F3EC-4D06-9EEE-F4BE4C863EBB</string>
                 <key>Type</key>
                 <string>Variable</string>
             </dict>
         </dict>
     </dict>
 </dict>
 */


public struct VariableName: Value {

    public static var nominalType: NativeCoercion = asLiteralName.nativeCoercion
    
    public var description: String { return "‘\(self.name.label)’" }
    
    public let name: Symbol
    public let uuid = UUID()
    public let isActionOutput: Bool
    
    public func export() -> Dict {
        if self.isActionOutput {
            return ["OutputName": self.name.label, "OutputUUID": self.uuid, "Type": "ActionOutput"]
        } else {
            return ["OutputName": self.name.label, "Type": "Variable"]
        }
    }
}


struct SetOutputValue: Value { // `set NAME to ACTION` should attach name’s UUID to action when output as plist
    
    static var nominalType: NativeCoercion = asCommand.nativeCoercion
    
    var description: String { return "\(self.name)" }
    
    private let name: VariableName
    private let expression: Value
    
    public func export() -> Dict {
        return ["": self.name.export()] // TO DO
    }
    
}
