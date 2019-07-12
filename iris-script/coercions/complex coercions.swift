//
//  complex coercions.swift
//  iris-lang
//

import Foundation

// TO DO: what would it take to replace current double-dispatch implementation with a [global] coercion table?


// TO DO: this is a little dicey as it assumes values cannot coerce to complex types; would be safer to implement Value.toComplex(in:as:), with the default implementation throwing if not same type (this allows values to implement their own toComplex where appropriate)

struct AsComplex<T: Value>: SwiftCoercion { // T must be concrete struct or class; abstract protocols aren't accepted
    
    let name: Name
    
    typealias SwiftType = T
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = try value.swiftEval(in: scope, as: asAnything) as? SwiftType else {
            throw UnsupportedCoercionError(value: value, coercion: self)
        }
        return result
    }
}


struct AsName: SwiftCoercion {
    
    var name: Name { return Name("name") } // avoid creating cycle between Name and AsName when initializing them
    
    typealias SwiftType = Name
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        if !(value is Name) { throw UnsupportedCoercionError(value: value, coercion: self) }
        return value
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let name = value as? Name else { throw UnsupportedCoercionError(value: value, coercion: self) }
        return name
    }
}


struct AsHandler: SwiftCoercion { // (can't use AsComplex<Handler> as Handler isn't concrete type; however, we'll need some custom implementation anyway)
    
    let name: Name = "handler"
    
    typealias SwiftType = Handler
    
    // TO DO: when should handlers capture their lexical scope? and when should that capture be strongref vs weakref?
    
    func coerce(value: Value, in scope: Scope) throws -> Value {
        if !(value is Handler) { throw UnsupportedCoercionError(value: value, coercion: self) }
        // TO DO: return strongrefd handler?
        return value
    }
    
    func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = value as? SwiftType else { throw UnsupportedCoercionError(value: value, coercion: self) }
        // TO DO: return strongrefd handler?
        return result
    }
}


// TO DO (complex types generally only coerce to Any or Self)
let asCommand = AsComplex<Command>(name: "command")
let asName = AsName()
let asHandlerInterface = AsComplex<HandlerInterface>(name: "handler_interface") // TO DO: handler interface can be coerced to/from Record
let asHandler = AsHandler()
let asBlock = AsComplex<Block>(name: "block")



struct AsIs: SwiftCoercion {
    
    let name: Name = "anything"
    
    typealias SwiftType = Value
    
    func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        return value
    }
}

let asIs = AsIs()



extension Bool: Value {
    
    var nominalType: Coercion { return asBool }
    
    func toBool(in scope: Scope, as coercion: Coercion) throws -> Bool {
        return self
    }
}

let asBool = AsComplex<Bool>(name: "boolean")






struct AsCoercion: SwiftCoercion {
    
    let name: Name = "coercion"
    
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
    
    let name: Name = "error"
    
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



// asLiteralCast -- takes `as {left: Name, right: Coercion}` command and decomposes it? or should parseHandlerInterface() deal with `BINDING as COERCION` pattern itself?


// TO DO: LiteralCoercion? (this could be a single/generic struct, as all it does is typecheck the given value… although there is a caveat as some values eval first… another reason to lose the initial Value.eval call)
