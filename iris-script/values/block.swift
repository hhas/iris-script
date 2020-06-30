//
//  block.swift
//  iris-lang
//

import Foundation


// TO DO: sentence blocks are intractable, so get rid of those: comma, period, query, exclamation marks should all act as expr delimiter and make no structural difference to code; only difference is when using them as runtime flags to control stepping/prompting/etc (e.g. proceed on `,` but hold on `.` [c.f. debugger breakpoint], introspect current state on `?`, request confirmation of unsafe operation on `!`); these flags can be set via annotations, e.g. `«period: wait 5sec»`, and the annotations themselves may contain commands to be evaled in isolated 'debugger' environment with managed access to runtime env



struct Block: BoxedComplexValue { // caution: this does not capture lexical scope
    
    // TO DO: what about preserving user's punctuation?
        
    var description: String { // TO DO: hand off to pp; also need formatting hints from parser (e.g. whether to use linbreaks and/or punctuation between exprs)
        if let d = self.operatorDefinition, case .keyword(let n1) = d.pattern.first, case .keyword(let n2) = d.pattern.last {
            return "\(n1.name.label)\(self.data.map{"\n\t\($0)"}.joined(separator: ""))\n\(n2.name.label)"
        } else {
            return "(\n\t\(self.data.map{$0.description}.joined(separator: ",\n\t"))\n)"
        }
    }
    
    typealias ArrayLiteralElement = Value

    static let nominalType: Coercion = asBlock
    
    let operatorDefinition: OperatorDefinition?
    
    // Q. would it be simpler just to encapsulate ExpressionSequence?
    
    let data: [Value]
    
    init(_ data: [Value], operatorDefinition: OperatorDefinition?) {
        self.data = data
        self.operatorDefinition = operatorDefinition
    }
    init(_ data: [Value]) {
        self.init(data, operatorDefinition: nil)
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
