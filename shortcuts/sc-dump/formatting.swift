//
//  support.swift
//  sclib
//

import Foundation
import iris


typealias Dict = [String:Any]



func wordsToSnake(_ s: String) -> String { // replace spaces with underscores; used to convert action names and param labels to native identifiers
    return s.lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "-", with: "_") // TO DO: what about single-quoting?
}



let prefixes = ["AV", "CL", "EK", "EN", "IN", "MK", "MP", "NS", "REM", "WF", "UI"]
let suffixes = ["ContentItem", "Parameter"]


func camelToSnake(_ s: String) -> String { // convert CamelCase to snake_case; used to convert input/output/param types to native identifiers
    if s.isEmpty { return s }
    if let t = stdTypes[s] { return t }
    var s = Substring(s)
    for t in prefixes {
        if s.hasPrefix(t) {
            s = s.dropFirst(t.count)
            break
        }
    }
    for t in suffixes {
        if s.hasSuffix(t) {
            s = s.dropLast(t.count)
            break
        }
    }
    var result = ""
    while !s.isEmpty {
        let c = s.removeFirst()
        if !result.isEmpty && CharacterSet.uppercaseLetters.contains(c),
            let d = s.first, CharacterSet.lowercaseLetters.contains(d) { // convert "Ab" to "_ab"
            result += "_\(c.lowercased())"
        } else {
            // TO DO: set flag to single-quote if needed (e.g. "is.workflow.actions.addnewreminder" has badly labeled '2:00 PM' field, and some tags contain non-identifier chars)
            result += c.lowercased()
        }
    }
    return result
}

// all type names from WFActions.plist
// caution: these are a subset of true types used as various modifiers may be applied

typealias TypeNames = [String: String]

var inputOutputTypes = TypeNames() // [WFOriginalName:snake_name]
var parameterTypes   = TypeNames()
var disallowedTypes  = TypeNames()


func writeTypeDefinitions(_ label: String, for typeNames: TypeNames.Values, to glue: FileHandle) {
    glue.write("\n«\(label)»\n")
    for t in Set<String>(typeNames).sorted() { glue.write("shortcut_type \((t))\n") }
}

func writeShortcutTypes(to glue: FileHandle) {
    writeTypeDefinitions("input/output types", for: inputOutputTypes.values, to: glue)
    writeTypeDefinitions("parameter types", for: parameterTypes.values, to: glue)
    writeTypeDefinitions("disallowed types", for: disallowedTypes.values, to: glue)
}


func formatType(_ s: String, cache: inout [String:String]) -> String {
    if let res = cache[s] { return res }
    let res = camelToSnake(s)
    cache[s] = res
    return res
}


func formatIOType(_ s: String) -> String {
    return formatType(s, cache: &inputOutputTypes)
}

func formatParameterType(_ s: String) -> String {
    return formatType(s, cache: &parameterTypes)
}

func formatDisallowedType(_ s: String) -> String {
    return formatType(s, cache: &disallowedTypes)
}


func inputOutputType(_ d: Dict) -> String {
    var result: String
    if let types = d["Types"] as? [String] {
        if types.isEmpty {
            /*
             <key>Input</key>
             <dict>
                 <key>Multiple</key>
                 <true/>
                 <key>ParameterKey</key>
                 <string>WFFile</string>
                 <key>Required</key>
                 <true/>
                 <key>Types</key>
                 <array/> // probably a bug in XML, but we need to put something in for generated code to be valid
             </dict>
             */
            result = "anything"
        } else {
            result = types.map(formatIOType).joined(separator: " OR ")
            if types.count > 1 { result = "(\(result))" }
        }
        if d["Multiple"] as? Bool ?? false { result = "ordered_list of: \(result)" }
    } else {
        result = "nothing"
    }
    return result
}

/*
 TO DO: how to map WFStepperParameter? (presumably always an integer; how is min/max determined?)

     <dict>
         <key>Class</key>
         <string>WFStepperParameter</string>
         <key>DefaultValue</key>
         <integer>2</integer>
         <key>Key</key>
         <string>WFNumberFormatDecimalPlaces</string>
         <key>MinimumValue</key>
         <integer>0</integer>
         <key>StepperDescription</key>
         <string>Decimal Places</string>
         <key>StepperNoun</key>
         <string>Decimal Place</string>
         <key>StepperPluralNoun</key>
         <string>Decimal Places</string>
     </dict>
 */

func paramType(_ p: Dict) -> String {
    var result = p["Class"] as! String
    switch result {
    case "WFNumberFieldParameter":
        result = p["AllowsDecimalNumbers"] as? Bool ?? false ? "number" : "integer"
    case "WFEnumerationParameter":
        result = "choice [\((p["Items"] as! [String]).map { "“\($0)”" }.joined(separator: ", "))]"
    default:
        result = formatParameterType(result)
    }
    if result == "string" {
        if !(p["Multiline"] as? Bool ?? false) {
            result = "single_line_string" // TO DO: how best to constrain string?
        }
    }
    if let dv = p["DefaultValue"] {
        result = "optional \(result) with_default \(formatValue(dv))"
    }
    if let types = p["DisallowedVariableTypes"] as? [String] {
        result = "\(result) but_not \(types.map(formatDisallowedType).joined(separator: " OR "))"
    }
    return result
}

//

let _NSBoolean = type(of: NSNumber(value: true)) // this assumes Cocoa always represents true/false as __NSCFBoolean
let _NSNumber = type(of: NSNumber(value: 1)) // this assumes Cocoa always represents all integer and FP numbers as __NSCFNumber


func formatValue(_ v: Any) -> String {
    // casting NSNumber to each of Bool/Int/Double lossily succeeds for all, so explicitly type check (alternative is to implement plist parser in Swift, although that’d really need some sort of schema to type-map intelligently; in particular, dicts should map to either [String:Any] or custom struct, depending on whether it's a collection or a set of fields; bear in mind that plist export is really a compatibility shim: the end goal should be to use native iris, whether hand-written or machine-generated)
    if type(of: v) == _NSBoolean {
        return String(describing: v as! Bool)
    } else if type(of: v) == _NSNumber {
        switch (v as! NSNumber).objCType.pointee as Int8 {
        case 98, 99, 67, 115, 83, 105, 73, 108, 113: // (b, c, C, s, S, i, I, l, q) anything that will fit into Int64
            return String(describing: v as! Int)
        default:
            return String(describing: v as! Double)
        }
    }
    switch v {
    case let s as String:       return Text(s).literalDescription
    case let d as Date:         return d.debugDescription // TO DO
    case let array as [Any]:    return "[\(array.map(formatValue).joined(separator: ", "))]"
    default: fatalError("TODO: formatValue \(type(of: v)): \(v)")
    }
}
