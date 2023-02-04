//
//  handler type.swift
//  libiris
//
//  describes a handler's interface (signature): its name, parameters, and return value
//
//  - note that from the native language's POV a handler has a single record parameter which is pattern-matched against the invoking command's [record] argument; in effect `f x -> y`, where x is of form {x_1,x_2,...}
//
//  - internally, `x` is already decomposed to a parameter tuple akin to Swift's call convention, `f(x_1,x_2,...) -> y`
//
//  - each Parameter is a (label,binding,coercion) tuple corresponding to {label: binding as coercion,...}; native handlers can omit the label (in which case the binding name is used for both) and/or the coercion (in which case asAnything is used)
//


import Foundation

// TO DO: what naming convention to use? `HandlerType` or `HandlerSignature`? (HandlerInterface doesn't really work as "RecordInterface" sounds odd, whereas RecordType/RecordSignature works better) - "type" maybe isn’t ideal as that more commonly describes nominal type (which Values do have, but is de-emphasised) whereas this is more about structural typing: if a value looks the right “shape”, it is [or should be] compatible


// TO DO: how to look up handlers by name and introspect their interface natively? (more generally, how to look up environment slots natively using symbols; e.g. define a command that returns current scope as native value? once user has that, they can query it using same/similar code as is used to access records; consider such objects can also operate as JS-style objects, should we wish to support/encourage nominal single-dispatch OOP with objects as an alternative to structural multiple-dispatch on record fields, although creating them natively would require a constructor command [presumably taking object's implementation as block argument])

// TO DO: for lambdas (unnamed, unbound, handlers), use nullSymbol as handler interface's name if no explicit name is declared (e.g. `{args}:action`); Q. should we have a dedicated operator syntax for constructing lambdas, or just use a command? (for now, accept an arg-less command (literal handler name), an appropriately structured colon Pair, or plain [parenthesized?] expr, in an asHandler context)

// TO DO: generalize 'isEventHandler' flag to describe any type of handler; e.g. in a `catching` block, the error handler may declare the error type(s) it is willing to accept, in which case the handler is only invoked if the error argument can be coerced to that type (presumably native errors will be represented as records, so type matching is structural, not nominal)


// literal syntax is `HANDLER_NAME { [ LABEL: ] BINDING [ as COERCION ], … } [ returning COERCION ]`

// note that if a `LABEL:` is not explicitly declared, the binding name is also used as the label name, e.g. `to foo {a,b}…` is shorthand for `to foo {a:a as anything, b:b as anything}`; note that Swift takes the opposite approach—in a Swift `func` definition, it's the binding name that can be omitted and the label that's required, in which case the argument value is bound to the label name—but that makes for inconsistent colon placement in function calls vs function interfaces, which is confusing for users; one the goals of handler interfaces is to act as 'visual templates' for the commands that will invoke them (a-la kiwi, where a Handler’s interface is literally defined by a Command value passed as first argument to the `define rule` command, `define rule (foo (a,b), stuff to do)` and `foo (1,2)` - the command's syntax is identical to its definition; only the values’ names are substituted with the actual values); our approach also avoids having to type parameter labels as `_` to indicate unlabeled arguments, which further complicates language syntax and adds to argument vs parameter inconsistency


// note that the binding name also plays a user documentation role, particularly where parameter label is a preposition rather than a noun, e.g. `search {the_text, for: old_text, replacing_with: new_text}`; this should be encouraged even in primitive handlers where the binding name is unused (in theory, the binding name, if given, could be used as the Swift parameter's label, but it's probably best to insist on native and primitive parameter labels being the same, caveat automatic underscore-to-camelCase conversion)


// Q. how close can literal syntax for AsRecord coercion be to parameter record above? bear in mind that if a handler returns multiple values, `returning` operand should be a record coercion (in theory, its fields may be labeled or unlabeled, depending on how caller is expected to consume returned record, e.g. `set {a,b,c} to do_something` doesn't demand labels, though it's probably still best to require them in the signature as they are self-documenting); main awkwardness is binding names, which standard records don't have (since a record field is {label:value}; obviously if we define a coercion for the value portion that returns a `{name,coercion}` tuple given `name` or `name as coercion`/`‘as’ {name, coercion}`)


// TO DO: how to represent significant handler characteristics (e.g. referentially-transparent/safe/idempotent/side-effects/unsafe/destructive/dependencies); similar to isEventHandler, these aren't really characteristics of handler interface, but might be best attached to it [note that only primitive handlers would explicitly declare their characteristics; native handlers would need to recursively lookup their commands' handlers to obtain set of all found characteristics; furthermore, this is all pretty much done on trust as Swift lacks mechanisms to check/enforce any guarantees, not least as underlying [Obj]C[++] APIs are an absolute free-for-all]


