//
//  block.swift
//  iris-lang
//

import Foundation



public class Block: BoxedCollectionValue { // caution: this does not capture lexical scope
    
    // TO DO: what about preserving user's punctuation?
        
    public var description: String { // TO DO: hand off to pp; also need formatting hints from parser (e.g. whether to use linbreaks and/or punctuation between exprs)
        return "(\(self.data.map{$0.description}.joined(separator: ", ")))" // unsugared representation
    // TO DO: move sugared representation to PP
    //    if let d = self.patternDefinition, case .keyword(let n1) = d.pattern.first, case .keyword(let n2) = //d.pattern.last {
    //        return "\(n1.name.label)\(self.data.map{"\n\t\($0)"}.joined(separator: ""))\n\(n2.name.label)"
    //    } else {
    //        return "(\n\t\(self.data.map{$0.description}.joined(separator: ",\n\t"))\n)" // TO DO: default block representation is a parenthesized sequence of (comma- and/or linebreak-delimited?) exprs
    //    }
    }
    
    public typealias ArrayLiteralElement = Value
    public static let nominalType: Coercion = asBlock
    
    let operatorDefinition: PatternMatch? // TO DO: make this part of optional annotation metadata and standardize annotation API and types across Blocks and Commands (Q. what about lists and records?)
    
    public let data: [Value]
    
    public required init(_ data: [Value], patternDefinition: PatternMatch?) {
        self.data = data
        self.operatorDefinition = patternDefinition
    }
    public required convenience init(_ data: [Value]) {
        self.init(data, patternDefinition: nil)
    }
    
    public __consuming func makeIterator() -> IndexingIterator<[Value]> {
        return self.data.makeIterator()
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
    
    
    public func toValue(in scope: Scope, as coercion: Coercion) throws -> Value {
        print("\(type(of:self)).toValue(as:\(coercion))")
        return try self.toTYPE(in: scope, as: coercion)
    }
    
    public func toTYPE<T>(in scope: Scope, as coercion: Coercion) throws -> T {
        print("Block.toTYPE", self, "as", T.self, type(of:coercion))
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

public typealias AbstractSyntaxTree = Block

/*
class ScriptAST: Block {

    override var description: String {
        return self.data.map{$0.description}.joined(separator: ",\n")
    }
    
}
*/
