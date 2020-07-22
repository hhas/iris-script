//
//  pattern value.swift
//  iris-glue
//

import Foundation
import iris


// TO DO: move parameter tuples from interface_ to type_

// TO DO: how easy/hard to implement general-purpose reducefunc that uses pattern definition to reduce [most] patterns? or are we as well to determine which hardcoded reducer to use for common patterns during glue generation, based on pattern?


public class PatternValue: OpaqueValue<iris.Pattern> {

    public override var description: String { return "«pattern: \(self.data)»" }

}


// TO DO: need to support coercing list of pattern values to PatternValue(Pattern.sequence(…))

let asPatternValue = AsComplex<PatternValue>(name: "pattern")


/*
struct AsScope: SwiftCoercion { // for now, this is purely to enable Swift func stubs to be generated with correct commandEnv/handlerEnv param types
    
    var swiftLiteralDescription: String { return "asScope" }
    
    let name: Symbol = "scope"
    
    typealias SwiftType = Scope
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        fatalError("Not yet implemented.")
    }
    
    func box(value: Scope, in scope: Scope) -> Value {
        fatalError("Not yet implemented.")
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        fatalError("Not yet implemented.")
    }
}

let asScope = AsScope()
*/
