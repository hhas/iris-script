//
//  match and reduce.swift
//  iris-script
//

// WIP

import Foundation


// `to name returning typename typearg: action` is problematic; it's not clear if `typearg` is labeled arg or direct arg; one option would be to use `to…do…done`, but that's inconsistent with `do…done` usage elsewhere; might use a different conjunction, e.g. `to…run…`, `to…perform…`, `to…then…`, `to…action…`, `to…evaluate…`

// pulled this out of Parser for now; not sure if it should be there or on matcher


// TO DO: conjunctions should trigger reduction (what if conjunction is also non-conjunction)



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
        case .quotedName(let name), .unquotedName(let name): return name
        case .operatorName(let definitions):                 return definitions.name
        default:                                             return nullSymbol
        }
    }
}



// TO DO: should stack track previous delimiter index, allowing us to know number of stack frames to be reduced (if 1, and it's .value, we know it's already fully reduced)

// TO DO: when comparing precedence, look for .values in stack that have overlapping operator matches where one isAtBeginningOfMatch and other isAFullMatch; whichever match has the higher definition.precedence (or if both are same definition and associate==.right) reduce that first



// TO REDUCE:
// if matches[0].start != 0, ops haven't matched exactly

// simple matching strategy, assuming range is 100% matched by single expression composed of 1 or more operations: start at first match in sorted array [of completed matches] (which should have start index 0) and get its end index, then advance until [longest] pattern whose start index == previous match's end index is found; repeat until end index == end of range (or no matches left, if not perfect match)

// the problem remains: unreduced operands prevent all patterns initially matching; thus there will be gaps between completed matches (e.g. `1 - -2`) -- so just keep re-running scan, doing one reduction per-pass, until no more reductions can be made


// note: even with this strategy we need to do precedence comparisons so that we know *which* match to reduce when (one or more) contentions are found; basically, when doing pass we need to extract operator indices and precedence, and have some way of chunking them when command names/arg labels are found




// a command name preceded by an operator requires that operator be prefix/infix (i.e. has trailing EXPR) else it's a syntax error; thus encountering a name when scanning backwards mean reduction can be performed from that command name up to any right-hand infix/postfix operators that have lower precedence than argument binding

// any operator to immediate right of an arg label must be prefix/atom else it's a syntax error


// patterns to look for: `.operatorName .value .operatorName` -- needs precedence/association comparison to resolve


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

// logic for disambiguating `cmd OP val` where OP is both prefix and infix operator (this should be hardcoded behavior in parser, not pattern): if OP has balanced whitespace then treat as infix operator whose LH operand is cmd; if OP has unbalanced whitespace (e.g. `foo -1`) then treat as prefix operator on val and pass that operation as argument



typealias MatchInfo = (start: Int, end: Int, matcher: PatternMatcher) // `start...end`

func key(_ info: MatchInfo) -> String {
    return "\(info.start) \(info.matcher.definition.name.key)"
}


extension Parser {
    
    func readLowPunctuationCommand() {
        
    }
    
    func fullyReduceExpression() {
        
        // caution: we have to be careful when reducing a range of tokens, as it's possible to have [pathological?] cases where an operator has an optional conjunction, e.g. `foo EXPR ( bar EXPR )?`: when parser encounters that conjunction, it will trigger a reduction; however, that reduction must not consume the shorter completed `foo EXPR` match
        
        self.reduceExpression() // TO DO: keep reducing until a single .value, otherwise reduce to error value
    }
    
