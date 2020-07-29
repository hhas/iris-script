//
//  handler glue.swift
//  iris-glue
//

import Foundation
import iris



public struct HandlerGlue {
    
    public var description: String { return "«HandlerGlue \(self.interface) \(self.canError), \(self.useScopes), \(String(describing: self.swiftFunction)), \(String(describing: self.operatorSyntax))»"}
        
    // TO DO: also extract user documentation (from annotations); Q. where should user docs go? may be an idea to put them in separate data file that is loaded as needed (or just use the native glue def itself, assuming it isn't too slow to parse)
    typealias Parameter = (name: String, binding: String, coercion: String)
    typealias SwiftFunction = (name: String, params: [String])
    typealias OperatorSyntax = (pattern: [iris.Pattern], precedence: Int, associate: Associativity, reducefunc: String?)
    
    let interface: HandlerInterface
    
    var name: String { return self.interface.name.label }
    var parameters: [Parameter] {
        return self.interface.parameters.map{($0.label.label, $0.binding.label, $0.coercion.swiftLiteralDescription)}
    }
    var result: String { return self.interface.result.swiftLiteralDescription } // coercion name
    
    let canError: Bool
    let useScopes: [String] // commandEnv, handlerEnv // TO DO: any use-cases for per-invocation sub-env?
    let swiftFunction: SwiftFunction? // if different to native names
    let operatorSyntax: OperatorSyntax?
}

