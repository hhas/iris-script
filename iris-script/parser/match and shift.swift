//
//  match and shift.swift
//  iris-script
//

import Foundation

/*
 TO DO: FIX: there is a bug somewhere in here that causes `if` matcher to be added to stack a second time:
 

     matchOperator(`if`):
     Stack[0..<3]:
         .operatorName(<if (‘if’ EXPR ‘then’ EXPR (‘else’ EXPR)?)>) [1]
                     «match `if…then……` U1 O1 G1: () ‘if’ (EXPR ‘then’ EXPR (‘else’ EXPR)?) 104»
         .value(1) [2]
                     «match `if…then……` U3 O1 G1: (‘if’) EXPR (‘then’ EXPR (‘else’ EXPR)?) 104»
                     «match `if…then……` U2 O1 G1: (‘if’) EXPR (‘then’ EXPR (‘else’ EXPR)?) 104»
         .operatorName(<then (‘if’ EXPR ‘then’ EXPR (‘else’ EXPR)?)>) [2]
                     «match `if…then……` U6 O1 G1: (‘if’ EXPR) ‘then’ (EXPR (‘else’ EXPR)?) 104»
                     «match `if…then……` U7 O1 G1: (‘if’ EXPR) ‘then’ (EXPR (‘else’ EXPR)?) 104»
 
 */


extension Parser {

    // match prefix/infix operator definitions to current or previous+current tokens
    //
    // this method back-matches by up to 1 token in the event the operator pattern starts with an EXPR followed by the operator itself (note: this does not match conjunctions as those should be at least two tokens ahead of the primary operator name)
    
        
    // shift moves the current token from lexer to parser's stack and applies any in-progress matchers to it
    //
    // note: if shift completes a list/record/group literal, it is immediately reduced to a value (see PatternDefinition.autoReduce; i.e. any pattern which has explicit start and end delimiters can be safely auto-reduced as precedence and associativity rules only apply to operators that start and/or end with an EXPR)
    // anything else is left on the stack until an explicit reduceExpression() phase is triggered
    
    func shift(form: Token.Form? = nil, adding newMatches: [PatternMatch] = []) { // newMatches have (presumably) already matched this token, but we match them again to be sure
        let form = form ?? self.current.token.form
        //      print("\nCURRENT:", form)
        let matches: [PatternMatch]
        
        // TO DO: any new matches that don't match form should be tried against top of stack and, if that matches, advanced and matched to form; that should take care of infix/postfix ops (the match func below merges into this shift func)
        
        if let previousMatches = self.stack.last?.matches { // advance any in-progress matches
            //print("PREV:", previousMatches, "\nNEW:", newMatches)
            matches = previousMatches.flatMap{$0.next()} + newMatches
        } else {
            //print("NEW:", newMatches)
            matches = newMatches
        }
        
        
        // apply in-progress and newly-started matchers to current token, noting any that end on this token
        var continuingMatches = [PatternMatch](), fullMatches = [PatternMatch]()
        for match in matches {
            if match.provisionallyMatches(form: form) { // match succeeded for this token
                continuingMatches.append(match)
                if match.isAFullMatch { fullMatches.append(match) }
            }
        }
        //print("SHIFT matched", form, "to", continuingMatches, "with completions", completedMatches)
        self.stack.append((form, continuingMatches, self.current.token.hasLeadingWhitespace))
        // TO DO: if >1 complete match, we can only reduce one of them (i.e. need to resolve any reduce conflicts *before* reducing, otherwise 2nd will get wrong stack items to operate on; alternative would be to fork multiple parsers and have each try a different strategy, which might be helpful during editing)
        // TO DO: what if there are still in-progress matches running? (can't start reducing ops till those are done as we want longest match and precedence needs resolved anyway, but ops shouldn't auto-reduce anyway [at least not unless they start AND end with keyword])
                if !fullMatches.isEmpty { print("SHIFT fully matched", fullMatches) }
        
        //   print("SHIFT \(self.stack.count - 1): .\(form)")
        
        // automatically reduce atomic operators and list/record/group/block literals (i.e. anything that starts and ends with a static token, not an expr, so is not subject to precedence or association rules)
        // TO DO: not sure if reasoning is correct here; if we limit auto-reduction to builtins (which we control) then it's safe to say there will be max 1 match, but do…done blocks should also auto-reduce and those are library-defined; leave it for now as it solves the immediate need (reducing literal values as soon as they're complete so operator patterns can match them as operands); probably safest to require auto-reducing patterns to have a single terminating token only (i.e. no optional tail clauses and no [or restricted?] keyword overloading)
        if let longestMatch = fullMatches.max(by: { $0.count < $1.count }), longestMatch.definition.autoReduce {
            //           print("\nAUTO-REDUCE", longestMatch.definition.name.label)
            self.stack.reduce(fullMatch: longestMatch)
            if fullMatches.count > 1 {
                // TO DO: what if there are 2 completed matches of same length?
                print("discarding extra matches in", fullMatches.sorted{ $0.count < $1.count })
            }
        }
        //      print("SHIFTED STACK:", self.stack.dump()); print()
    }
    
    
    
    
    
