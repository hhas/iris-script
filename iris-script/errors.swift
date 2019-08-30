//
//  errors.swift
//  iris-lang
//

// TO DO: localization

import Foundation


protocol NativeError: Value, Error {
    
}

extension NativeError {
    
    static var nominalType: Coercion { return asError }

    func from(_ parent: Error) -> Error {
        return ChainedError(error: self, parent: parent)
    }
}


struct ChainedError: NativeError { // problem with this approach is that it requires unwrapping to determine actual error type (defining a `parent:Error?` slot on every native error struct avoids this problem, but gets messy); main reason for chained exceptions is to construct native stack traces from chained HandlerError instances, so it might be simpler to limit error chaining support to HandlerError
    
    var description: String { return "\(self.error)\n• \(self.parent)" }
    
    var error: Error
    var parent: Error
}


// TO DO: error chaining

// TO DO: base protocol for all native errors (this should extend Value protocol)


struct NotYetImplementedError: NativeError {
    
    internal(set) public var parent: Error?
    
    var description: String { return "`\(self._function)` is not yet implemented." }
    
    private let _function: String
    
    init(_ _function: String = #function) {
        self._function = _function
    }
}


struct MalformedRecordError: NativeError {
    
    var description: String { return "Found duplicate name `\(self.name.label)` in record \(self.fields)" } // TO DO: format
    
    let name: Symbol
    let fields: [Record.Field]
    
    init(name: Symbol, in fields: [Record.Field]) {
        self.name = name
        self.fields = fields
    }
}


// Environment errors

struct UnknownNameError: NativeError {
    
    var description: String { return "Can’t find `\(self.name.label)` in \(self.scope)" }
    
    let name: Symbol
    let scope: Accessor
    
    init(name: Symbol, in scope: Accessor) {
        self.name = name
        self.scope = scope
    }
}


struct ImmutableScopeError: NativeError {
    
    var description: String { return "Can’t modify value named `\(self.name.label)` in immutable \(self.scope)" }
    
    let name: Symbol
    let scope: Accessor
    
    init(name: Symbol, in scope: Accessor) {
        self.name = name
        self.scope = scope
    }
}

struct ExistingNameError: NativeError {
    
    var description: String { return "Can’t replace existing value named `\(self.name.label)` in \(self.scope)" }
    
    let name: Symbol
    let scope: Accessor
    
    init(name: Symbol, in scope: Accessor) {
        self.name = name
        self.scope = scope
    }
}

struct ImmutableValueError: NativeError {
    
    var description: String { return "Can’t modify immutable value named `\(self.name.label)` in \(self.scope)" }
    
    let name: Symbol
    let scope: Accessor
    
    init(name: Symbol, in scope: Accessor) {
        self.name = name
        self.scope = scope
    }
}


// TO DO: when to use enum vs struct? (e.g. probably makes sense to group all coercion errors except null coercion as a single struct, with enum to indicate exact issue)

protocol CoercionError: NativeError {
    
    var value: Value { get }
    var coercion: Coercion { get }
    
}

extension CoercionError {
    
    var description: String {
        return "Can’t coerce the following \(self.value.nominalType) value to \(self.coercion): `\(self.value)`"
    }
}
    
struct NullCoercionError: CoercionError { // value is `nothing`
    
    let value: Value
    let coercion: Coercion
}

struct UnsupportedCoercionError: CoercionError { // cannot coerce value to specified type
    
    let value: Value
    let coercion: Coercion
}

struct ConstraintError: CoercionError { // value is correct type, but out of allowable range
    
    let value: Value
    let coercion: Coercion
}



protocol ArgumentError: NativeError {
    
    var index: Int { get }
    var command: Command { get }
}


struct UnknownArgumentError: ArgumentError {
    
    var description: String { return "Unknown value \(self.index+1) in command: `\(self.command)`" }
    
    let index: Int
    let command: Command
    
    init(at index: Int, of command: Command) {
        self.index = index
        self.command = command
    }
}

struct BadArgumentError: ArgumentError {
    
    var description: String { return "Bad value \(self.index+1) in command: `\(self.command)`" } // TO DO: change message to "is missing" if index >= command.arguments.count
    
    let index: Int
    let command: Command
    
    init(at index: Int, of command: Command) {
        self.index = index
        self.command = command
    }
}



struct HandlerError: NativeError {
    
    var description: String { return "The handler `\(self.handler)` failed on command `\(self.command)`." }
    
    let handler: Handler
    let command: Command
    
    init(handler: Handler, command: Command) {
        self.handler = handler
        self.command = command
    }
}

struct BadInterfaceError: NativeError {
    
    var description: String { return "Invalid interface: \(self.interface)." }
    
    let interface: HandlerInterface
    
    init(_ interface: HandlerInterface) {
        self.interface = interface
    }
}



struct InternalError: NativeError {

    let description: String
    
}


// syntax errors

enum BadSyntax: NativeError { // while tokens containing invalid code are marked as bad syntax, they do not constitute syntax errors if they appear within a string or annotation literal; however, this can only be determined when the script is parsed in full - all a single-line lexer can do is mark it as a potential issue and move on to the next token
    
    var description: String {
        switch self {
        case .unterminatedAnnotation:   return "unterminated annotation"
        case .unterminatedList:         return "unterminated list"
        case .unterminatedRecord:       return "unterminated record"
        case .unterminatedGroup:        return "unterminated group"
        case .unterminatedQuotedName:   return "unterminated quotedname"
        case .unterminatedQuotedString: return "unterminated quoted string"
        case .missingExpression:        return "missing expression"
        case .missingName:              return "missing name"
        case .unterminatedExpression:   return "unterminated expression"
        }
    }
    
    // TBC: case names and human-readable descriptions
    
    case unterminatedAnnotation
    case unterminatedList
    case unterminatedRecord
    case unterminatedGroup
    case unterminatedQuotedName
    case unterminatedQuotedString
    case unterminatedExpression
    case missingExpression // TO DO: parameterize with expected expression type?
    case missingName // e.g. handler name or pair label; TO DO: how should missing colon be reported?
    // TO DO: what else?
}
