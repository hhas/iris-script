//
//  errors.swift
//  iris-lang
//

// TO DO: localization

// TO DO: how to generalize error throwing to provide interactive runtime hooks (e.g. rather than call [NativeError].init directly, call a function that allows a custom hook to be installed over default throw behavior; while AST-walking interpreter precludes halting evaluator and breaking out of its main loop, threaded code could block on interpreter thread while separate user-interaction thread allows user inspection of issue; in an ideal world, the user could directly amend problem state and resume execution, although that may be require a more sophisticated interpreter architecture to enable; however, even being able to inspect errors at point of origin without having to set explicit breakpoints manually throughout code may be of help in getting code to work right)

// note that commands should use operator syntax when available (i.e. parser should annotate Command instance with PatternDefinition); as with message localization, how to provide modifiable/live view onto error attributes? (might consider developing a native DSL for transformable data composition, c.f. glue generator; e.g. once we have a form library that transforms handler interfaces to GUI forms, it shouldn't be much of a step to define error constructors as native handlers, complete with PP hinting, canonical [interpolated] error messages with hand/machine localization support, etc)

import Foundation


public protocol NativeError: Value, Error {
    
}

extension NativeError {
    
    public static var nominalType: Coercion { return asError }

    public func from(_ parent: Error) -> Error {
        return ChainedError(error: self, parent: parent)
    }
}


public struct ChainedError: NativeError { // problem with this approach is that it requires unwrapping to determine actual error type (defining a `parent:Error?` slot on every native error struct avoids this problem, but gets messy); main reason for chained exceptions is to construct native stack traces from chained HandlerError instances, so it might be simpler to limit error chaining support to HandlerError
    
    public var description: String { return "\(self.error)\n• \(self.parent)" }
    
    var error: Error
    var parent: Error
}


// TO DO: error chaining

// TO DO: base protocol for all native errors (this should extend Value protocol)


public struct NotYetImplementedError: NativeError {
    
    internal(set) public var parent: Error?
    
    public var description: String { return "`\(self._function)` is not yet implemented." }
    
    private let _function: String
    
    public init(_ _function: String = #function) {
        self._function = _function
    }
}


public struct MalformedRecordError: NativeError {
    
    public var description: String { return "Found duplicate name `\(self.name.label)` in record \(self.fields)" } // TO DO: format
    
    let name: Symbol
    let fields: [Record.Field]
    
    public init(name: Symbol, in fields: [Record.Field]) {
        self.name = name
        self.fields = fields
    }
}


// Environment errors

public struct UnknownNameError: NativeError {
    
    public var description: String { return "Can’t find `\(self.name.label)` in \(self.scope)" }
    
    let name: Symbol
    let scope: Accessor
    
    public init(name: Symbol, in scope: Accessor) {
        self.name = name
        self.scope = scope
    }
}


public struct ImmutableScopeError: NativeError {
    
    public var description: String { return "Can’t modify `\(self.name.label)` in immutable \(self.scope)" }
    
    let name: Symbol
    let scope: Accessor
    
    public init(name: Symbol, in scope: Accessor) {
        self.name = name
        self.scope = scope
    }
}

public struct ExistingNameError: NativeError {
    
    public var description: String { return "Can’t replace existing value named `\(self.name.label)` in \(self.scope)" }
    
    let name: Symbol
    let scope: Accessor
    
    public init(name: Symbol, in scope: Accessor) {
        self.name = name
        self.scope = scope
    }
}

public struct ImmutableValueError: NativeError {
    
    public var description: String { return "Can’t modify immutable value named `\(self.name.label)` in \(self.scope)" }
    
    let name: Symbol
    let scope: Accessor
    
    public init(name: Symbol, in scope: Accessor) {
        self.name = name
        self.scope = scope
    }
}


// TO DO: when to use enum vs struct? (e.g. probably makes sense to group all coercion errors except null coercion as a single struct, with enum to indicate exact issue)

public protocol CoercionError: NativeError {
    
    var value: Value { get }
    var coercion: Coercion { get }
    
}

extension CoercionError {
    
    public var description: String {
        return "Can’t coerce the following \(self.value.nominalType) to \(self.coercion): `\(self.value)`"
    }
}
    
public struct NullCoercionError: CoercionError { // value is `nothing`
    
    public let value: Value
    public let coercion: Coercion
    
    public var description: String {
        return "Can’t coerce `nothing` to \(self.coercion)."
    }
}

struct UnsupportedCoercionError: CoercionError { // cannot coerce value to specified type
    
    public let value: Value
    public let coercion: Coercion
    
    public init(value: Value, coercion: Coercion) {
        self.value = value
        self.coercion = coercion
    }
}

public struct ConstraintError: CoercionError { // value is correct type, but out of allowable range
    
    public let value: Value
    public let coercion: Coercion
}



public protocol ArgumentError: NativeError {
    
    var index: Int { get }
    var command: Command { get }
}


public struct UnknownArgumentError: ArgumentError {
    
    public var description: String { return "Can’t match argument field \(self.index+1) in `\(self.command)`" }
    
    public let index: Int
    public let command: Command
    
    public init(at index: Int, of command: Command) {
        self.index = index
        self.command = command
    }
}

public struct BadArgumentError: ArgumentError {
    
    public var description: String { return "Can’t evaluate argument field \(self.index+1) in `\(self.command)`" } // TO DO: change message to "is missing" if index >= command.arguments.count
    
    public let index: Int
    public let command: Command
    
    public init(at index: Int, of command: Command) {
        self.index = index
        self.command = command
    }
}



public struct HandlerError: NativeError {
    
    public var description: String { return "The handler `\(self.handler)` failed on command `\(self.command)`." }
    
    let handler: Handler
    let command: Command
    
    public init(handler: Handler, command: Command) {
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
    
    init(description: String) {
        self.description = description
    }
    
    init(_ error: Error) {
        self.init(description: String(describing: error))
    }
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
        case .illegalCharacters:        return "illegal character[s]"
        case .malformedWhitespace:     return "malformed whitespace"
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
    case illegalCharacters
    case malformedWhitespace
}


public class SyntaxErrorDescription: NativeError {
    
    public var description: String {
        return "«Syntax Error: \(self.error)»"
    }
    
    public let error: NativeError
    
    public init(error: NativeError) {
        self.error = error
    }
    public convenience init(_ message: String) {
        self.init(error: InternalError(description: message))
    }
}
