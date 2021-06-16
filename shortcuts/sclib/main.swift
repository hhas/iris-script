//
//  main.swift
//  sclib
//

import Foundation
import iris

/*
TO DO: most of the following actions are simply shims to allow a literal value to be inserted into pipeline:
 
Skipping ‘street_address’ action as its name conflicts with an existing type.
Skipping ‘date’ action as its name conflicts with an existing type.
Skipping ‘email_address’ action as its name conflicts with an existing type.
Skipping ‘home’ action as its name conflicts with an existing type.
Skipping ‘list’ action as its name conflicts with an existing type.
Skipping ‘location’ action as its name conflicts with an existing type.
Skipping ‘measurement’ action as its name conflicts with an existing type.
Skipping ‘number’ action as its name conflicts with an existing type.
Skipping ‘phone_number’ action as its name conflicts with an existing type.
Skipping ‘url’ action as its name conflicts with an existing type.
 
(Also ‘text’/`gettext` and possibly others which don’t conflict but should be special-cased.)
 
`shortcut_action` currently skips them because there are already coercions of the same [normalized] name, and sclib doesn’t allow handler overloading. However, we really want to move them to exclusions so that they don’t appear in actions glue at all; instead, their functionality should be implemented on the coercions of the same name. (I suspect these values are often assigned to magic variables, rather than passed directly as input, thus `set NAME to VALUE [as TYPE]` might be implemented as generating the action and inserting it into the pipeline, possibly followed by `nothing` action to clear its output. That gives us iris semantics, which is what we want to move toward, while still outputting usable Shortcuts code.)
 
 
 
 Most of these actions should be subsumed/merged with coercions e.g. an iris number, 5, should be automatically wrapped in "is.workflow.actions.number"/is.workflow.actions.text" action when it appears in pipeline context. For street_address, email_address, etc. where the input data is written as a string, use the coercion to construct the action, e.g. `“foo@example.org” as email_address` -> “is.workflow.actions.email” action with WFEmailAddressField:foo@example.org parameter; if no coercion specified then the input text is wrapped as “is.workflow.actions.gettext” action by default. Furthermore, this coercion can probably be applied automatically by the consuming action, so no need for user to cast the value.
 
 e.g. From Swift Shortcuts:
 
 struct BatteryLevelShortcut: Shortcut {
     @OutputVariable var batteryLevel: Variable

     var body: some Shortcut {
         ShortcutGroup {
             Comment("This Shortcut was generated in Swift.")
             BatteryLevel()
                 .savingOutput(to: $batteryLevel)
             If(batteryLevel < Number(20), then: {
                 SetLowPowerMode(true)
                 ShowResult("Your battery level is \(batteryLevel)%; you might want to charge soon.")
             }, else: {
                 ShowResult("Your battery level is \(batteryLevel)%; you're probably fine for now.")
             })
         }
     }
 }

 Our goal is to write:
 
 «This Shortcut was written in iris»
 set battery_level to get_battery_level
 if battery_level < 20 then do
     set_low_power_mode true
     show_result “Your battery level is ” & battery_level & “%; you might want to charge soon.”
 done else do
     show_result “Your battery level is ” & battery_level & “%; you're probably fine for now.”
 done
 
or possibly:

    show_result interpolate “Your battery level is ««battery_level»»%; you might want to charge soon.”

depending on how we perform string interpolation:
 
 <dict>
     <key>WFWorkflowActionIdentifier</key>
     <string>is.workflow.actions.showresult</string>
     <key>WFWorkflowActionParameters</key>
     <dict>
 
         <key>Text</key>
         <dict>
             <key>WFSerializationType</key>
             <string>WFTextTokenString</string>
             <key>Value</key>
             <dict>
                 <key>string</key>
                 <string>Total is !</string>
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
         </dict>
 
     </dict>
 </dict>
 
 shortcut_action show_result { «Shows the specified text in Siri or in an alert.»
         text: Text as optional string with_default “”} returning input requires {
     id: “is.workflow.actions.showresult”
     category: “Scripting/Notification”
     tags: [#text, #such_text, #very_speech, #much_words, #so_wow, #string, #display]
 }
 
(Bear in mind the end goal of sclib is not to generate Shortcuts plists, but to provde a transition path from .plist to .iris as the native [workflow/script] format. Iris is simpler and more capable than Shortcuts, and repackaging actions as native handlers should simplify their implementation and improve reusability, especially once an Action’s GUI form can be auto-generated from the handler’s interface and metadata.)
 
*/


// TO DO: define custom coercions for "is.workflow.action.number", ".gettext", ".list", ".url", etc; these should override types+actions defined in glue files (see: shortcut_type and shortcut_action) and are responsible for adding actions to workflow/coercing value to parameter


let args = CommandLine.arguments

if args.count != 2 {
    print("USAGE: sclib GLUEDIR")
    print(args)
    exit(1)
}


public extension IncrementalParser {
    
    func loadGlue(_ file: URL) throws {
        self.read(try String(contentsOf: file, encoding: .utf8))
        guard let script = self.ast() else {
            let errors = self.errors()
            if errors.isEmpty { throw InternalError(description: "Found syntax errors in glue.") }
            throw InternalError(description: "Found syntax errors in glue: \(errors)")
        }
        let _ = try script.eval(in: env, as: asAnything)
        self.clear()
    }
}

func newParser(for glueDir: URL) -> IncrementalParser {
    let parser = IncrementalParser(withStdLib: false)
    let env = parser.env
    stdlib_loadCoercions(into: env)
    stdlib_loadConstants(into: env)
    sclib_loadHandlers(into: env)
    sclib_loadCoercions(into: env)
    sclib_loadOperators(into: env.operatorRegistry)
    do {
        try parser.loadGlue(glueDir.appendingPathComponent("shortcut types.iris-glue"))
        try parser.loadGlue(glueDir.appendingPathComponent("shortcut actions subset.iris-glue"))
    } catch {
        print("Failed: \(error)")
    }
    // TO DO: write-lock base env and create a new subenv for each buildWorkflow()
    return parser
}


extension IncrementalParser {
    
    func read(workflow: String) {
        // TO DO: should we instantiate new parser?
        self.read(workflow)
        guard let script = parser.ast() else { print("Error:", parser.errors()); exit(5) }
        do {
            let scope = parser.env.subscope() as! Environment
            try scope.set(workflowName, to: Workflow())
            let result = try script.eval(in: scope, as: asAnything)
            print("Result:", result)
            print((scope.get(workflowName) as! Workflow).data["WFWorkflowActions"]!)
        } catch {
            print("Error:", error); exit(5)
        }
    }
}

// show_result takes string; this might be a string literal or interpolated string

let parser = newParser(for: URL(fileURLWithPath: args[1]))
// piping output where string param is expected should transform `random_number; show_result` to `random_number->store UUID, show_result interpolate "\(UUID)"` (Q. does interpolation work with non-string values, e.g. lists?)
parser.read(workflow: """
    random_number minimum: 1 maximum: 10; show_result
""")
