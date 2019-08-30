//
//  query values.swift
//  iris-lang
//

import Foundation



/* selector forms:
 
 // pathological case is `foo of bar baz of fub`: `bar` would be command name, but is its argument `baz` or `baz of fub`? with explicit punctuation: `foo of bar {baz} of fub` or `foo of bar {baz of fub}`, which implies argument must bind tighter than `of` (otherwise we get `bar {{baz} of fub}`, which is clearly not what's intended); so how do other operators behave? e.g. `foo -bar` vs `foo - bar` would need to pretty print first case as `foo {-bar}`, i.e. whitespace around prefix/infix operators is significant (IIRC, this was already the case with entoli, with the added case of `foo-bar` being a single identifier); so how does `of` behave in implicit-punctuation labeled commands, e.g. `foo x of y of z bar: a of b baz: c of d` - this time we want `of` to bind tighter; the one saving grace is that `foo bar` vs `foo {bar}` could be parsed with different precedence, since parser can infer `{…}` to mean 'this is the entire argument'
 
 
 PROPERTY of VALUE
 
 ELEMENTS of VALUE
 
 ELEMENT at 1 of VALUE
 
 ELEMENT named "foo" of VALUE
 
 ELEMENT id "ABC123" of VALUE
 
 ELEMENT before/after ELEMENT
 
 ELEMENTS at X thru Y of VALUE
 
 ELEMENTS where TEST of VALUE
 
 first/middle/last/any/every ELEMENT of VALUE
 
 note: there is no `ELEMENT SELECTOR of …` shorthand for by-index/by-name reference forms (c.f. AppleScript's `word 1 of…`/`folder "Untitled" of…`) as that makes it difficult to determine the correct precedence when binding `CMD X of Y` without explicit parenthesis (Is it calling method CMD of Y with X as the command's argument? Or is it calling a global handler CMD with `X of Y` as its argument? Now try resolving `get element x of y`, where `get` and `element` are both right-associative unary commands. Sylvia-lang already tried to solve this, unsuccessfully.)
 
 */


func ofClause(attribute: Value, target: Value, commandEnv: Scope) throws -> Value { // TO DO: see TODO on AsAnything re. limiting scope of `didNothing` result
    // look up attribute (identifier/command) on value; all other evaluation (command arguments) is done in commandEnv as normal
    // TO DO: what scope? (value?); args will be evaled in command's scope except where handler uses as-is, in which case it has choice
    // this is all dubious
    if let command = attribute as? Command {
        if let selector = target.get(command.name) {
            if let handler = selector as? Handler {
                return try handler.call(with: command, in: commandEnv, as: asAnything)
            } else if command.arguments.isEmpty {
                return selector // TO DO: eval?
            } // fall thru
        }
    }
    throw UnsupportedCoercionError(value: attribute, coercion: asHandler)
}




func indexSelector(element_type: Symbol,selector_data: Value) throws -> Value {
    fatalError("Not yet implemented.")
}

func nameSelector(element_type: Symbol,selector_data: Value) throws -> Value {
    fatalError("Not yet implemented.")
}

func idSelector(element_type: Symbol,selector_data: Value) throws -> Value {
    fatalError("Not yet implemented.")
}

func testSelector(element_type: Symbol,selector_data: Value) throws -> Value {
    fatalError("Not yet implemented.")
}

func firstElement(element_type: Symbol) -> Value {
    fatalError("Not yet implemented.")
}

func middleElement(element_type: Symbol) -> Value {
    fatalError("Not yet implemented.")
}

func lastElement(element_type: Symbol) -> Value {
    fatalError("Not yet implemented.")
}

func randomElement(element_type: Symbol) -> Value {
    fatalError("Not yet implemented.")
}

func allElements(element_type: Symbol) -> Value {
    fatalError("Not yet implemented.")
}

func beforeElement(element_type: Symbol,expression: Value) -> Value {
    fatalError("Not yet implemented.")
}

func afterElement(element_type: Symbol,expression: Value) -> Value {
    fatalError("Not yet implemented.")
}

func insertBefore(expression: Value) -> Value {
    fatalError("Not yet implemented.")
}

func insertAfter(expression: Value) -> Value {
    fatalError("Not yet implemented.")
}

func insertAtBeginning() -> Value {
    fatalError("Not yet implemented.")
}

func insertAtEnd() -> Value {
    fatalError("Not yet implemented.")
}
