//
//  element range.swift
//  iris-script
//
//  Created by Hamish Sanderson on 29/08/2019.
//

import Foundation




struct ElementRange: Value {
    
    var description: String { return "(‘thru’ {\(self.start), \(self.stop)})" }
    
    static let nominalType: Coercion = asRange 
    
    let start: Value
    let stop: Value
    
    init(from start: Value, to stop: Value) { // TO DO: any way to improve static type? (one option would be to define separate range subclasses for numeric sequence vs reference ranges; current context would need first option to supply 'thru' handler so that List can return Range that takes Ints while Reference can return Range that takes) // TO DO: add `step` argument? (this'd only be relevant when defining native numeric sequences; it's not supported by AE IPC)
        self.start = start
        self.stop = stop
    }
    
    // TO DO: implement asList() which returns numeric sequence if start and stop are integers (eventually want to implement Value.asIterable that returns a generator, which is more efficient than building a new list object when iterating)
}



// coercion

typealias AsRange = AsLiteral<ElementRange>

let asRange = AsRange()


