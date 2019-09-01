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


func ofClause(attribute: Value, target value: Value, commandEnv: Scope, handlerEnv: Scope) throws -> Value { // TO DO: see TODO on AsAnything re. limiting scope of `didNothing` result
    // look up command's name in target
    if let command = attribute as? Command {
        if let selector = value.get(command.name) {
            if let handler = selector as? Handler {
                // command's arguments are evaled in commandEnv as normal (the Handler already contains a [strong]ref to its owner, )
                return try handler.call(with: command, in: commandEnv, as: asAnything)
            } else if command.arguments.isEmpty {
                return selector
            } // fall thru
        }
    }
    throw UnsupportedCoercionError(value: attribute, coercion: asHandler)
}


// TO DO: should element selection handlers be available at global level, or solely as 'methods' on collection-like values? e.g. `document at 1` at top level is a valid query, regardless of whether evaluating it succeeds or fails


func ofClause(attribute: Symbol,target value: Value,commandEnv: Scope,handlerEnv: Scope) throws -> Value {
    fatalError("Not yet implemented.")
}

func atSelector(elementType: Value,selectorData: Value,commandEnv: Scope,handlerEnv: Scope) throws -> Value {
    //fatalError("Not yet implemented.")
    print("at:", elementType, selectorData)
    return nullValue
}

func nameSelector(elementType: Symbol,selectorData: Value,commandEnv: Scope) throws -> Value {
    fatalError("Not yet implemented.")
}

func idSelector(elementType: Symbol,selectorData: Value,commandEnv: Scope) throws -> Value {
    fatalError("Not yet implemented.")
}

func whereSelector(elementType: Symbol,selectorData: Value,commandEnv: Scope,handlerEnv: Scope) throws -> Value {
    fatalError("Not yet implemented.")
}

func firstElement(right elementType: Symbol) -> Value {
    fatalError("Not yet implemented.")
}

func middleElement(right elementType: Symbol) -> Value {
    fatalError("Not yet implemented.")
}

func lastElement(right elementType: Symbol) -> Value {
    fatalError("Not yet implemented.")
}

func randomElement(right elementType: Symbol) -> Value {
    fatalError("Not yet implemented.")
}

func allElements(right elementType: Symbol) -> Value {
    fatalError("Not yet implemented.")
}

func beforeElement(left elementType: Symbol,right expression: Value) -> Value {
    fatalError("Not yet implemented.")
}

func afterElement(left elementType: Symbol,right expression: Value) -> Value {
    fatalError("Not yet implemented.")
}

func insertBefore(right expression: Value) -> Value {
    fatalError("Not yet implemented.")
}

func insertAfter(right expression: Value) -> Value {
    fatalError("Not yet implemented.")
}

func insertAtBeginning() -> Value {
    fatalError("Not yet implemented.")
}

func insertAtEnd() -> Value {
    fatalError("Not yet implemented.")
}