    // called by reduceNow() when a RH expr delimiter is found
    func reduceExpression(allowLowPunctuationSyntax: Bool = false) { // TO DO: is there any use-case where this can perform partial reduction only?
        
        // we're starting from top of stack here (end of code), so question is, how do we deal with commands
        
        // implement operator reduction only for now
        
        
        /// caution `a - 1` needs to parse as `-{a{},1}`, not `a{-1}`, but initially the `-` matcher will only match unary `-`
        
        let stack = self.stack
        guard let item = stack.last else { return } // this'll only occur if a separator appears at start of script
        print("reduceNow:", item)
        
        // temporary
        if item.matches.count == 1 && item.matches[0].isAFullMatch {
            self.reduce(completedMatch: item.matches[0], endingAt: stack.count)
        }
        
        
        // problem: SR immediately reduces higher-precedence operation when +1 lookahead indicates infix/postfix operator of lower precedence is next, whereas we're reading all operators then reducing them in-place
        
        
        
        
        // TO DO: can we extract commands here? ([un]quoted names, colons, (NAME EXPR) preceded by [what?]; running backwards arguably helps)
        //print("back-scan…")
        
        
        // Q. how would pattern matchers work if, having found end and start of a complete expression, we switched to reading it using recursive descent? (we'd still use auto-reduction for lists, blocks, etc, which are the long structures that need shift-reduce for incremental parsing)
        
        // TO DO: backscanning needs to cope with `if expr then …`, where `if…then…` may not be initially resolvable due to middle expr not yet being reduced; it is a case of expanding from innermost exprs outwards (which is point of SR)
        
        // TO DO: `a - 1` should also produce partial COMMAND match for `a -`, but isn’t - why?
        
        // TO DO: rework BadSyntax error; need to capture unreduced token sequence (malformed EXPR) as well as explanation of problem, then push that onto stack; Q. presumably this needs to be both Value and NativeError so that remaining reductions can be performed
        /*
        let end = stack.count
        
        // find the start of current expression, extracting longest matches (e.g. an infix operator will add three matches to stack, of which only the last is relevant) // TO DO: remove previous incomplete match when adding next match to stack? (that'd save the extra work of removing them here)
        var i = end
        var allMatches = [String: MatchInfo]()
        loop: while i > 0 {
            i -= 1
            let (form, matches, _, _) = stack[i]
            for match in matches {
                // TO DO: this also discards completed matches if a longer match of same pattern was made
                let matchInfo = (i - match.count + 1, i, match)
                let k = key(matchInfo)
                if allMatches[k] == nil { allMatches[k] = matchInfo }
            }
            switch form {
            case .separator(_), .lineBreak:
                i += 1
                break loop
            case .startList, .startRecord, .startGroup:
                i += 1
                break loop
            // TO DO: what about semicolon?
            default: ()
            }
        }
        let start = i
        //print("…found start of expression at \(start)")
        print("REDUCE expression: \(start)...\(end-1)")
        
        // var precedence = Precedence.min
        for frame in self.stack[start..<end] {
            print(frame.token)
            if case .operatorName(let defs) = frame.reduction {
                print("…", defs.name, defs.map{$0.precedence})
            }
        }
        
        /*
         do {
         let _ = try readExpr(StackReader(stack:self.stack[start..<end], index: start)) // we need blockreader for *start* of expr
         } catch {
         print("readExpr ERROR:", error)
         }
         */
        // lists the patterns that *can* match; caution: this list is not complete as some patterns may not match fully/at all until others are reduced
        for item in stack[start..<end] {
            print(" - ", item.reduction, item.matches.filter{$0.isAFullMatch})
        }
        /*
         do {
         var cleanedMatches = [MatchInfo]()
         var start = 0, end = -1
         for m in allMatches.values.sorted(by: {$0.start < $1.start})  {
         do {//if !(m.start >= start && m.end <= end) {
         cleanedMatches.append(m)
         start = m.start; end = m.end
         let _ = end, _ = start
         }
         }
         print()
         print("operation matchers:")
         for m in cleanedMatches {
         print(" - \(m.start)...\(m.end) \(m.matcher.isAFullMatch ? "Y" : "N") `\(m.matcher.definition.name.label)`")
         }
         print()
         
         // further problem: infix ops may not have matched at all if preceded by non-.value
         
         }
         // TO DO: also discard non-longest matches?
         */
        
        // TO DO: precedence
        
        //if let (_, end, match) = matchers.first { // test
        //     self.reduce(completedMatch: match, endingAt: end+1)
        // }
        
        
        // for m in item.matches where m.isAFullMatch {
        //     print("  reduceNow found edge of fully matched ‘\(m.definition.name.label)’ operation")
        // print("  ", self.stack[m.start]) // check start of match for contention, e.g. in `1 + 2 * 3` there is an SR conflict on `2` which requires comparing operator precedences to determine which operation to reduce first
        // in addition, if an EXPR operand match is not a fully-reduced .value(_) then that reduction needs to be performed first
        // }
 
 */
    }

      
      func reduce(completedMatch: PatternMatcher, endingAt endIndex: Int) {
          let startIndex = endIndex - completedMatch.count // check math (endIndex is inclusive)
          let reduction: StackItem
          let token: Token = endIndex < self.stack.count ? self.stack[endIndex].token : self.current.token
          let hasLeadingWhitespace = self.stack[startIndex].hasLeadingWhitespace
          switch completedMatch.definition.reduce(self.stack, completedMatch.definition, startIndex, endIndex) {
          case .value(let v):
              var updatedMatchers = [PatternMatcher]()
              if startIndex > 0 { // reapply the preceding stack frame's matchers to newly reduced value
                  for match in self.stack[startIndex - 1].matches {
                      for match in match.next() {
                          //print("rematching", match, "to", type(of: v), v, match.match(.value(v)))
                          if match.match(.value(v)) {
                              updatedMatchers.append(match)
                              
                              // TO DO: what if match is completed? where should reduction be triggered? (where should contention be checked?)
                          }
                      }
                  }
                  //print("updated matchers:", updatedMatchers)
              }
              reduction = (Form.value(v), updatedMatchers, hasLeadingWhitespace, token)
          case .error(let e):
              reduction = (Form.error(e), [], hasLeadingWhitespace, token)
          }
    //      print("reduce()", completedMatch, "->", reduction)
          self.stack.replaceSubrange((startIndex..<endIndex), with: [reduction])
          //show(self.stack, 0, self.stack.count, "after reduction")
      }
      
      //
      
      func reduce(conjunction: Token.Form, matchedBy matchers: [PatternMatcher]) {
          let matchID: Int // find nearest
          if matchers.count == 1 {
              matchID = matchers[0].matchID
          } else {
              matchID = matchers.min{ $0.count < $1.count }!.matchID // confirm this logic
          }
          let start = self.stack.lastIndex{ $0.matches.first{ $0.matchID == matchID } != nil }!
          let end = self.stack.count - 1
          print("Reduce expression:")
          show(self.stack, start, end)
          self.fullyReduceExpression() // ensure last item is reduced
      }
    
}
