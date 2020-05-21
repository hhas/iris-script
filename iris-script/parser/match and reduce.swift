//
//  match and reduce.swift
//  iris-script
//

// WIP

import Foundation


// pulled this out of Parser for now; not sure if it should be there or on matcher


// TO DO: conjunctions should trigger reduction (what if conjunction is also non-conjunction)

func match(previousToken: Token.Form?, followedBy definitions: OperatorDefinitions) -> (backMatches: [PatternMatcher], newMatches: [PatternMatcher]) {
    
    var backMatches = [PatternMatcher]()
    var newMatches = [PatternMatcher]()
    
    // TO DO: should this be moved to shift()? (it would mean shift's 2nd parameter becomes [OpDef] instead of [PatternMatcher])
    //print("FOUND operator ‘\(definitions.name.label)’")
    for definition in definitions.definitions {
        // TO DO: we need to distinguish conjunctions from leading keyword; we start new match on leading keyword; we trigger reduceNow on conjunctions (since the expr is between two keywords, it must be complete [with caveat that some keywords are both leading and conjunction, e.g. `repeat` <-> `while`]) but only back to the preceding keyword
        // note: the below code effectively ignores p
        // TO DO: is there any situation where neither first nor second pattern is a keyword?
        //print("back-matching:", definition)
        // temporary kludge
        
        // TO DO: extract backmatching into subroutine so hardcoded .semicolon (pipe) pattern can use it as well
        
        for pattern in definition.pattern.reify() {
            //print("--matching ", pattern)
            // check if 1st pattern matches this operator name (i.e. atom/prefix operator)
            if case .keyword(let k) = pattern[0], k.matches(definitions.name) { // prefix operator
                let newMatch = PatternMatcher(for: definition)
                print("  adding matcher for ‘\(definitions.name.label)’:", newMatch)
                newMatches.append(newMatch)
                // print("matched prefix op", newMatch)
            } else if case .expression = pattern[0] { // leading EXPR implies an infix/postfix operator // TO DO: what if pattern matches LH operand as something other than .expression, e.g. `.test(F)`, .value(T)?
                //print("backmatching…")
                // now check if 2nd pattern matches this operator name
                for pattern in [Pattern](pattern.dropFirst()).reify() {
                    if let next = pattern.first, case .keyword(let k) = next, k.matches(definitions.name) {
                        // print("checking last", last.reduction)
                        if case .value(_) = previousToken { // TO DO: this needs work as .value is not the only valid Reduction: stack's head can also be an unreduced command or LP argument, but we don't know if we should reduce that command now or later (we have to finish matching the operator in order to know the operator's precedence, at which point we can determine which to reduce first: command (into an operand) or operator (into an argument)); Q. do we actually need to know if EXPR is a valid expression to proceed with the match? if it looks like it *could* be reduced later on (i.e. it's not a linebreak or punctuation), that might be enough to proceed with match for now
                            let newMatch = PatternMatcher(for: definition)
                            print("  adding matcher for ‘\(definitions.name.label)’:", newMatch)
                            backMatches.append(newMatch)
                            //print("matched infix/postfix op", newMatch)
                        }
                    }
                }
            }
        }
    }
    return (backMatches, newMatches)
}


extension Token.Form {
    
    var canBeLabel: Bool {
        switch self {
        case .operatorName(_), .quotedName(_), .unquotedName(_): return true
        default:                                                 return false
        }
    }
    
    var isName: Bool {
        switch self {
        case .quotedName(_), .unquotedName(_): return true
        default:                               return false
        }
    }
    
    func toName() -> Symbol {
        switch self {
        case .quotedName(let name), .unquotedName(let name): return Symbol(name)
        case .operatorName(let definitions):                 return definitions.name
        default:                                             return nullSymbol
        }
    }
}



