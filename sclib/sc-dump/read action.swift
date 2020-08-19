//
//  read action.swift
//  sclib
//

import Foundation
import iris


// TO DO: how to handle bad action translations, e.g. "is.workflow.actions.conditional" has parameter record with duplicate labels, which is not valid iris code (simplest is to declare a set of action IDs to skip when auto-generating glues, leaving those problem cases to be manually defined)

// TO DO: allow LP syntax for list of [metadata hash]tags? e.g. `#phone #number #call` -> `[#phone, #number, #call]`

// TO DO: check single-quoting rules are consistent throughout; see also NameReader, which is probably more restricted in what it accepts; would be best to whitelist using only the charactersets used by lexer to detect .letters/.digits/.underscore
let firstCharSet = nameCharacters.subtracting(digitCharacters)


func formatParameter(_ p: Dict) -> String {
    var label = wordsToSnake(p["Label"] as? String ?? "")
    if let c = label.first {
        if !(firstCharSet ~= c && label.conforms(to: nameCharacters)) {
            label = "‘\(label)’"
        }
    }
    let key = p["Key"] as! String // binding is original Key, to be used in generated .shortcut plist
    return "\(label.isEmpty ? "" : "\(label): ")\(key) as \(paramType(p))"
}


func readAction(id: String, action: Dict) -> String? {
    guard let name = action["Name"] as? String else { return nil }
    //print(id, wordsToSnake(name).debugDescription)
    var parameters = [String]()
    let input: String, output: String
    var resultDescription = ""
    if (action["InputPassthrough"] ?? action["SnappingPassthrough"]) as? Bool ?? false {
        input = "nothing"
        output = "input"
    } else {
        if let d = action["Input"] as? Dict {
            input = ioType(d)
        } else {
            input = "nothing"
        }
        if let d = action["Output"] as? Dict {
            output = ioType(d)
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
        for p in params {
            let d = action["Description"] as? String ?? ""
            parameters.append("\n\t\t\(formatParameter(p))\(d.isEmpty ? "" : " «\(d)»")")
        }
    }
    let description = (action["Description"] as? Dict ?? [:])["DescriptionSummary"] as? String ?? ""
    let note = (action["Description"] as? Dict ?? [:])["DescriptionNote"] as? String ?? ""
    var category = action["Category"] as? String ?? ""
    if let subcategory = action["Subcategory"] { category += "/\(subcategory)" }
    let tags = (action["ActionKeywords"] as? [String])?.map{ Symbol(wordsToSnake($0)).literalDescription } ?? []
    return """
    shortcut_action \(wordsToSnake(name)) {\(description.isEmpty ? "" : " «\(description)»")\(parameters.joined(separator: ""))} returning \(output)\(resultDescription.isEmpty ? "" : " «\(resultDescription)»") requires {
    \t\(note.isEmpty ? "" : "«\(note)»\n\t")id: “\(id)”
    \tcategory: “\(category)”
    \ttags: [\(tags.joined(separator: ", "))]
    }\n\n
    """
}

