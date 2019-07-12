//
//  access protocols.swift
//  iris-script
//

import Foundation


protocol Accessor { // slot access // TO DO: adopt Value protocol?
    
    //func get(_ key: Symbol, delegate: Scope?) -> Value?
    func get(_ name: Name) -> Value?
}


// note that when evaluating chunk expressions against values, e.g. `item 1 of [1,2,3,4,5]`, this is typically performed as `get(#item).at(1)`; the `get` method returning a FORMSelector struct that knows how to access elements of the underlying collection; e.g. for List, `get(#item)` can return self; `SelectableByIndex` being a trait of List struct; in the case of String, `get()` might accept `#character` (returns self), `#word` (returns struct that knows how to slice string at word boundaries), `#paragraph` (returns struct that knows how to slice string at linebreaks); if following established AppleScript/AEOM idioms, we'll also need `#text_range` for slicing (since `get characters 1 thru 5 of STRING` returns list of string in AS), however, it may make more sense to discard that (`text 1 thru 5 of STRING` it was always counterintuitive and inconsistently supported, and also lacks separate singular+plural forms) and have `characters 1 thru 5 of STRING` return sliced string by default ('best type'), with explicit coercion `(characters 1 thru 5 of STRING) as list {of: string}` providing the alternate representation (and much less useful) list-of-single-characters; conversely `words/paragraphs 1 thru 5` would return list of string by default, unless explicit `as string` coercion is applied [note that this coercion must be applied during slicing; the non-lossy coercion rule means an existing list of string[s] cannot be coerced to string, it can only be joined by explicit command]

protocol Mutator: Accessor {
    
    func set(_ name: Name, to value: Value) throws
}

protocol Scope: class, Accessor {
    
    func subscope() -> Scope // TO DO: `Self` causes subclasses to barf
    
}

protocol MutableScope: Scope, Mutator {
    
    func set(_ name: Name, to value: Value) throws // TO DO: delegate? thisFrameOnly?
    
    func subscope(withWriteBarrier isLocked: Bool) -> MutableScope
}

extension MutableScope {
    func subscope() -> Scope { return self.subscope(withWriteBarrier: true) }
}
