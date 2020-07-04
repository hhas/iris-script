//
//  operator definitions.swift
//  iris-script
//
//  encapsulates all operators that use a given name anywhere in their pattern; e.g. the group for #‘-’ currently encapsulates the prefix "negative" and infix "minus" operators (if YYYY-MM-DD date patterns are introduced then that would also be added to that group); used by OperatorRegistry and Token.Form.operatorName(…)

import Foundation



struct OperatorDefinitions: Sequence, CustomStringConvertible { // TO DO: define as class rather than struct? it would reduce no. of method calls needed to populate PartialMatch tree to one add() per OpGrp rather than one add() per OpDef
    
    var description: String {
        return "<\(self.name.label) \(self.definitions.map{String(describing: $0)}.joined(separator: " "))>"
    }
    
    private static var _groupID = 0
    
    let name: Symbol // .operatorName(_) needs the name of the operator keyword (canonical/conjunction/alias) as written in user's code for reporting purposes

    private(set) var definitions = [PatternDefinition]() // order is arbitrary
    
    init(name: Symbol) {
        self.name = name // this is the name under which the Operation is stored in registry (a single Operation may be stored under multiple names); the name itself it may be canonical name, alias, and/or conjunction for one or more operators; when the tokenizer matches that name, it outputs an .operatorName(OperatorDefinitions) token and it's up to parser to determine which definition it is (e.g. if it's a conjunction in an Operation that's already partially matched, or if it's the start of a new match, or both)
     }
    
    mutating func add(_ definition: PatternDefinition) {
        // TO DO: how to detect conflicting definitions? (could be tricky, plus it could impact bootstrap times)
        self.definitions.append(definition)
    }
    
    __consuming func makeIterator() -> IndexingIterator<[PatternDefinition]> {
        return self.definitions.makeIterator()
    }
    
    var isInfixPrecedenceLessThanCommand: Bool? { // returns true if operator is infix/postfix with precedence[s] lower than command’s (i.e. a lower-precedence), false if operator has no infix/postfix forms or precedence is higher than command’s, or nil if overloaded operators’ precedence is both less AND greater than command’s (i.e. user MUST add explicit parentheses to disambiguate as parser cannot decide for itself); caution: only call this on operators known to have infix forms otherwise an exception is raised
        let infixDefinitions = self.definitions.filter{ $0.hasLeftOperand }
        if infixDefinitions.isEmpty {
            fatalError("Operator \(self.name) has no infix definitions, so command precedence cannot be compared.") // this is an implementation error as the parser should not have called it without first confirming the operator has one or more infix forms
        }
        let (minPrecedence, maxPrecedence) = infixDefinitions.reduce(
            (Precedence.max, Precedence.min), { (Swift.min($0.0, $1.precedence), Swift.max($0.1, $1.precedence)) })
        if minPrecedence > commandPrecedence {
            return false
        } else if maxPrecedence < commandPrecedence {
            return true
        } else { // overloaded infix/postfix operator has precedences higher AND lower than command
            return nil
        }
    }
    
    var hasPrefixForms: Bool {
        return self.contains{ !$0.hasLeftOperand }
    }
    
    var hasInfixForms: Bool {
        return self.contains{ $0.hasLeftOperand }
    }
    
    
    var alwaysHasLeftOperand: Bool {
        return self.allSatisfy{ $0.hasLeftOperand }
    }
    
    var sometimesHasLeftOperand: Bool {
        return self.contains{ $0.hasLeftOperand } && self.contains{ !$0.hasLeftOperand }
    }
    
    var neverHasLeftOperand: Bool {
        return self.allSatisfy{ !$0.hasLeftOperand }
    }
    
    //
    
    static func newGroupID() -> Int {
        self._groupID += 1
        return self._groupID
    }
    
    func newMatches() -> [PatternMatch] { // returns one or more new pattern matchers for matching this operator
        let groupID = OperatorDefinitions.self.newGroupID()
        return self.flatMap{ $0.newMatches(groupID: groupID) }
    }
}



