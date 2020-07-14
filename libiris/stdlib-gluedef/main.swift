//
//  main.swift
//

import Foundation
import iris

// TO DO: AsLiteralName coercion?; this'd allow aliases to be written directly as names rather than strings;

// TO DO: how to parameterize run-time return type? (TO DO: any primitive handler that evals native code need ability to pass result coercion as Swift func parameter; for now, best to declare requirement explicitly, c.f.     use_scopes:…)

// TO DO: should `use_scopes` argument also specify mutability requirements?

// TO DO: glue handler names shouldn't normally need single-quoted as (except for ‘to’, ‘as’, ‘returning’) they're not defined as operators when glue code is parsed

// TO DO: generic `left`/`right` arg labels are awful; use meaningful labels and binding names where practical and store that info in PatternDefinition to be used when reducing operators to annotated Commands

// TO DO: precedence should eventually be defined by tables describing relative ordering: for each group of operators (arithmetic, comparison, concatenative, reference, etc), ordering of operators within that group are described as a named table, i.e. (TABLENAME,Array<Set<OPNAME>>); these tables are then ordered relative to one another by Array<TABLENAME>; upon loading all operator definitions, the parser can assign numeric precedences for efficiency (although it may be simpler to store this as a separate [OPNAME:Int] dictionary rather than update PatternDefinition structs in-situ; one more level of indirection is unlikely to make any difference as it's not a bottleneck); main challenge is in deciding how to declare relative ordering of operator groups when these groups are defined across multiple libraries; e.g. if two unrelated third-party libraries define operator groups, those groups can be ordered relative to stdlib groups (e.g.. stdgrp3 < FOOGRP < stdgrp4), but not relative to each other (potentially a problem if BARGRP appears between stdgrp3 and 4 as well; for practical purposes the parser would have to forbid their direct composition, requiring explicit parentheses around one or other: `OP1 (EX OPB)` or `(OP1 EX) OPB`)

// TO DO: comparison and logic operators need higher precedence than `whose` operator (1200-1240?)


