//
//  read action.swift
//  sclib
//

// quick-n-nasty WFActions.plist to iris-glue converter; eventually it should construct AST and pretty-print/serialize that, but for now it generates iris file directly using crude text templating, so syntax errors may occur

// caution: this does not check for unbalanced `«`/`»` or other problem characters in comments

import Foundation
import iris


// TO DO: how to handle bad action translations, e.g. "is.workflow.actions.conditional" has parameter record with duplicate labels, which is not valid iris code (simplest is to declare a set of action IDs to skip when auto-generating glues, leaving those problem cases to be manually defined)

// TO DO: "is.workflow.actions.file.getlink" has dodgy Input Types (empty array)

// TO DO: allow LP syntax for list of [metadata hash]tags? e.g. `#phone #number #call` -> `[#phone, #number, #call]`

// TO DO: check single-quoting rules are consistent throughout; see also NameReader, which is probably more restricted in what it accepts; would be best to whitelist using only the charactersets used by lexer to detect .letters/.digits/.underscore

let reservedNames: Set<String> = [ // used by iris operators
    "nothing",
    "true",
    "false",
    "do",
    "done",
    "π",
    "and",
    "or",
    "xor",
    "not",
    "but_not",
]


func hasBadLabels(_ params: [Dict]) -> Bool {
    // Labels are neater but are sometimes duplicated or missing; Keys should always be present and unique though
    var found = Set<String>()
    for p in params {
        guard let label = p["Label"] as? String, !found.contains(label) else { return true }
        found.insert(label)
    }
    return false
}

func formatParameter(_ p: Dict, _ useKeys: Bool) -> String {
    let label = useKeys ? camelToSnake(p["Key"] as! String) : wordsToSnake(p["Label"] as! String)
    let key = p["Key"] as! String // binding is original Key, to be used in generated .shortcut plist
    var t = paramType(p)
    if p["Hidden"] as? Bool ?? false { t = "hidden_parameter {\(t)}" }
    return "\(quotableName(label)): \(key) as \(t)"
}


func readAction(id: String, action: Dict) -> String? {
    guard var name = action["Name"] as? String else { return nil }
    name = wordsToSnake(name)
    if reservedNames.contains(name) { name = "_\(name)" }
    //print(id, name.debugDescription)
    var parameters = [String]()
    let input: String, output: String
    var resultDescription = ""
    if (action["InputPassthrough"] ?? action["SnappingPassthrough"]) as? Bool ?? false {
        input = "nothing"
        output = "input"
    } else {
        if let d = action["Input"] as? Dict {
            input = inputOutputType(d)
        } else {
            input = "nothing"
        }
        if let d = action["Output"] as? Dict {
            output = inputOutputType(d)
            resultDescription = d["OutputName"] as? String ?? ""
        } else {
            output = "nothing"
        }
    }
    if input != "nothing" { parameters.append("\n\t\t_ as \(input)") }
    if let s = action["DescriptionResult"] as? String, !s.isEmpty {
        resultDescription += resultDescription.isEmpty ? s : ": \(s)"
    }
    if let params = action["Parameters"] as? [Dict] {
        let useKeys = hasBadLabels(params)
        for p in params {
            let d = action["Description"] as? String ?? ""
            parameters.append("\n\t\t\(formatParameter(p, useKeys))\(d.isEmpty ? "" : " «\(d)»")")
        }
    }
    let description = (action["Description"] as? Dict ?? [:])["DescriptionSummary"] as? String ?? ""
    let note = (action["Description"] as? Dict ?? [:])["DescriptionNote"] as? String ?? ""
    var category = action["Category"] as? String ?? ""
    if let subcategory = action["Subcategory"] { category += "/\(subcategory)" }
    let tags = (action["ActionKeywords"] as? [String])?.map{ Symbol(wordsToSnake($0)).literalDescription } ?? []
    return """
    shortcut_action \(quotableName(name)) {\(description.isEmpty ? "" : " «\(description)»")\(parameters.joined(separator: ""))} returning \(output)\(resultDescription.isEmpty ? "" : " «\(resultDescription)»") requires {
    \t\(note.isEmpty ? "" : "«\(note)»\n\t")id: “\(id)”
    \tcategory: “\(category)”
    \ttags: [\(tags.joined(separator: ", "))]
    }\n\n
    """
}

