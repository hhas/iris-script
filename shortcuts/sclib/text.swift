//
//  text.swift
//  sclib
//

import Foundation
import iris


public struct InterpolatedText: Value { // returned by `interpolate STRING` (Q. what about `&`?)
    
    public static var nominalType: NativeCoercion = asString.nativeCoercion
    
    public var description: String { return String(describing: self.string) }
    
    private let string: NSString
    private let variables: [(Int, VariableName)]
    
    private let tagPattern = try! NSRegularExpression(pattern: "««(.+?)»»", options: .caseInsensitive)
    
    public init(text: String, commandEnv: Scope) throws { // given text, look up var names (which should be VariableName) and compose
        let env = commandEnv as! Environment
        var start = 0
        var string = ""
        var variables = [(Int, VariableName)]()
        var err: Error?
        self.tagPattern.enumerateMatches(in: text, range: NSRange(location: 0, length: text.count)) {
            (match, flags, stop) in
            if let match = match {
                let name = (text as NSString).substring(with: match.range(at: 1))
                let m = match.range(at: 0)
                let s = (text as NSString).substring(with: NSRange(location: start, length: m.location - start))
                string += s
                do {
                    // guessing Shortcuts uses NSString internally, so use UTF16 indices as offsets
                    variables.append(((string as NSString).length, try env.getVariable(name)))
                } catch {
                    err = error
                    stop.pointee = true
                }
                string += "?"
                start = m.location + m.length
            }
        }
        if let error = err { throw error }
        string += (text as NSString).substring(from: start)
        self.string = string as NSString
        self.variables = variables
    }
    
    public func export() -> Dict {
        /*
         <dict>
             <key>string</key>
             <string>Total is  !</string>
             <key>attachmentsByRange</key>
             <dict>
                 <key>{9, 1}</key>
                 <dict>
                     <key>Type</key>
                     <string>ActionOutput</string>
                     <key>OutputUUID</key>
                     <string>374a8808-eace-4dbf-92fb-826b757d48a1</string>
                 </dict>
             </dict>
         </dict>
         */
        var attachments = Dict()
        for (index, variable) in self.variables { attachments["{\(index), 1}"] = variable.export() }
        return ["string": self.string, "attachmentsByRange": attachments]
    }
}



/*
        <dict>
            <key>WFWorkflowActionIdentifier</key>
            <string>is.workflow.actions.gettext</string>
            <key>WFWorkflowActionParameters</key>
            <dict>
                <key>WFTextActionText</key>
                <dict>
                    <key>WFSerializationType</key>
                    <string>WFTextTokenString</string>
                    <key>Value</key>
                    <dict>
                        <key>string</key>
                        <string>&#10;? ?</string>
                        <key>attachmentsByRange</key>
                        ...
                    </dict>
                </dict>
                <key>UUID</key>
                <string>24DEDAF1-E84F-49F1-A42B-E40C4F86D2DF</string>
            </dict>
        </dict>

                        <dict>
                             <key>{1, 1}</key>
                             <dict>
                                 <key>OutputName</key>
                                 <string>Name</string>
                                 <key>OutputUUID</key>
                                 <string>E888B44D-8F9B-402C-A098-A48E8B9D2A16</string>
                                 <key>Type</key>
                                 <string>ActionOutput</string>
                             </dict>
                             <key>{3, 1}</key>
                             <dict>
                                  <key>VariableName</key>
                                  <string>URL</string>
                                 <key>Type</key>
                                 <string>Variable</string>
                             </dict>
                        </dict>
*/
