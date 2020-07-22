//
//  complex coercions.swift
//  iris-lang
//

import Foundation

// TO DO: what would it take to replace current double-dispatch implementation with a [global] coercion table?


// TO DO: this is a little dicey as it assumes values cannot coerce to complex types; would be safer to implement Value.toComplex(in:as:), with the default implementation throwing if not same type (this allows values to implement their own toComplex where appropriate)

// TO DO: need to rethink AsComplex, as it doesn't lend itself to code generation; for now, assume there is always a public `asTYPE` constant defined where TYPE T

public struct AsComplex<T: Value>: SwiftCoercion { // T must be concrete struct or class; abstract protocols aren't accepted
    
    public var swiftLiteralDescription: String { return "as\(T.self)" }
    
    public let name: Symbol
    
    public typealias SwiftType = T
    
    public init(name: Symbol) {
        self.name = name
    }
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        // TO DO: this has issues
        guard let result = try asValue.unbox(value: value, in: scope) as? SwiftType else {
        //guard let result = try value.swiftEval(in: scope, as: asAnything) as? SwiftType else {
            throw UnsupportedCoercionError(value: value, coercion: self)
        }
        return result
    }
}


public struct AsSymbol: SwiftCoercion {
    
    public var name: Symbol { return Symbol("symbol") } // TO DO: what to call this datatype; "name"/"symbol"/"hashtag"/…? (AS jargon uses "class" and "constant", both of which are misleading)
    
    public typealias SwiftType = Symbol
    
    public init() {}
    
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        guard let result = try asValue.coerce(value: value, in: scope) as? Symbol else { throw UnsupportedCoercionError(value: value, coercion: self) }
        return result
    }
    
    public func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = try asValue.unbox(value: value, in: scope) as? Symbol else { throw UnsupportedCoercionError(value: value, coercion: self) }
        return result
    }
}


// TO DO (complex types generally only coerce to Any or Self)
public let asCommand = AsComplex<Command>(name: "command")
public let asSymbol = AsSymbol()


public let asBlock = AsComplex<Block>(name: "block")

//let asPair = AsComplex<Pair>(name: "pair")





public struct AsHashableValue: SwiftCoercion {
    
    public let name: Symbol = "key"
    
    public typealias SwiftType = HashableValue
    
    public init() {}
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = try? asAnything.coerce(value: value, in: scope) as? HashableValue else {
            throw UnsupportedCoercionError(value: value, coercion: self)
        }
        return result
    }
    
    // TO DO: these should be supplied by SwiftCoercion extension, but aren't; why?
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        return try self.unbox(value: value, in: scope)
    }
    
    public func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
}
public let asHashableValue = AsHashableValue()



public struct AsIs: SwiftCoercion {
    
    public var swiftLiteralDescription: String { return "asIs" }

    public let name: Symbol = "expression"
    
    public init() {}
    
    public typealias SwiftType = Value
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        return value
    }
}

public let asIs = AsIs()



public let asBool = AsComplex<Bool>(name: "boolean")







public struct AsCoercion: SwiftCoercion {
    
    public let name: Symbol = "coercion"
    
    public typealias SwiftType = Coercion
    
    public init() {}
    
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        if !(value is Coercion) { throw UnsupportedCoercionError(value: value, coercion: self) }
        return value
    }
    
    public func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
    
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = (try? asAnything.coerce(value: value, in: scope)) as? SwiftType else {
            throw UnsupportedCoercionError(value: value, coercion: self)
        }
        return result
    }
}


public let asCoercion = AsCoercion() // can't use AsComplex<Coercion> as generics require concrete types, not protocols




//let asRecord = AsComplex<Record>(name: "record") // TO DO: what about AsRecord with specified fields




public struct AsError: SwiftCoercion {
    
    public let name: Symbol = "error"
    
    public typealias SwiftType = NativeError
    
    public init() {}
    
    // TO DO: why isn't SwiftCoercion extension adding coerce and box methods?
    
    public func coerce(value: Value, in scope: Scope) throws -> Value {
        return try self.unbox(value: value, in: scope)
    }
    
    public func box(value: SwiftType, in scope: Scope) -> Value {
        return value
    }
  
    public func unbox(value: Value, in scope: Scope) throws -> SwiftType {
        guard let result = try value.swiftEval(in: scope, as: asAnything) as? SwiftType else {
            throw UnsupportedCoercionError(value: value, coercion: self)
        }
        return result
    }
}

public let asError = AsError()



// asLiteralCast -- takes `as {left: Symbol, right: Coercion}` command and decomposes it? or should parseHandlerInterface() deal with `BINDING as COERCION` pattern itself?


// TO DO: LiteralCoercion? (this could be a single/generic struct, as all it does is typecheck the given value… although there is a caveat as some values eval first… another reason to lose the initial Value.eval call)
