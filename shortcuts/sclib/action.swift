//
//  types.swift
//  sclib
//

import Foundation
import iris

/*
 <dict>
     <key>WFWorkflowActionIdentifier</key>
     <string>is.workflow.actions.getvariable</string>
     <key>WFWorkflowActionParameters</key>
     <dict>
         <key>WFVariable</key>
         <dict>
             <key>Value</key>
             <dict>
                 <key>OutputName</key>
                 <string>URLs</string>
                 <key>OutputUUID</key>
                 <string>AFE9CEB0-DE6F-4E8B-833E-BC808C619A14</string>
                 <key>Type</key>
                 <string>ActionOutput</string>
             </dict>
             <key>WFSerializationType</key>
             <string>WFTextTokenAttachment</string>
         </dict>
     </dict>
 </dict>
 <dict>
     <key>WFWorkflowActionIdentifier</key>
     <string>is.workflow.actions.setvariable</string>
     <key>WFWorkflowActionParameters</key>
     <dict>
         <key>WFVariableName</key>
         <string>Link</string>
     </dict>
 </dict>
 */


public struct DefaultActionConstructor: Callable {
    
    public static var nominalType: NativeCoercion = asHandler.nativeCoercion
    
    public var description: String { return self.interface.description }
    
    public var name: Symbol { return self.interface.name }
    
    public let interface: HandlerType
    public let requirements: ShortcutActionRequirements
    
    public init(for interface: HandlerType, requires requirements: ShortcutActionRequirements) {
        self.interface = interface
        self.requirements = requirements
    }
    
    public func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        /*
         <dict>
             <key>WFWorkflowActionIdentifier</key>
             <string>is.workflow.actions.number</string>
             <key>WFWorkflowActionParameters</key>
             <dict>
                 <key>WFNumberActionNumber</key>
                 <integer>42</integer>
             </dict>
         </dict>
         */
        // experimental; TO DO: how should individual actions compose into completed workflow?
        print(">>>", command, self.interface.parameters)
        
        var result: Dict = ["WFWorkflowActionIdentifier":self.requirements.id]
        var parameters = Dict()
        var index = 0
        // TO DO: if direct arg is action, call it
        // this matches arguments but does not apply coercions (which should only be used to check compatibility, although they might be used to adapt action outputs for use as parameter inputs, or adapt literal values for use as action inputs)
        for param in self.interface.parameters {
            let arg = command.arguments.value(labeled: param.label, at: &index)
            if !(arg is NullValue) { parameters[param.binding.label] = arg }
        }
        // TO DO: add <key>UUID</key><string>0000-00-00-0000</string> to parameters as needed
        result["WFWorkflowActionParameters"] = parameters
        //print(self.name, result)
        (scope.get(workflowName) as! Workflow).add(action: result)
        return try coercion.coerce(nullValue, in: scope)
    }
}

extension Environment {

    public func define(action: DefaultActionConstructor) throws {
        try self.set(action.name, to: action)
    }
}

