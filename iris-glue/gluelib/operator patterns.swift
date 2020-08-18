//
//  operator patterns.swift
//  iris-glue
//

import Foundation
import iris

let currentHandlerTypeKey = Symbol(".handler_interface")


    
func keyword(for names: [String]) -> Keyword {
    return Keyword(Symbol(names[0]), aliases: names.dropFirst().map{Symbol($0)})
}


func newSequencePattern(for patterns: [iris.Pattern]) -> iris.Pattern {
    return .sequence(patterns)
}

func newAnyOfPattern(for patterns: [iris.Pattern]) -> iris.Pattern {
    return .anyOf(patterns)
}

func newKeywordPattern(for names: [String]) -> iris.Pattern {
    return .keyword(keyword(for: names))
}

func newExpressionPattern(binding: String?, handlerEnv: Scope) throws -> iris.Pattern {
    if let binding = binding {
        let interface = handlerEnv.get(currentHandlerTypeKey) as! HandlerType
        guard let label = interface.labelForBinding(Symbol(binding)) else {
            // TO DO: what error? (UnknownNameError doesn’t quite work as that expects an Accessor and provides only a generic “can’t find X in Y” message)
            throw InternalError(description: "Operator pattern failed on `expression “\(binding)”` as “\(binding)” isn’t a binding name in the handler’s interface: \(interface)")
        }
        return .boundExpression(label, Symbol(binding))
    } else {
        return .expression
    }
}

func newOptionalPattern(pattern: iris.Pattern) -> iris.Pattern {
    return .optional(pattern)
}

func newZeroOrMorePattern(pattern: iris.Pattern) -> iris.Pattern {
    return .zeroOrMore(pattern)
}

func newOneOrMorePattern(pattern: iris.Pattern) -> iris.Pattern {
    return .oneOrMore(pattern)
}

func newAtomPattern(named names: [String]) -> iris.Pattern {
    return .keyword(keyword(for: names))
}

func newPrefixPattern(named names: [String]) -> iris.Pattern {
    return [.keyword(keyword(for: names)), .expression]
}

func newInfixPattern(named names: [String]) -> iris.Pattern {
    return [.expression, .keyword(keyword(for: names)), .expression]
}

func newPostfixPattern(named names: [String]) -> iris.Pattern {
    return [.expression, .keyword(keyword(for: names))]
}



// sequence {…}
private let type_sequence = (
name: Symbol("sequence"),
    param_0: (Symbol("patterns"), Symbol("patterns"), AsArray(asOperatorSyntax)), // TO DO: min:1
    result: asOperatorSyntax
)
private let interface_sequence = HandlerType(
    name: type_sequence.name,
    parameters: [
        nativeParameter(type_sequence.param_0),
    ],
    result: type_sequence.result.nativeCoercion
)
private func procedure_sequence(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_sequence.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let result = newSequencePattern(
        for: arg_0
    )
    return type_sequence.result.wrap(result, in: handlerEnv)
}

// any {…}
private let type_any = (
    name: Symbol("any"),
    param_0: (Symbol("patterns"), Symbol("patterns"), AsArray(asOperatorSyntax)), // TO DO: min:1
    result: asOperatorSyntax
)
private let interface_any = HandlerType(
    name: type_any.name,
    parameters: [
        nativeParameter(type_any.param_0),
    ],
    result: type_any.result.nativeCoercion
)
private func procedure_any(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_any.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let result = newAnyOfPattern(
        for: arg_0
    )
    return type_any.result.wrap(result, in: handlerEnv)
}

// keyword {…}
private let type_keyword = (
    name: Symbol("keyword"),
    param_0: (Symbol("named"), Symbol("names"), AsArray(asString)), // TO DO: min:1
    result: asOperatorSyntax
)
private let interface_keyword = HandlerType(
    name: type_keyword.name,
    parameters: [
        nativeParameter(type_keyword.param_0),
    ],
    result: type_keyword.result.nativeCoercion
)
private func procedure_keyword(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_keyword.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let result = newKeywordPattern(
        for: arg_0
    )
    return type_keyword.result.wrap(result, in: handlerEnv)
}

// expr {…}
private let type_expression = (
    name: Symbol("expression"),
    param_0: (Symbol("binding"), Symbol("binding"), AsSwiftOptional(asString)),
    result: asOperatorSyntax
)
private let interface_expression = HandlerType(
    name: type_expression.name,
    parameters: [
        nativeParameter(type_expression.param_0),
    ],
    result: type_expression.result.nativeCoercion
)
private func procedure_expression(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_expression.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let result = try newExpressionPattern(
        binding: arg_0,
        handlerEnv: handlerEnv
    )
    return type_expression.result.wrap(result, in: handlerEnv)
}

// optional {…}
private let type_optional = (
    name: Symbol("optional"),
    param_0: (Symbol("pattern"), Symbol("pattern"), asOperatorSyntax),
    result: asOperatorSyntax
)
private let interface_optional = HandlerType(
    name: type_optional.name,
    parameters: [
        nativeParameter(type_optional.param_0),
    ],
    result: type_optional.result.nativeCoercion
)
private func procedure_optional(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_optional.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let result = newOptionalPattern(
        pattern: arg_0
    )
    return type_optional.result.wrap(result, in: handlerEnv)
}