// called by reduceNow() when a RH expr delimiter is found
func reduceOperators(parser: Parser) {
    let stack = parser.stack
    // TO DO: should stack track previous delimiter index, allowing us to know number of stack frames to be reduced (if 1, and it's .value, we know it's already fully reduced)

    // TO DO: when comparing precedence, look for .values in stack that have overlapping operator matches where one isBeginning and other isCompleted; whichever match has the higher definition.precedence (or if both are same definition and associate==.right) reduce that first
    
    guard let _ = stack.last else { return } // this'll only occur if a separator appears at start of script
    // print("reduceNow:", item)
    let end = stack.count
    var i = end
    var matchers = [(start: Int, end: Int, matcher: PatternMatcher)]() // `start...end`
    var commandComponents = [(start: Int, end: Int, name: Symbol, isLabel: Bool)]()
    // TO DO: can we extract commands here? ([un]quoted names, colons, (NAME EXPR) preceded by [what?]; running backwards arguably helps)
    print("back-scan…")
    loop: while i > 0 {
        i -= 1
        let (form, matches) = stack[i]
        let completedMatches = matches.filter{$0.isCompleted}
        for match in completedMatches {
            print(match.count, i, match)
            matchers.append((i - match.count + 1, i, match))
        }
        switch form {
        case .colon: // caution: this can detect false positives (e.g. in `tell foo returning bar: action`)
            if i > 0 && stack[i-1].reduction.canBeLabel {
                print("Found possible arg name: \(stack[i-1].reduction)")
                commandComponents.insert((i-1, i, stack[i-1].reduction.toName(), true), at: 0)
                i -= 1
            }
        case .unquotedName(let name), .quotedName(let name):
            print("Found command name: \(name)")
            commandComponents.insert((i, i, form.toName(), false), at: 0)
        case .separator(_), .lineBreak:
            i += 1
            break loop
        case .startList, .startRecord, .startGroup:
            i += 1
            break loop
        // TO DO: what about colon, semicolon?
        default: ()
        }
    }
    let start = i
    print("REDUCE NOW: \(start)...\(end-1)")
    for item in stack[start..<end] {
        print(" - ", item.reduction, item.matches.filter{$0.isCompleted})
    }
    
    // there is another problem with above: start and end indices of later matches will change as earlier matches are reduced
    
    // note: not all ops will be fully matched at this point as some operands (e.g. commands) are not yet reduced
    
    // a command is `NAME EXPR`
    // LP syntax allows `NAME [EXPR] [LABEL: EXPR …]`
    
    // `NAME NAME NAME …` is valid syntax, i.e. `NAME{NAME{NAME{…}}}`, although PP should insert braces to clarify
    
    // while we are scanning backwards, we treat any labels as belonging to outermost (LP) command
    // any reduced .value(_) preceded by NAME is a command; if the value is followed by infix/postfix OPNAME then precedence determines if value is argument and command is the operand or value is operand and operation is argument; most operators bind less tightly than argument (one notable exception is `of` and its associated reference forms) so, as a rule, `CMDNAME EXPR OPNAME` -> `OPNAME{CMDNAME{EXPR}}`
    
    // `NAME NAME NAME …` pattern can appear anywhere - at start of range (in which case it's command's name + direct argument) or after a label (in which case it's an argument to command); labels always associate with outermost command, however
    
    // commands are effectively prefix operators so precedence comparison is only needed for infix/postfix operators appearing *after* a command name/arg label; a prefix/infix operator name preceding command name will always reduce that particular command - the question is where that command's right-side terminates
    
    // there is an added wrinkle with precedence, e.g. `foo 1 + 2` -> `+{foo{1},2}` but `foo 1 + 2 bar: 3` is a syntax error
    
    // note that `foo 1 + a bar: 3` -> `+{foo{1},a{bar:3}}`; when scanning back from end, the labeled arg associates with `a`, not `foo`; the PP should probably transform this code to `(foo 1) + (a bar: 3)` or `foo {1} + a {bar:3}` to avoid any visual ambiguity
    
    print("found command parts:")
    print(commandComponents)
    print()
    
    print("found operations:")
    for m in matchers { print(" - \(m.start)...\(m.end) \(m.matcher.definition.name.label)") }
    matchers.sort{ $0.start < $1.start || $0.start == $1.start && $0.end < $1.end }
    
    print()
    for m in matchers { print(" - \(m.start)...\(m.end) \(m.matcher.definition.name.label)") }
    
    // TO DO: precedence
    
    //if let (_, end, match) = matchers.first { // test
   //     parser.reduce(completedMatch: match, endingAt: end+1)
   // }
    
    // TO REDUCE:
    // if matches[0].start != 0, ops haven't matched exactly
    
    // simple matching strategy, assuming range is 100% matched by single expression composed of 1 or more operations: start at first match in sorted array [of completed matches] (which should have start index 0) and get its end index, then advance until [longest] pattern whose start index == previous match's end index is found; repeat until end index == end of range (or no matches left, if not perfect match)
    
    // the problem remains: unreduced operands prevent all patterns initially matching; thus there will be gaps between completed matches (e.g. `1 - -2`)
    
   // for m in item.matches where m.isCompleted {
   //     print("  reduceNow found edge of fully matched ‘\(m.definition.name.label)’ operation")
       // print("  ", self.stack[m.start]) // check start of match for contention, e.g. in `1 + 2 * 3` there is an SR conflict on `2` which requires comparing operator precedences to determine which operation to reduce first
        // in addition, if an EXPR operand match is not a fully-reduced .value(_) then that reduction needs to be performed first
    // }
}