let stdlibGlue = """

«= stdlib glue definition =»

«== Arithmetic operators ==»

«TODO: should symbolic operators have word-based aliases? (these would provide speakable support automatically; alternative is to match spoken phrases to the symbols’ Unicode names)»

to ‘^’ {left as number, right as number} returning number requires {
    can_error: true
    swift_function: exponent
    operator:{form: #infix, precedence: 1300, associate: #right} «aliases: [“to_the_power_of”]»
}

«TO DO: unary positive/negative should be defined as ‘+’ and ‘-’ (primary names), and loaded into env as multimethods that dispatch on argument fields (for now, we define "+"/"-" as secondary alias names)»

«TO DO: what about plain text names (“add”, “subtract”, “multiply”, etc)? what about speakable names, e.g. “plus”, “minus”, “multiplied_by”? defining as aliases pollutes the global namespace; OTOH, these names are probably specific enough that they won't often collide with scripts’ own namings»

«TO DO: how to write operator patterns?»

to ‘positive’ {right as number} returning number requires {
    can_error: true
    operator:{form: #prefix, precedence: 1298, #left, [#‘+’], #reductionForPositiveOperator} «aliases: [0uFF0B]»
}

to ‘negative’ {right as number} returning number requires {
    can_error: true
    operator:{form: #prefix, precedence: 1298, #left, [#‘-’], #reductionForNegativeOperator} «aliases: [0uFF0D, 0u2212, 0uFE63]»
}


to ‘*’ {left as number, right as number} returning number requires {
    can_error: true
    swift_function: multiply
    operator:{form: #infix, precedence: 1296} «aliases: “×”»
}

to ‘/’ {left as number, right as number} returning number requires {
    can_error: true
    swift_function: divide
    operator:{form: #infix, precedence: 1296} «aliases: “÷”»
}

to ‘div’ {left as real, right as real} returning real requires {
    can_error: true
    operator:{form: #infix, precedence: 1296}
}

to ‘mod’ {left as real, right as real} returning real requires {
    can_error: true
    operator:{form: #infix, precedence: 1296}
}



to ‘+’ {left as Number, right as Number} returning Number requires {
    can_error: true
    swift_function: add
    operator:{form: #infix, precedence: 1290, associate: #left} «aliases: 0uFF0B»
}

to ‘-’ {left as Number, right as Number} returning Number requires {
    can_error: true
    swift_function: subtract
    operator:{form: #infix, precedence: 1290, associate: #left} «aliases: [0uFF0D, 0u2212, 0uFE63]»
}



to ‘<’ {left as real, right as real} returning boolean requires {
    swift_function: isLess
    operator:{form: #infix, precedence: 540}
}

to ‘≤’ {left as real, right as real} returning boolean requires {
    swift_function: isLessOrEqual
    operator:{form: #infix, precedence: 540} «aliases: ”<=”»
}

to ‘=’ {left as real, right as real} returning boolean requires {  «equality test, c.f. APL»
    swift_function: isEqual
    operator:{form: #infix, precedence: 540} «aliases: ”==”»
}

to ‘≠’ {left as real, right as real} returning boolean requires {
    swift_function: isNotEqual
    operator:{form: #infix, precedence: 540} «aliases: “<>”»
}

to ‘>’ {left as real, right as real} returning boolean requires {
    swift_function: isGreater
    operator:{form: #infix, precedence: 540}
}

to ‘≥’ {left as real, right as real} returning boolean requires {
    swift_function: isGreaterOrEqual
    operator:{form: #infix, precedence: 540} «aliases: “>=”»
}


«== Boolean operators ==»

to ‘NOT’ {right as boolean} returning boolean requires {
    operator:{form: #prefix, precedence: 400}
}

to ‘AND’ {left as boolean, right as boolean} returning boolean requires {
    operator:{form: #infix, precedence: 398}
}

to ‘OR’ {left as boolean, right as boolean} returning boolean requires {
    operator:{form: #infix, precedence: 396}

}

to ‘XOR’ {left as boolean, right as boolean} returning boolean requires {
    operator:{form: #infix, precedence: 394}
}


«== String operators ==»

«note: comparisons may throw if/when trinary `as` clause is added [unless we build extra smarts into glue generator to apply that coercion to the other args automatically, in which case glue code with throw so primitive funcs don't have to]»

«Q. how to name these operators? ideally they should not be confused with arithmetical comparison operators when spoken»

«=== comparison operators ===»

to ‘is_before’ {left as string, right as string} returning boolean requires {
    can_error: true
    operator:{form: #infix, precedence: 540}
}

to ‘is_not_after’ {left as string, right as string} returning boolean requires {
    can_error: true
    operator:{form: #infix, precedence: 540} «aliases: “is_before_or_same_as”»
}

to ‘is_same_as’ {left as string, right as string} returning boolean requires {
    can_error: true
    operator:{form: #infix, precedence: 540}
}

to ‘is_not_same_as’ {left as string, right as string} returning boolean requires {
    can_error: true
    operator:{form: #infix, precedence: 540}
}

to ‘is_after’ {left as string, right as string} returning boolean requires {
    can_error: true
    operator:{form: #infix, precedence: 540}
}

to ‘is_not_before’ {left as string, right as string} returning boolean requires {
    can_error: true
    operator:{form: #infix, precedence: 540} « aliases: “is_same_as_or_after” »
}

«=== containment operators ===»

«TO DO: convenience `does_not_begin_with`, etc.»

to ‘begins_with’ {left as string, right as string} returning boolean requires {
    can_error: true
    operator:{form: #infix, precedence: 542}
}

to ‘ends_with’ {left as string, right as string} returning boolean requires {
    can_error: true
    operator:{form: #infix, precedence: 542}
}

to ‘contains’ {left as string, right as string} returning boolean requires {
    can_error: true
    operator:{form: #infix, precedence: 542}
}

to ‘is_in’ {left as string, right as string} returning boolean requires {
    can_error: true
    operator:{form: #infix, precedence: 542}
}

«=== other operators ===»

to ‘&’ {left as string, right as string} returning string requires {
    can_error: true
    swift_function: joinValues
    operator:{form: #infix, precedence: 340}
}


«== String commands ==»

to uppercase {text as string} returning string requires {
}

to lowercase {text as string} returning string requires {
}

to format_code {value as optional} returning string requires {
}


«== IO commands ==»

to write {value as anything} returning nothing requires {
«TODO: 'to' argument field for specifying the external resource to write to (for now, primitive func is hardcoded to print() value's description to stdout)»
«TODO: what about error handling? e.g. if writing to locked/missing file; we want to keep read and write commands as generic as possible; OTOH, not all writers will throw [e.g. Swift's standard print() never throws]»
}


«== Type operators ==»

to ‘is_a’ {left: value as anything, right: coercion as coercion} returning boolean requires {
    use_scopes: #command
    operator:{#infix, 540}
}

to ‘as’ {left: value as anything, right: coercion as coercion} returning anything requires {
    can_error: true
    use_scopes: #command
    swift_function: coerce
    operator:{#infix, 350}
}


«== Flow control ==»

«TODO: better labels than left/right»

to ‘to’ {right: handler as procedure} returning procedure requires {
    can_error: true
    use_scopes: #command
    swift_function: defineCommandHandler
    operator:{#prefix, 80}
}

to ‘when’ {right: handler as procedure} returning procedure requires {
    can_error: true
    use_scopes: #command
    swift_function: defineEventHandler
    operator:{#prefix, 80}
}

to ‘set’ {name as name, to: value} returning anything requires { «assignment; TODO: name argument should be a chunk expression»
    can_error: true
    use_scopes: #command
    operator:{#prefix_with_conjunction, 80, #left, [#set, #to]}
}

«TO DO: how to express result/error of action as return value of 'if'? how to express `did_nothing` as alternate result of 'if?'? e.g. `returning result of right or did_nothing` (BTW, this is good example of why 'left' and 'right' are poor labels)»
to ‘if’ {left: condition as boolean, middle: action as expression, right: alternative_action as expression} returning anything requires {
    can_error: true «TODO: would be better to distinguish errors thrown by arguments from errors thrown by handler itself»
    use_scopes: #command
    swift_function: ifTest {condition, action, alternativeAction}
    operator:{#prefix_with_two_conjunctions, 101, #left, [#if, #then, #else]}
}

to ‘while’ {left: condition as boolean, right: action as expression} returning anything requires {
    can_error: true
    use_scopes: #command
    swift_function: whileRepeat {condition, action}
    operator:{#prefix_with_conjunction, 101, #left, [#while, #repeat]}
}

to ‘repeat’ {left: action as expression, right: condition as boolean} returning anything requires {
    can_error: true
    use_scopes: #command
    swift_function: repeatWhile {action, condition}
    operator:{#prefix_with_conjunction, 101, #left, [#repeat, #while]}
}

to ‘tell’ {left: target as value, right: action as expression} returning anything requires {
    can_error: true
    use_scopes: #command
    swift_function: tell {target, action}
    operator:{#prefix_with_conjunction, 101, #left, [#tell, #to]}
}


«== Chunk expressions ==»

to ‘of’ {left: attribute as expression, right: value as value} returning expression requires { «TODO: is left operand always a command?»
    can_error: true «TODO: throw immediately, or wait until query if fully constructed?»
    use_scopes: [#command, #handler]
    swift_function: ofClause {attribute, target}
    operator:{#infix, 1100} «binds tighter than commands»
}


to ‘app’ {bundle_identifier as string} returning value requires {
    can_error: true «TODO: errors (e.g. app not found) should only occur upon use, not creation»
    swift_function: Application
}


«=== Element selectors ===»

to ‘at’ {left: element_type as name, right: selector_data as expression} returning expression requires {
    can_error: true
    use_scopes: [#command, #handler] «`elements at expr thru expr` will eval exprs in handler's scope, delegating to command scope»
    swift_function: atSelector {elementType, selectorData}
    operator:{#infix, 1110, #right} « “index” »
}

to ‘named’ {left: element_type as name, right: selector_data as expression} returning expression requires {
    can_error: true
    use_scopes: #command
    swift_function: nameSelector {elementType, selectorData}
    operator:{#infix, 1110}
}

to ‘id’ {left: element_type as name, right: selector_data as expression} returning expression requires { «TODO: what about ‘id’ properties? (easiest is to define id as .atom operator as well as .infix, with multimethod despatching on 0/2 operands; while operators could in principle fall back to commands when the operands found don't match any of the known operator definitions, it would be hard to distinguish an intended command from an operator with missing arguments [i.e. syntax error])»
    can_error: true
    use_scopes: #command
    swift_function: idSelector {elementType, selectorData}
    operator:{#infix, 1110}
}

to ‘from’ {left: element_type as name, right: selector_data as expression} returning expression requires {
    can_error: true
    use_scopes: [#command, #handler]
    swift_function: rangeSelector {elementType, selectorData}
    operator:{#infix, 1110}
}

to ‘whose’ {left: element_type as name, right: selector_data as expression} returning expression requires {
    can_error: true
    use_scopes: [#command, #handler] «`elements where expr` will eval expr in handler's scope, delegating to command scope, allowing expr to refer to properties and elements without requiring an explicit `its`»
    swift_function: testSelector {elementType, selectorData}
    operator:{#infix, 1110}
}

«=== element range ===»

to ‘thru’ {left: startSelector as expression, right: endSelector as expression} returning expression requires {
    swift_function: ElementRange {‘from’, ‘to’}
    operator:{#infix, 1120}
}

«=== absolute ordinal ===»

to ‘first’ {right: element_type as name} returning expression requires {
    swift_function: firstElement
    operator:{#prefix, precedence: 1130}
}

to ‘middle’ {right: element_type as name} returning expression requires {
    swift_function: middleElement
    operator:{#prefix, precedence: 1130}
}

to ‘last’ {right: element_type as name} returning expression requires {
    swift_function: lastElement
    operator:{#prefix, precedence: 1130}
}

to ‘any’ {right: element_type as name} returning expression requires { «TODO: what to call this? 'any'? 'some'? 'random'?»
    swift_function: randomElement
    operator:{#prefix, precedence: 1130} « aliases: [“some”, “random”] »
}

to ‘every’ {right: element_type as name} returning expression requires {
    swift_function: allElements
    operator:{#prefix, precedence: 1130} « aliases: “all” »
}

«=== relative ordinal ===»

to ‘before’ {left: element_type as name, right: expression as expression} returning expression requires {
    swift_function: beforeElement
    operator:{#infix, precedence: 1126}
}

to ‘after’ {left: element_type as name, right: expression as expression} returning expression requires {
    swift_function: afterElement
    operator:{#infix, precedence: 1126}
}

«=== insertion location ====»

to ‘before’ {right: expression as expression} returning expression requires {
    swift_function: insertBefore
    operator:{#prefix, precedence: 1106}
}

to ‘after’ {right: expression as expression} returning expression requires {
    swift_function: insertAfter
    operator:{#prefix, precedence: 1106}
}

to ‘beginning’ returning expression requires {
    swift_function: insertAtBeginning
    operator:{#atom, precedence: 1106}
}

to ‘end’ returning expression requires {
    swift_function: insertAtEnd
    operator:{#atom, precedence: 1106}
}

"""




//print(handlersTemplate.debugDescription)

func renderStdlibGlue() {
    do {
        let code = try renderHandlerGlue(for: "stdlib", from: stdlibGlue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
        print(code)
    } catch {
        print(error)
    }
}

renderStdlibGlue()


