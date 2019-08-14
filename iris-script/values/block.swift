//
//  block.swift
//  iris-lang
//

import Foundation




struct Block: ComplexValue { // caution: this does not capture lexical scope
    
    var description: String { // TO DO: hand off to pp
        switch self.style {
        case .sentence(let t): return "\(self.data.map{$0.description}.joined(separator: ", "))\(t)"
        case .parenthesis: return "(\(self.data.map{"\n\t\($0.description)"}.joined(separator: ""))\n)"
        case .custom(let def, let t, let d): return "\(def.name)\n\(self.data.map{$0.description}.joined(separator: "\(d)")))\(t)"
        }
    }
    
    typealias ArrayLiteralElement = Value

    let nominalType: Coercion = asBlock
    
    enum Style {
        case sentence(terminator: Token) // terminator may be .period, .query, .exclamation; TO DO: how should `!`/`?` modify behavior? (e.g. environment hooks)
        case parenthesis // TO DO: not sure about this; should parens be separate Group type which can hold blocks or other values?
        case custom(definition: OperatorDefinition, terminator: Token, delimiter: Token) // TO DO: definition should probably provide formatter
    }
    
    let data: [Value]
    let style: Style // pretty-printer should format blocks as-per user preference
    
    init(_ data: [Value], style: Style = .parenthesis) {
        self.data = data
        self.style = style
    }
    
    func eval(in scope: Scope, as coercion: Coercion) throws -> Value {
        // TO DO: how to customize evaluation behavior when `?`/`!` modifiers are used
        var result: Value = nullValue
        for value in self.data {
            // TO DO: what should we do with result?
            // TO DO: what about early return? (simplest is to chuck an error containing the return value, then catch that error outside this eval loop and unwrap the return value) although there are arguments for keeping the language strictly structured (i.e. no 'goto'-like behaviors: break/continue/return/etc) as it's easier to reason and manipulate a program as data if its structure describes flow
            result = try value.eval(in: scope, as: asAnything) // TO DO: `return VALUE` would throw a recoverable exception [and be caught here? or further up in HandlerProtocol? Q. what about `let foo = {some block}` idiom? should block be callable for this?]
        }
        return try coercion.coerce(value: result, in: scope)
    }
    func swiftEval<T: SwiftCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
        // bit clumsy (also unnecessary if we enforce structured programming, as we can just process the last expression in self.data separately
        return try coercion.unbox(value: self.eval(in: scope, as: coercion), in: scope)
    }
    
}
