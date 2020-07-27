//
//  reference coercions.swift
//  iris-script
//

import Foundation


/*
struct AsQuery: SwiftCoercion {
    
    let name: Symbol = "query"
    
    typealias SwiftType = Query
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        guard let result = (try? asAnything.coerce(value: value, in: scope)) as? Query else {
            throw TypeCoercionError(value: value, coercion: self)
        }
        return result
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = (try? asAnything.coerce(value: value, in: scope)) as? Query else {
            throw TypeCoercionError(value: value, coercion: self)
        }
        return result.desc
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        fatalError() // TO DO: need to capture appData in scope for use here
    }
}


let asQuery = AsQuery()
*/


typealias AsReference = AsComplex<Reference>

let asReference = AsReference(name: "reference")

typealias AsInsertionLocation = AsComplex<InsertionLocation>

let asInsertionLocation = AsInsertionLocation(name: "insertion_location")

typealias AsTestClause = AsComplex<TestClause>

let asTestClause = AsTestClause(name: "whose_clause")

