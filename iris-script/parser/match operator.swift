//
//  match operator.swift
//  iris-script
//

import Foundation



// need a way to reify a pattern up to first operatorName

// TO DO: conjunctions should trigger reduction (what if conjunction is also non-conjunction)

func match(operatorGroup: OperatorGroup, to stack: Parser.Stack) -> (backMatches: [PatternMatcher], newMatches: [PatternMatcher]) {
    
    var backMatches = [PatternMatcher]()
    var newMatches = [PatternMatcher]()
    
    // TO DO: should this be moved to shift()? (it would mean shift's 2nd parameter becomes [OpDef] instead of [PatternMatcher])
    //print("FOUND operator ‘\(operatorGroup.name.label)’")
    for definition in operatorGroup.definitions {
        // TO DO: we need to distinguish conjunctions from leading keyword; we start new match on leading keyword; we trigger reduceNow on conjunctions (since the expr is between two keywords, it must be complete [with caveat that some keywords are both leading and conjunction, e.g. `repeat` <-> `while`]) but only back to the preceding keyword
        // note: the below code effectively ignores p
        // TO DO: is there any situation where neither first nor second pattern is a keyword?
        //print("back-matching:", definition)
        // temporary kludge
        for pattern in definition.pattern.reify() {
            //print("--matching ", pattern)
            // check if 1st pattern matches this operator name (i.e. atom/prefix operator)
            if case .keyword(let k) = pattern[0], k.matches(operatorGroup.name) { // prefix operator
                let newMatch = PatternMatcher(for: definition)
                print("  adding matcher for ‘\(operatorGroup.name.label)’:", newMatch)
                newMatches.append(newMatch)
                // print("matched prefix op", newMatch)
            } else if case .expression = pattern[0] { // leading EXPR implies an infix/postfix operator
                //print("backmatching…")
                // now check if 2nd pattern matches this operator name
                for pattern in [Pattern](pattern.dropFirst()).reify() {
                    if let next = pattern.first, case .keyword(let k) = next, k.matches(operatorGroup.name) {
                        if let last = stack.last {
                            // print("checking last", last.reduction)
                            if case .value(_) = last.reduction { // TO DO: this needs work as .value is not the only valid Reduction: stack's head can also be an unreduced command or LP argument, but we don't know if we should reduce that command now or later (we have to finish matching the operator in order to know the operator's precedence, at which point we can determine which to reduce first: command (into an operand) or operator (into an argument)); Q. do we actually need to know if EXPR is a valid expression to proceed with the match? if it looks like it *could* be reduced later on (i.e. it's not a linebreak or punctuation), that might be enough to proceed with match for now
                                let newMatch = PatternMatcher(for: definition)
                                print("  adding matcher for ‘\(operatorGroup.name.label)’:", newMatch)
                                backMatches.append(newMatch)
                                //stack[stack.count-1].matches.append(newMatch) // add matcher to head of stack, before operator name is shifted onto it
                                // shift() will carry this forward from head of stack
                                //print("matched infix/postfix op", newMatch)
                            }
                        }
                    }
                }
            }
        }
    }
    return (backMatches, newMatches)
}

