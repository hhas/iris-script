//
//  complex coercions.swift
//  iris-lang
//

import Foundation

// TO DO: what would it take to replace current double-dispatch implementation with a [global] coercion table?


// TO DO: this is a little dicey as it assumes values cannot coerce to complex types; would be safer to implement Value.toComplex(in:as:), with the default implementation throwing if not same type (this allows values to implement their own toComplex where appropriate)

// TO DO: need to rethink AsComplex, as it doesn't lend itself to code generation; for now, assume there is always a public `asTYPE` constant defined where TYPE T

struct AsComplex<T: Value>: SwiftCoercion { // T must be concrete struct or class; abstract protocols aren't accepted
    
    var swiftLiteralDescription: String { return "as\(T.self)" }
    
    let name: Symbol
    
    typealias SwiftType = T
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        // TO DO: this has issues
        guard let result = try asValue.unbox(value: value, in: scope) as? SwiftType else {
        //guard let result = try value.swiftEval(in: scope, as: asAnything) as? SwiftType else {
            throw UnsupportedCoercionError(value: value, coercion: self)
        }
        return result
    }
}


struct AsSymbol: SwiftCoercion {
    
    var name: Symbol { return Symbol("symbol") } // TO DO: what to call this datatype; "name"/"symbol"/"hashtag"/…? (AS jargon uses "class" and "constant", both of which are misleading)
    
    typealias SwiftType = Symbol
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        guard let result = try asValue.coerce(value: value, in: scope) as? Symbol else { throw UnsupportedCoercionError(value: value, coercion: self) }
        return result
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = try asValue.unbox(value: value, in: scope) as? Symbol else { throw UnsupportedCoercionError(value: value, coercion: self) }
        return result
    }
}


// TO DO (complex types generally only coerce to Any or Self)
let asCommand = AsComplex<Command>(name: "command")
let asSymbol = AsSymbol()


let asBlock = AsComplex<Block>(name: "block")

let asPair = AsComplex<Pair>(name: "pair")





struct AsHashableValue: SwiftCoercion {
    
    let name: Symbol = "key"
    
    typealias SwiftType = HashableValue
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = try? asAnything.coerce(value: value, in: scope) as? HashableValue else {
            throw UnsupportedCoercionError(value: value, coercion: self)
        }
        return result
    }
    
    // TO DO: these should be supplied by SwiftCoercion extension, but aren't; why?
    func coerce(value: Value, in scope: Scope) throws -> Value {
        return try self.unbox(value: value, in: scope)
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}
let asHashableValue = AsHashableValue()



struct AsIs: SwiftCoercion {
    
    var swiftLiteralDescription: String { return "asIs" }

    let name: Symbol = "anything"
    
    typealias SwiftType = Value
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        return value
    }
}

let asIs = AsIs()



extension Bool: Value {
    
    var swiftLiteralDescription: String { return String(self) }
    
    static let nominalType: Coercion = asBool 
    
    func toBool(in scope: Scope, as coercion: Coercion) throws -> Bool {
        return self
    }
}

let asBool = AsComplex<Bool>(name: "boolean")







struct AsCoercion: SwiftCoercion {
    
    let name: Symbol = "coercion"
    
    typealias SwiftType = Coercion
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        if !(value is Coercion) { throw UnsupportedCoercionError(value: value, coercion: self) }
        return value
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = value as? SwiftType else { throw UnsupportedCoercionError(value: value, coercion: self) }
        return result
    }
}


let asCoercion = AsCoercion() // can't use AsComplex<Coercion> as generics require concrete types, not protocols




//let asRecord = AsComplex<Record>(name: "record") // TO DO: what about AsRecord with specified fields




struct AsError: SwiftCoercion {
    
    let name: Symbol = "error"
    
    typealias SwiftType = NativeError
    
    // TO DO: why isn't SwiftCoercion extension adding coerce and box methods?
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        return try self.unbox(value: value, in: scope)
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
  
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = try value.swiftEval(in: scope, as: asAnything) as? SwiftType else {
            throw UnsupportedCoercionError(value: value, coercion: self)
        }
        return result
    }
}

let asError = AsError()



// asLiteralCast -- takes `as {left: Symbol, right: Coercion}` command and decomposes it? or should parseHandlerInterface() deal with `BINDING as COERCION` pattern itself?


// TO DO: LiteralCoercion? (this could be a single/generic struct, as all it does is typecheck the given value… although there is a caveat as some values eval first… another reason to lose the initial Value.eval call)