// TO DO: what about allowing name instead of record as parameter: `[to|when] command_name binding_name action_block`? this'd allow varargs (albeit by moving _all_ argument matching into the handler) (presumably the command's argument would still be coerced to record beforehand)



public struct HandlerType: ComplexValue, StaticValue { // native representation is a record; how best to convert to/from that?
    
    public var description: String {
        return "‘\(self.name.label)’ {\(self.parameters.map{ "\($0 == $1 ? "" : "\($0.label): ")\($1.label) as \($2)" }.joined(separator: ", "))} returning \(self.result)"
    }
    
    // TO DO: store binding names separately? primitive handlers don't need them, and native handlers should probably treat them as private (i.e. third-party code should not make any assumptions about these names - they are defined by and for the handler's own use only); in theory, code analysis tools will want to know all bound names; then again, the easiest way to do code analysis in iris it to execute the script against alternate libraries that have the same signatures but different behaviors (e.g. whereas a standard `switch` handler lazily matches conditions and only evaluates the first matched case, an analytical `switch` handler would evaluate all conditions and all cases to generate an analysis of all possible behaviors)
    
    public typealias Parameter = RecordType.Field // TO DO: include docstring? // binding is only needed in native handlers when different to label (e.g. in `foo(bar:baz as TYPE)`, bar is the parameter name and baz is the name under which the parameter value is stored in the handler's stack frame)
    
    public static let nominalType: NativeCoercion = asHandlerType.nativeCoercion
    
    // TO DO: how/where to capture defining module's ID (e.g. for error reporting)
    public let name: Symbol
    public let parameters: [Parameter] // single parameter? (how to pattern-match, bind values to handler scope?) // TO DO: linked list vs array vs record (records might use linked list internally, since they're ordered key-value sets)
    public let result: NativeCoercion // rename parameters/result to input/output?
    
    public let isEventHandler: Bool // if true, unmatched arguments are silently ignored; if false, all arguments must be matched (this allows `when EVENT…` event handlers to ignore arguments that are not of interest to them, while ensuring `to ACTION…` command handlers do not ignore anything); TO DO: this needs more work (NativeHandler.call() isn't smart enough to step over an unmatched argument; might be simpler to implement event handler as separate struct) // TO DO: can primitive handlers be event handlers, or will they always be command handlers? // TO DO: should this be attribute of Handler rather than HandlerType? (i.e. the interface is arguably what appears as the first operand between the `to`/`when` operator and its second [action] operand)
    
    // what about introspectable user documentation and other metadata?
    
    public init(name: Symbol, parameters: [Parameter], result: NativeCoercion, isEventHandler: Bool = false) { // caution: parameters must have unique, non-empty labels
        self.name = name
        self.parameters = parameters
        self.result = result
        self.isEventHandler = isEventHandler
    }
    
    static func validatedInterface(name: Symbol, parameters: [Parameter], result: NativeCoercion, isEventHandler: Bool = false) throws -> HandlerType { // TO DO: currently unused
        var uniqueLabels = Set<Symbol>(), uniqueBindings = Set<Symbol>()
        let parameters = parameters.map{ (label: Symbol, binding: Symbol, coercion: NativeCoercion) -> Parameter in
            // TO DO: in native handler definitions, binding should always be given while label is optional; that said, we may want to keep current logic depending on where AsHandlerType coercion does its validation (since the same coercion may be applied to primitive as well as native handler interfaces)
            let label_ = label == nullSymbol ? binding : label
            let binding_ = binding == nullSymbol ? label_ : binding
            uniqueLabels.insert(label_)
            uniqueBindings.insert(binding_)
            return (label_, binding_, coercion)
        }
        let interface = self.init(name: name, parameters: parameters, result: result, isEventHandler: isEventHandler)
        if name == nullSymbol || uniqueLabels.contains(nullSymbol)
            || uniqueLabels.count != parameters.count || uniqueBindings.count != parameters.count {
            throw BadInterfaceError(interface)
        }
        return interface
    }
    
    public func asEventHandler() -> HandlerType { // convert from command handler (unmatched arguments are an error) to event handler (unmatched arguments are ignored)
        if self.isEventHandler { return self }
        return HandlerType(name: self.name, parameters: self.parameters, result: self.result, isEventHandler: true)
    }
}


public extension HandlerType {
    
    // caution: this assumes HandlerType always contains both label and binding name, even if identical
    func labelForBinding(_ name: Symbol) -> Symbol? { // used by native `expression NAME` Pattern wrapper to convert an operand/binding name (used in native operator definition) to and argument label name (used in underlying Command’s argument record); this makes for more readable, less error-prone native pattern syntax
        return self.parameters.first{ $0.binding == name }?.label
    }
}


let nullHandlerType = HandlerType(name: nullSymbol, parameters: [], result: asNothing.nativeCoercion)
