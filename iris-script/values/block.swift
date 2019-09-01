//
//  block.swift
//  iris-lang
//

import Foundation




struct Block: BoxedComplexValue { // caution: this does not capture lexical scope
        
    var description: String { // TO DO: hand off to pp; also need formatting hints from parser
        switch self.style {
        case .sentence(let t): return "\(self.data.map{$0.description}.joined(separator: ", "))\(t.content)"
        case .parenthesis: return "(\(self.data.map{$0.description}.joined(separator: ", ")))"
        case .custom(let def, let t, let d): return "\(def)\n\(self.data.map{$0.description}.joined(separator: "\(d)"))\n\(t)"
        }
    }
    
    typealias ArrayLiteralElement = Value

    static let nominalType: Coercion = asBlock
    
    enum Style { // TO DO: revise this as a single Block contains all contiguous sentences with all separator and terminator punctuation and linebreak info included, and the only thing that varies is how its boundaries are marked; therefore Style should be renamed Delimiters and .sentence(_) case should be renamed .none; for .custom(_) case we need to decide what it should hold (it may be that it uses start and end keywords, defined as .atom operators)
        case sentence(terminator: Token) // terminator may be .period, .query, .exclamation; TO DO: how should `!`/`?` modify behavior? (e.g. environment hooks)
        case parenthesis // TO DO: not sure about this; should parens be separate Group type which can hold blocks or other values?
        case custom(definition: String, terminator: String, delimiter: String) // TO DO: definition should probably provide formatter
    }
    
    // Q. would it be simpler just to encapsulate ExpressionSequence?
    
    let data: [Value]
    let style: Style // pretty-printer should format blocks as-per user preference
    
    init(_ data: [Value], style: Style) {
        self.data = data
        self.style = style
    }
    
    init(_ data: [Value]) {
        self.init(data, style: .parenthesis)
    }
    
    /*
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
    */
    
    
    func toValue(in scope: Scope, as coercion: Coercion) throws -> Value {
        return try self.toTYPE(in: scope, as: coercion)
    }
    
    func toTYPE<T>(in scope: Scope, as coercion: Coercion) throws -> T {
        //print("Block.toTYPE", self, "as", T.self, type(of:coercion))
        var result: Value = nullValue
        for value in self.data {
            // TO DO: what should we do with result?
            // TO DO: what about early return? (simplest is to chuck an error containing the return value, then catch that error outside this eval loop and unwrap the return value) although there are arguments for keeping the language strictly structured (i.e. no 'goto'-like behaviors: break/continue/return/etc) as it's easier to reason and manipulate a program as data if its structure describes flow
            result = try value.eval(in: scope, as: asAnything) // TO DO: `return VALUE` would throw a recoverable exception [and be caught here? or further up in HandlerProtocol? Q. what about `let foo = {some block}` idiom? should block be callable for this?]
        }

        
        if T.self is Value {
            return try coercion.coerce(value: result, in: scope) as! T
        } else {
            return try coercion.swiftCoerce(value: result, in: scope)
        }
    }
    
}
