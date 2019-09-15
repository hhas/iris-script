//
//  main.swift
//

import Foundation

// TO DO: AsLiteralName coercion?; this'd allow aliases to be written directly as names rather than strings;

// TO DO: how to parameterize run-time return type? (TO DO: any primitive handler that evals native code need ability to pass result coercion as Swift func parameter; for now, best to declare requirement explicitly, c.f. use_scopes:…)

// TO DO: should `use_scopes` argument also specify mutability requirements?


let stdlibGlue = """

«= stdlib glue definition =»

«== Arithmetic operators ==»

«TODO: should symbolic operators have word-based aliases? (these would provide speakable support automatically; alternative is to match spoken phrases to the symbols’ Unicode names)»

to ‘^’ {left as number, right as number} returning number: do
can_error: true
swift_function: exponent
operator: {form: #infix, precedence: 600, associativity: #right, aliases: [“to_the_power_of”]}
done

«TO DO: unary positive/negative should be defined as ‘+’ and ‘-’ (primary names), and loaded into env as multimethods that dispatch on argument fields (for now, we define "+"/"-" as secondary alias names)»

«TO DO: what about plain text names (“add”, “subtract”, “multiply”, etc)? what about speakable names, e.g. “plus”, “minus”, “multiplied_by”? defining as aliases pollutes the global namespace; OTOH, these names are probably specific enough that they won't often collide with scripts’ own namings»

to ‘positive’ {right as number} returning number: do
can_error: true
operator: {form: #prefix, precedence: 598, aliases: [“+”, 0uFF0B]}
done

to ‘negative’ {right as number} returning number: do
can_error: true
operator: {form: #prefix, precedence: 598, aliases: [“-”, 0uFF0D, 0u2212, 0uFE63]}
done


to ‘*’ {left as number, right as number} returning number: do
can_error: true
swift_function: multiply
operator: {form: #infix, precedence: 596, aliases: “×”}
done

to ‘/’ {left as number, right as number} returning number: do
can_error: true
swift_function: divide
operator: {form: #infix, precedence: 596, aliases: “÷”}
done

to ‘div’ {left as real, right as real} returning real: do
can_error: true
operator: {form: #infix, precedence: 596}
done

to ‘mod’ {left as real, right as real} returning real: do
can_error: true
operator: {form: #infix, precedence: 596}
done



to ‘+’ {left as Number, right as Number} returning Number: do
can_error: true
swift_function: add
operator: {form: #infix, precedence: 590, associativity: #left, aliases: 0uFF0B}
done

to ‘-’ {left as Number, right as Number} returning Number: do
can_error: true
swift_function: subtract
operator: {form: #infix, precedence: 590, associativity: #left, aliases: [0uFF0D, 0u2212, 0uFE63]}
done



to ‘<’ {left as real, right as real} returning boolean: do
swift_function: isLess
operator: {form: #infix, precedence: 540}
done

to ‘≤’ {left as real, right as real} returning boolean: do
swift_function: isLessOrEqual
operator: {form: #infix, precedence: 540, aliases: ”<=”}
done

to ‘=’ {left as real, right as real} returning boolean: do  «equality test, c.f. APL»
swift_function: isEqual
operator: {form: #infix, precedence: 540, aliases: ”==”}
done

to ‘≠’ {left as real, right as real} returning boolean: do
swift_function: isNotEqual
operator: {form: #infix, precedence: 540, aliases: “<>”}
done

to ‘>’ {left as real, right as real} returning boolean: do
swift_function: isGreater
operator: {form: #infix, precedence: 540}
done

to ‘≥’ {left as real, right as real} returning boolean: do
swift_function: isGreaterOrEqual
operator: {form: #infix, precedence: 540, aliases: “>=”}
done


«== Boolean operators ==»

to ‘NOT’ {right as boolean} returning boolean: do
operator: {form: #prefix, precedence: 400}
done

to ‘AND’ {left as boolean, right as boolean} returning boolean: do
operator: {form: #infix, precedence: 398}
done

to ‘OR’ {left as boolean, right as boolean} returning boolean: do
operator: {form: #infix, precedence: 396}

done

to ‘XOR’ {left as boolean, right as boolean} returning boolean: do
operator: {form: #infix, precedence: 394}
done


«== String operators ==»

«note: comparisons may throw if/when trinary `as` clause is added [unless we build extra smarts into glue generator to apply that coercion to the other args automatically, in which case glue code with throw so primitive funcs don't have to]»

«Q. how to name these operators? ideally they should not be confused with arithmetical comparison operators when spoken»

«=== comparison operators ===»

to ‘is_before’ {left as string, right as string} returning boolean: do
can_error: true
operator: {form: #infix, precedence: 540}
done

to ‘is_not_after’ {left as string, right as string} returning boolean: do
can_error: true
operator: {form: #infix, precedence: 540, aliases: “is_before_or_same_as”}
done

to ‘is’ {left as string, right as string} returning boolean: do
can_error: true
operator: {form: #infix, precedence: 540}
done

to ‘is_not’ {left as string, right as string} returning boolean: do
can_error: true
operator: {form: #infix, precedence: 540}
done

to ‘is_after’ {left as string, right as string} returning boolean: do
can_error: true
operator: {form: #infix, precedence: 540}
done

to ‘is_not_before’ {left as string, right as string} returning boolean: do
can_error: true
operator: {form: #infix, precedence: 540, aliases: “is_same_as_or_after”}
done

«=== containment operators ===»

«TO DO: convenience `does_not_begin_with`, etc.»

to ‘begins_with’ {left as string, right as string} returning boolean: do
can_error: true
operator: {form: #infix, precedence: 542}
done

to ‘ends_with’ {left as string, right as string} returning boolean: do
can_error: true
operator: {form: #infix, precedence: 542}
done

to ‘contains’ {left as string, right as string} returning boolean: do
can_error: true
operator: {form: #infix, precedence: 542}
done

to ‘is_in’ {left as string, right as string} returning boolean: do
can_error: true
operator: {form: #infix, precedence: 542}
done

«=== other operators ===»

to ‘&’ {left as string, right as string} returning string: do
can_error: true
swift_function: joinValues
operator: {form: #infix, precedence: 340}
done


«== String commands ==»

to uppercase {text as string} returning string: do
done

to lowercase {text as string} returning string: do
done

to format_code {value as optional} returning string: do
done


«== IO commands ==»

to write {value as anything} returning nothing: do
«TODO: 'to' argument field for specifying the external resource to write to (for now, primitive func is hardcoded to print() value's description to stdout)»
«TODO: what about error handling? e.g. if writing to locked/missing file; we want to keep read and write commands as generic as possible; OTOH, not all writers will throw [e.g. Swift's standard print() never throws]»
done


«== Type operators ==»

to ‘is_a’ {left: value as anything, right: coercion as coercion} returning boolean: do
use_scopes: #command
operator: {#infix, 540}
done

to ‘as’ {left: value as anything, right: coercion as coercion} returning anything: do
can_error: true
use_scopes: #command
swift_function: coerce
operator: {#infix, 350}
done


«== Flow control ==»

«TODO: operator parsefuncs always label arguments `left` and/or `right`; this is not ideal, but we'll live with it until table-driven parser is implemented»

to ‘to’ {right: handler as procedure} returning procedure: do
can_error: true
use_scopes: #command
swift_function: defineCommandHandler
operator: {#prefix, 180}
done

to ‘when’ {right: handler as procedure} returning procedure: do
can_error: true
use_scopes: #command
swift_function: defineEventHandler
operator: {#prefix, 180}
done

to ‘set’ {name as name, to: value} returning anything: do «assignment; TODO: name argument should be a chunk expression»
can_error: true
use_scopes: #command
«TODO: make this an operator, as in AS? (it's awfully easy to forget the colon after the `to` keyword, and mildly irritating to have to type it; in principle, a3c could insert the colon automatically, but it may be easier to visually read as an operator, particularly when the name operand is a lengthy expr)»
done

to ‘if’ {left: condition as boolean, right: action as expression} returning anything: do
can_error: true «TODO: would be better to distinguish errors thrown by arguments from errors thrown by handler itself»
use_scopes: #command
swift_function: ifTest {condition, action}
operator: {#parseIfThenOperator, 100}
done

to ‘else’ {left as expression, right as expression} returning anything: do
can_error: true
use_scopes: #command
swift_function: elseTest
operator: {#infix, 90} «lower precedence than `if`, lp commands; TO DO: adaptive precedence when `if` operators are nested; each `else` should bind to its closest left-hand `if`; alternative is that we handle optional `else` clause within parsefunc, although that lacks composability that an infix `else` provides [assuming we can make it parse]; for example, how should/will following parse: `if t1 then if t2 then a1 else a2 else a3`? It should be `(if t1 then (if t2 then a1 else a2)) else (a3)`, so that outer `else` takes `if t1 then if t2 then a1 else a2` as its left operand, but currently parses as `if t1 then (if t2 then ((a1 else a2) else (a3)))`»
done

to ‘while’ {left: condition as boolean, right: action as expression} returning anything: do
can_error: true
use_scopes: #command
swift_function: whileRepeat {condition, action}
operator: {#parseWhileRepeatOperator, 100}
done

to ‘repeat’ {left: action as expression, right: condition as boolean} returning anything: do
can_error: true
use_scopes: #command
swift_function: repeatWhile {action, condition}
operator: {#parseRepeatWhileOperator, 100}
done

to ‘tell’ {left: target as value, right: action as expression} returning anything: do
can_error: true
use_scopes: #command
swift_function: tell {target, action}
operator: {#parseTellToOperator, 100}
done


«== Chunk expressions ==»

to ‘of’ {left: attribute as expression, right: value as value} returning expression: do «TODO: is left operand always a command?»
can_error: true «TODO: throw immediately, or wait until query if fully constructed?»
use_scopes: [#command, #handler]
swift_function: ofClause {attribute, target}
operator: {#infix, 304} «binds tighter than commands»
done


to ‘app’ {bundle_identifier as string} returning value: do
can_error: true «TODO: errors (e.g. app not found) should only occur upon use, not creation»
swift_function: Application
done


«=== Element selectors ===»

to ‘at’ {left: element_type as name, right: selector_data as expression} returning expression: do
can_error: true
use_scopes: [#command, #handler] «`elements at expr thru expr` will eval exprs in handler's scope, delegating to command scope»
swift_function: atSelector {elementType, selectorData}
operator: {#infix, 310, #right, “index”}
done

to ‘named’ {left: element_type as name, right: selector_data as expression} returning expression: do
can_error: true
use_scopes: #command
swift_function: nameSelector {elementType, selectorData}
operator: {#infix, 310}
done

to ‘id’ {left: element_type as name, right: selector_data as expression} returning expression: do «TODO: what about ‘id’ properties? (easiest is to define id as .atom operator as well as .infix, with multimethod despatching on 0/2 operands; while operators could in principle fall back to commands when the operands found don't match any of the known operator definitions, it would be hard to distinguish an intended command from an operator with missing arguments [i.e. syntax error])»
can_error: true
use_scopes: #command
swift_function: idSelector {elementType, selectorData}
operator: {#infix, 310}
done

to ‘from’ {left: element_type as name, right: selector_data as expression} returning expression: do
can_error: true
use_scopes: [#command, #handler]
swift_function: rangeSelector {elementType, selectorData}
operator: {#infix, 310}
done

to ‘whose’ {left: element_type as name, right: selector_data as expression} returning expression: do
can_error: true
use_scopes: [#command, #handler] «`elements where expr` will eval expr in handler's scope, delegating to command scope, allowing expr to refer to properties and elements without requiring an explicit `its`»
swift_function: testSelector {elementType, selectorData}
operator: {#infix, 310}
done

«=== element range ===»

to ‘thru’ {left: startSelector as expression, right: endSelector as expression} returning expression: do
swift_function: ElementRange {‘from’, ‘to’}
operator: {#infix, 330}
done

«=== absolute ordinal ===»

to ‘first’ {right: element_type as name} returning expression: do
swift_function: firstElement
operator: {#prefix, precedence: 320}
done

to ‘middle’ {right: element_type as name} returning expression: do
swift_function: middleElement
operator: {#prefix, precedence: 320}
done

to ‘last’ {right: element_type as name} returning expression: do
swift_function: lastElement
operator: {#prefix, precedence: 320}
done

to ‘any’ {right: element_type as name} returning expression: do «TODO: what to call this? 'any'? 'some'? 'random'?»
swift_function: randomElement
operator: {#prefix, precedence: 320, aliases: [“some”, “random”]}
done

to ‘every’ {right: element_type as name} returning expression: do
swift_function: allElements
operator: {#prefix, precedence: 320, aliases: “all”}
done

«=== relative ordinal ===»

to ‘before’ {left: element_type as name, right: expression as expression} returning expression: do
swift_function: beforeElement
operator: {#infix, precedence: 320}
done

to ‘after’ {left: element_type as name, right: expression as expression} returning expression: do
swift_function: afterElement
operator: {#infix, precedence: 320}
done

«=== insertion location ====»

to ‘before’ {right: expression as expression} returning expression: do
swift_function: insertBefore
operator: {#prefix, precedence: 320}
done

to ‘after’ {right: expression as expression} returning expression: do
swift_function: insertAfter
operator: {#prefix, precedence: 320}
done

to ‘beginning’ returning expression: do
swift_function: insertAtBeginning
operator: {#atom, precedence: 320}
done

to ‘end’ returning expression: do
swift_function: insertAtEnd
operator: {#atom, precedence: 320}
done

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


