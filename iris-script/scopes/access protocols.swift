//
//  access protocols.swift
//  iris-script
//

import Foundation


typealias AttributedValue = Value & Accessor


protocol Accessor { // slot access // TO DO: adopt Value protocol?
    
    func get(_ name: Symbol) -> Value?
}


// note that when evaluating chunk expressions against values, e.g. `item 1 of [1,2,3,4,5]`, this is typically performed as `get(#item).at(1)`; the `get` method returning a FORMSelector struct that knows how to access elements of the underlying collection; e.g. for OrderedList, `get(#item)` can return self; `SelectableByIndex` being a trait of OrderedList struct; in the case of String, `get()` might accept `#character` (returns self), `#word` (returns struct that knows how to slice string at word boundaries), `#paragraph` (returns struct that knows how to slice string at linebreaks); if following established AppleScript/AEOM idioms, we'll also need `#text_range` for slicing (since `get characters 1 thru 5 of STRING` returns list of string in AS), however, it may make more sense to discard that (`text 1 thru 5 of STRING` it was always counterintuitive and inconsistently supported, and also lacks separate singular+plural forms) and have `characters 1 thru 5 of STRING` return sliced string by default ('best type'), with explicit coercion `(characters 1 thru 5 of STRING) as list {of: string}` providing the alternate representation (and much less useful) list-of-single-characters; conversely `words/paragraphs 1 thru 5` would return list of string by default, unless explicit `as string` coercion is applied [note that this coercion must be applied during slicing; the non-lossy coercion rule means an existing list of string[s] cannot be coerced to string, it can only be joined by explicit command]

protocol Mutator: Accessor {
    
    func set(_ name: Symbol, to value: Value) throws
}

protocol Scope: class, Accessor { // TO DO: can/should we move `class` further down? some frequently instantiated scopes, e.g. `TellTarget`, do not hold state directly, but merely delegate lookups to other scopes, so making them class instances is of no benefit (need to check original rationale for making Scope a class-only protocol)
    
    func subscope() -> Scope // TO DO: `Self` causes subclasses to barf
    
}

protocol MutableScope: Scope, Mutator {
    
    func set(_ name: Symbol, to value: Value) throws // TO DO: delegate? thisFrameOnly?
    
    func subscope(withWriteBarrier isLocked: Bool) -> MutableScope
}

extension MutableScope {
    func subscope() -> Scope { return self.subscope(withWriteBarrier: true) }
}