    //
    
    
    internal func match(_ newMatches: [PatternMatch]) -> (previousTokenMatches: [PatternMatch], currentTokenMatches: [PatternMatch], conjunctionTokenMatches: [PatternMatch]) {
        let form = self.current.token.form
        var precedingMatches = [PatternMatch]() // new matchers to be added to the previously shifted token, i.e. all operators that have a left operand followed by the current token
        var currentMatches = [PatternMatch]()   // new matchers to be added to the current token when it is shifted, i.e. all patterns that start with the current token
        var conjunctionMatches = [PatternMatch]() // in-progress matchers that are awaiting a conjunction keyword in order to complete their current EXPR match
        for match in newMatches {
            if match.provisionallyMatches(form: form) { // attempt to match the current token; this allows new matchers to match atom/prefix operators (match starts on .operatorName token)
                currentMatches.append(match)
                if match.hasConjunction { conjunctionMatches.append(match) }
            } else if let previous = self.stack.last, match.provisionallyMatches(form: previous.form) { // attempt to match the previous token (expr), followed by current token (opName); this allows new matchers to match infix/postfix operators (match starts on token before .operatorName)
                // confirm opname was 2nd pattern (i.e. primary keyword, not a conjunction); kludgy
                let matches = match.next().filter{ $0.fullyMatches(form: form) } // caution: since opdefs currently include conjunctions, we need to rematch operatorName here; this'll match infix/postfix ops and discard conjunctions // TO DO: apply this match even when previous match fails and, if it succeeds, put matcher in current token's stack frame, marking it as requiring backmatch?
                if !matches.isEmpty {
                    //currentMatches += matches
                    precedingMatches.append(match) // for now, put left expr matcher in previous frame; it'll advance back onto .operatorName when next shift(); caution: this works only inasmuch as previous token can be matched as EXPR, otherwise matcher is not attached and is lost from stack (we should be okay as we're only doing partial match of leading expr)
                    if match.hasConjunction { conjunctionMatches.append(match) }
                }
            }
        }
        //     print("PREV", previousMatches, "CURR", currentMatches)
        return (precedingMatches, currentMatches, conjunctionMatches)
    }
    
    
    func matchOperator(_ definitions: OperatorDefinitions) {
        guard case .operatorName(let opname) = self.current.token.form else { fatalError("BUG") }
        print("\nmatchOperator(`\(opname.name.label)`):"); self.stack.show(); print()
        // called by parser's main loop when an .operatorName(…) token is encountered
        if case .colon = self.current.next().token.form { // `OPNAME COLON` is reduced to .label, same as `NAME COLON`
            self.shiftLabel(named: Symbol(self.current.token.content)) // this shifts the reduced `.label(NAME)` onto stack
        } else if let matches = self.blockMatchers.conjunctionMatches(for: definitions.name) {
            // check if keyword is an awaited conjunction (e.g. `then` in `if…then…`); if so, fully reduce the preceding EXPR (for this, we need to backsearch the shift stack for that matcher by uniqueID; once we find it, we know the range of tokens to reduce; e.g. given `if…then…` we want to reduce everything between the `if` and the `then` keywords to a single .value, but we don't want to risk reducing the `if EXPR` as well in the event that `if` is overloaded as a prefix operator as well; i.e. we can't make assumptions about library-defined operators)
            // TO DO: given an overloaded conjunction, e.g. `to` is both a conjunction after `tell` and a prefix operator in its own right, how to ensure it is always matched as conjunction and other interpretations are ignored? (currently, after matching `to` token as a conjunction, we proceed to standard operator matching which will want to start matching it as a `to` operator; there are also questions on how to deal with bad expr seqs such as `EXPR prefixOp EXPR`, and longest-match vs best-match rules)
            // one reason for keeping "unmatchable" matchers (i.e. where keyword is conjunction rather than prefix/infix operator) is that those matchers may be used to generate error messages when a stray conjunction is found, e.g. "found stray `then` keyword outside of `if…then…` expression"
            print("Reducing EXPR before expected conjunction:", matches)
            self.reduceExpressionBeforeConjunction(matchedBy: matches)
            self.shift() // shift the conjunction onto stack
        } else { //
               print("matching operator", definitions.name)
            // preceding matches = infix operators; these will be re-matched to current operator token upon shift()
            // current matches = prefix operators
            // conjunction matches = matches already in progress (strictly speaking we only need their matchIDs)
            let (precedingMatches, currentMatches, conjunctionMatches) = self.match(definitions.newMatches())
            
            /* self.match([PatternMatch]) is called from parser’s main loop in two places: here (which is part of .operatorName case) and in .semicolon case
             
             self.fullyReduceExpression() // TO DO: confirm this is correct (i.e. punctuation should always have lowest precedence so that operators on either side always bind first)
             let (previousMatches, currentMatches, _) = self.match(pipeLiteral.newMatches()) // TO DO: currently ignores conjunctionMatches
             //print(definitions.name.label, backMatches, newMatches)
             if !previousMatches.isEmpty { stack.append(matches: previousMatches) }
             self.shift(adding: currentMatches)
                          
             */
            
            print("PrevM",precedingMatches)
            print("CurrM",currentMatches)
            print("ConjM",conjunctionMatches)

            if !precedingMatches.isEmpty { stack.append(matches: precedingMatches) }
            if !conjunctionMatches.isEmpty {
                
                // TO DO: these are new matchers; we need them advanced to match conjunction keyword (can't do that: they may have >1 pattern, e.g. `do…done` yields 2 matchers, one that takes delimiter and `done` and the other takes delimiter followed by zero or more expr+delim then `done`)
                var conjunctions = [Symbol: [PatternMatch]]()
                for m in conjunctionMatches {
                    for n in m.conjunctions {
                        if conjunctions[n] == nil {
                            conjunctions[n] = [m]
                        } else {
                            conjunctions[n]!.append(m)
                        }
                    }
                }
                //print("Found \(operatorDefinitions.name); will look for conjunction:", conjunctions.map{$0.key})
                self.blockMatchers.start(.conjunction(conjunctions))
            } // TO DO: confirm this is appropriate
            //  print("ADDING MATCHERS:", currentMatches)
            self.shift(adding: currentMatches)
        }
    }
}