// zero_or_more {…}
private let type_zero_or_more = (
    name: Symbol("zero_or_more"),
    param_0: (Symbol("pattern"), Symbol("pattern"), asOperatorSyntax),
    result: asOperatorSyntax
)
private let interface_zero_or_more = HandlerType(
    name: type_zero_or_more.name,
    parameters: [
        nativeParameter(type_zero_or_more.param_0),
    ],
    result: type_zero_or_more.result.nativeCoercion
)
private func procedure_zero_or_more(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_zero_or_more.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let result = newZeroOrMorePattern(
        pattern: arg_0
    )
    return type_zero_or_more.result.wrap(result, in: handlerEnv)
}

// one_or_more {…}
private let type_one_or_more = (
    name: Symbol("one_or_more"),
    param_0: (Symbol("pattern"), Symbol("pattern"), asOperatorSyntax),
    result: asOperatorSyntax
)
private let interface_one_or_more = HandlerType(
    name: type_one_or_more.name,
    parameters: [
        nativeParameter(type_one_or_more.param_0),
    ],
    result: type_one_or_more.result.nativeCoercion
)
private func procedure_one_or_more(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_one_or_more.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let result = newOneOrMorePattern(
        pattern: arg_0
    )
    return type_one_or_more.result.wrap(result, in: handlerEnv)
}



// atom {…}
private let type_atom = (
    name: Symbol("atom"),
    param_0: (Symbol("named"), Symbol("names"), AsArray(asString)),
    result: asOperatorSyntax
)
private let interface_atom = HandlerType(
    name: type_atom.name,
    parameters: [
        nativeParameter(type_atom.param_0),
    ],
    result: type_atom.result.nativeCoercion
)
private func procedure_atom(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_atom.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let result = newAtomPattern(
        named: arg_0
    )
    return type_atom.result.wrap(result, in: handlerEnv)
}

// prefix {…}
private let type_prefix = (
    name: Symbol("prefix"),
    param_0: (Symbol("named"), Symbol("names"), AsArray(asString)),
    result: asOperatorSyntax
)
private let interface_prefix = HandlerType(
    name: type_prefix.name,
    parameters: [
        nativeParameter(type_prefix.param_0),
    ],
    result: type_prefix.result.nativeCoercion
)
private func procedure_prefix(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_prefix.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let result = newPrefixPattern(
        named: arg_0
    )
    return type_prefix.result.wrap(result, in: handlerEnv)
}

// infix {…}
private let type_infix = (
    name: Symbol("infix"),
    param_0: (Symbol("named"), Symbol("names"), AsArray(asString)),
    result: asOperatorSyntax
)
private let interface_infix = HandlerType(
    name: type_infix.name,
    parameters: [
        nativeParameter(type_infix.param_0),
    ],
    result: type_infix.result.nativeCoercion
)
private func procedure_infix(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_infix.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let result = newInfixPattern(
        named: arg_0
    )
    return type_infix.result.wrap(result, in: handlerEnv)
}

// postfix {…}
private let type_postfix = (
    name: Symbol("postfix"),
    param_0: (Symbol("named"), Symbol("names"), AsArray(asString)),
    result: asOperatorSyntax
)
private let interface_postfix = HandlerType(
    name: type_postfix.name,
    parameters: [
        nativeParameter(type_postfix.param_0),
    ],
    result: type_postfix.result.nativeCoercion
)
private func procedure_postfix(command: Command, commandEnv: Scope, handler: Handler, handlerEnv: Scope, coercion: NativeCoercion) throws -> Value {
    var index = 0
    let arg_0 = try command.value(for: type_postfix.param_0, at: &index, in: commandEnv)
    if command.arguments.count > index { throw UnknownArgumentError(at: index, of: command, to: handler) }
    let result = newPostfixPattern(
        named: arg_0
    )
    return type_postfix.result.wrap(result, in: handlerEnv)
}




class PatternDialect: Scope {

    private let parent: Scope
    private var frame = [Symbol: Value]()
    
    init(parent: Scope, for handlerType: HandlerType) { // the handler interface is used by `expression BINDING_NAME` to remap the operand’s binding name to the underlying Command’s argument label (it would be neater to implement `expression` as a closure that captures this value directly, but this is good enough); e.g. `set…to…` is defined as native pattern [keyword “set”, expression “name”, keyword “to”, expression “value”], which outputs Swift pattern: [.keyword("set"), .boundExpression(Symbol("name"), Symbol("name")), .keyword("to"), .boundExpression(Symbol("to"), Symbol("value"))], remapping the “name” and “value” name bindings to argument labels `{name:,to:}`
        self.parent = parent
        self.frame[currentHandlerTypeKey] = handlerType
        for (interface, action) in [
            // primitive pattern constructors
            (interface_sequence, procedure_sequence),
            (interface_any, procedure_any),
            (interface_keyword, procedure_keyword),
            (interface_expression, procedure_expression),
            (interface_optional, procedure_optional),
            (interface_zero_or_more, procedure_zero_or_more),
            (interface_one_or_more, procedure_one_or_more),
            // convenience constructors for common operator forms
            (interface_atom, procedure_atom),
            (interface_prefix, procedure_prefix),
            (interface_infix, procedure_infix),
            (interface_postfix, procedure_postfix)] {
                self.frame[interface.name] = PrimitiveHandler(interface: interface, action: action, in: self)
        }
    }
    
    func get(_ name: Symbol) -> Value? {
        // print("opt", name, self.frame[name] as Any)
        return self.frame[name] ?? self.parent.get(name)
    }
    
    func subscope() -> Scope {
        return self
    }
}

