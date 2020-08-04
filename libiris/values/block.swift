//
//  block.swift
//  libiris
//

import Foundation



public class Block: BoxedCollectionValue, LiteralConvertible, SelfEvaluatingValue { // caution: this does not capture lexical scope
    
    // TO DO: what about preserving user's punctuation?
    
    public var swiftLiteralDescription: String {
        return "Block([\(self.data.map(literal).joined(separator: ", "))])"
    }
        
    public var literalDescription: String { // TO DO: hand off to pp; also need formatting hints from parser (e.g. whether to use linbreaks and/or punctuation between exprs)
        return "(\(self.data.map(literal).joined(separator: ", ")))" // unsugared representation
    // TO DO: move sugared representation to PP
    //    if let d = self.patternDefinition, case .keyword(let n1) = d.pattern.first, case .keyword(let n2) = //d.pattern.last {
    //        return "\(n1.name.label)\(self.data.map{"\n\t\($0)"}.joined(separator: ""))\n\(n2.name.label)"
    //    } else {
    //        return "(\n\t\(self.data.map{$0.description}.joined(separator: ",\n\t"))\n)" // TO DO: default block representation is a parenthesized sequence of (comma- and/or linebreak-delimited?) exprs
    //    }
    }
    
    public typealias ArrayLiteralElement = Value
    public static let nominalType: NativeCoercion = asBlock.nativeCoercion
    
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
    
    public func eval<T: SwiftCoercion>(in scope: Scope, as coercion: T) throws -> T.SwiftType {
       // print("Block.eval", self, "as", T.self)
        //var result: Value = nullValue
        for value in self.data.dropLast() { // self.data is zero or more exprs to evaluate; note that the result of each expr is normally discarded
            if let expr = value as? SelfEvaluatingValue {
                // TO DO: what about early return? (simplest is for `return EXPR?` to throw an EarlyReturn error containing the EXPR to be evaluated, then catch it here and eval that expr with coercion T; problem is that only breaks us out of the current block, not the handler’s block; if we want to break out of the current handler then the early return error must be trapped by the handler itself)
                let _ = try expr.eval(in: scope, as: asAnything)
            }
        }
        return try coercion.coerce(self.data.last ?? nullValue, in: scope)
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
