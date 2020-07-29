//
//  reference coercions.swift
//  iris-script
//

import Foundation


/*
struct AsQuery: SwiftCoercion {
    
    let name: Symbol = "query"
    
    typealias SwiftType = Query
    
    func coerce(_ value: Value, in scope: Scope) throws -> Value {
        guard let result = (try? asAnything.coerce(value, in: scope)) as? Query else {
            throw TypeCoercionError(value: value, coercion: self)
        }
        return result
    }
    
    func coerce(_ value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = (try? asAnything.coerce(value, in: scope)) as? Query else {
            throw TypeCoercionError(value: value, coercion: self)
        }
        return result.desc
    }
    
    func wrap(_ value: SwiftType, in scope: Scope) -> Value {
        fatalError() // TO DO: need to capture appData in scope for use here
    }
}


let asQuery = AsQuery()
*/


typealias AsReference = TypeMap<Reference>

let asReference = AsReference("reference", "asReference")

typealias AsInsertionLocation = TypeMap<InsertionLocation>

let asInsertionLocation = AsInsertionLocation("insertion_reference", "asInsertionLocation")

typealias AsTestClause = TypeMap<TestClause>

let asTestClause = AsTestClause("test_reference", "asTestClause")

