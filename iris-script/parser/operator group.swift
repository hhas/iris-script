//
//  operator group.swift
//  iris-script
//
//  encapsulates all operators that use a given name anywhere in their pattern; e.g. the group for #‘-’ currently encapsulates the prefix "negative" and infix "minus" operators (if YYYY-MM-DD date patterns are introduced then that would also be added to that group); used by OperatorRegistry and Token.Form.operatorName(…)

import Foundation



struct OperatorGroup: CustomDebugStringConvertible { // TO DO: define as class rather than struct? it would reduce no. of method calls needed to populate PartialMatch tree to one add() per OpGrp rather than one add() per OpDef
    
    var debugDescription: String {
        return "<\(self.name.label) \(self.definitions.map{String(describing: $0)}.joined(separator: " "))>"
    }
    
    let name: Symbol // .operatorName(_) needs the name of the operator keyword (canonical/conjunction/alias) as written in user's code for reporting purposes

    private(set) var definitions = [OperatorDefinition]()
    
    init(name: Symbol) {
        self.name = name // this is the name under which the Operation is stored in registry (a single Operation may be stored under multiple names); the name itself it may be canonical name, alias, and/or conjunction for one or more operators; when the tokenizer matches that name, it outputs an .operatorName(OperatorDefinitions) token and it's up to parser to determine which definition it is (e.g. if it's a conjunction in an Operation that's already partially matched, or if it's the start of a new match, or both)
     }
    
    mutating func add(_ definition: OperatorDefinition) {
        // TO DO: how to detect conflicting definitions? (could be tricky, plus it could impact bootstrap times)
        self.definitions.append(definition)
    }
}



