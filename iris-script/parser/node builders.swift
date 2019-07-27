//
//  node builders.swift
//  iris-script
//

import Foundation



protocol NodeBuilder { // rather than a single token stack, onto which all tokens are shifted until a reduction can be made, have a stack of .token(Token)/.builder(NodeBuilder), where List/Record/Block builders are incrementally populated by individual expr reductions, with the final reduction wrapping the populated array/dict in the corresponding Value
    
    associatedtype Element
    
    mutating func push(_: Element)
    
    // TO DO: what to do with accummulated items if the list/record/block is not correctly closed
    
    func reduce() -> Value
}


// CommandBuilder?


struct ListBuilder: NodeBuilder { // `[`
    
    typealias Element = Value
    
    private var items = [Element]()
    
    mutating func push(_ value: Element) {
        self.items.append(value)
    }
    
    func reduce() -> Value {
        return OrderedList(self.items) // note: there's no easy way to fold `LIST_LITERAL as unique_list` at parse time, since `as` is a library-defined operator, so we'll need to leave 'as' command to convert the underlying Array<Value> to Set<Value> on first evaluation and memoize it (assuming common usage patterns where all list items are themselves literals; that just leaves the pathological case of a large set literal containing one or more commands, though with a bit of work even that should be reducible to a Set representation)
    }
}


struct KeyedListBuilder: NodeBuilder { // `[…:`
    
    typealias Key = KeyedList.Key
    typealias Element = (Key, Value)
    
    private var items = [Key: Value]()
    
    mutating func push(_ value: Element) {
        self.items[value.0] = value.1
    }
    
    func reduce() -> Value {
        return KeyedList(self.items)
    }
}


struct RecordBuilder: NodeBuilder { // `[…:`
    
    typealias Element = Record.Field
    
    private var items = [Element]()
    
    mutating func push(_ value: Element) {
        self.items.append(value)
    }
    
    func reduce() -> Value {
        return try! Record(self.items) // TO DO: simplest to defer duplicate field errors to eval time (for which we need a Value that always throws the captured error on eval); alternatively, we could have reduce() throw, although that doesn't seem quite right either (again, bear in mind that all syntax errors should be encapsulated within AST via 'fixers', allowing script to eval at least partially)
    }
}


struct BlockBuilder: NodeBuilder { // `(`, or `,`, or `do` operator; Q. this assumes an expr sequence; should it reduce to parenthesized value if single expr? (that in turn may be reduced further if expr is directly annotatable, or if it's an operator with non-elective [predecence-overriding] parens, e.g. `(1+2)*3` reduces to `'*'{'+'{1,2},3}`, whereas `1+(2*3)` needs to annotate '*' command so pp knows to add parens as per user's preference, while `1+(2)*3` should arguably discard the parens and `(foo)+2*3` probably wants to keep them to ensure `+2*3` is not mistaken for argument)
    
    typealias Element = Value
    
    private var items = [Element]()
    
    let style: Block.Style
    
    mutating func push(_ value: Element) {
        self.items.append(value)
    }
    
    func reduce() -> Value {
        return self.items.count == 1 ? self.items[0] : Block(self.items) // TO DO: this is incomplete and will not handle parens correctly; see above
    }
}

