//
//  handler interface.swift
//  iris-lang
//

import Foundation


// TO DO: for lambdas (unnamed, unbound, handlers), use nullSymbol as handler interface's name; Q. should we have a dedicated operator syntax for constructing lambdas, or just use a command?


// literal syntax is `HANDLER_NAME { [ LABEL: ] BINDING [ as COERCION ], … } [ returning COERCION ]`

// note that if a `LABEL:` is not explicitly declared, the binding name is also used as the label name, e.g. `to foo {a,b}…` is shorthand for `to foo {a:a as anything, b:b as anything}`; note that Swift takes the opposite approach—in a Swift `func` definition, it's the binding name that can be omitted and the label that's required, in which case the argument value is bound to the label name—but that makes for inconsistent colon placement in function calls vs function interfaces, which is confusing for users; one the goals of handler interfaces is to act as 'visual templates' for the commands that will invoke them (a-la kiwi, where a Handler’s interface is literally defined by a Command value passed as first argument to the `define rule` command, `define rule (foo (a,b), stuff to do)` and `foo (1,2)` - the command's syntax is identical to its definition; only the values’ names are substituted with the actual values); our approach also avoids having to type parameter labels as `_` to indicate unlabeled arguments, which further complicates language syntax and adds to argument vs parameter inconsistency


// note that the binding name also plays a user documentation role, particularly where parameter label is a preposition rather than a noun, e.g. `search {the_text, for: old_text, replacing_with: new_text}`; this should be encouraged even in primitive handlers where the binding name is unused (in theory, the binding name, if given, could be used as the Swift parameter's label, but it's probably best to insist on native and primitive parameter labels being the same, caveat automatic underscore-to-camelCase conversion)


// Q. how close can literal syntax for AsRecord coercion be to parameter record above? bear in mind that if a handler returns multiple values, `returning` operand should be a record coercion (in theory, its fields may be labeled or unlabeled, depending on how caller is expected to consume returned record, e.g. `set {a,b,c} to do_something` doesn't demand labels, though it's probably still best to require them in the signature as they are self-documenting); main awkwardness is binding names, which standard records don't have (since a record field is {label:value}; obviously if we define a coercion for the value portion that returns a `{name,coercion}` tuple given `name` or `name as coercion`/`‘as’ {name, coercion}`)


// TO DO: how to represent significant handler characteristics (e.g. referentially-transparent/safe/idempotent/side-effects/unsafe/destructive/dependencies); similar to isEventHandler, these aren't really characteristics of handler interface, but might be best attached to it [note that only primitive handlers would explicitly declare their characteristics; native handlers would need to recursively lookup their commands' handlers to obtain set of all found characteristics; furthermore, this is all pretty much done on trust as Swift lacks mechanisms to check/enforce any guarantees, not least as underlying [Obj]C[++] APIs are an absolute free-for-all]


// TO DO: what about allowing name instead of record as parameter: `[to|when] command_name binding_name action_block`? this'd allow varargs (albeit by moving _all_ argument matching into the handler) (presumably the command's argument would still be coerced to record beforehand)



struct HandlerInterface: ComplexValue { // native representation is a record; how best to convert to/from that?
    
    var description: String {
        return "‘\(self.name.label)’ {\(self.parameters.map{ "\($0.label): \($1.label.isEmpty ? $0.label : $1.label) as \($2)" }.joined(separator: ", "))} returning \(self.result)"
    }
    
    // TO DO: store binding names separately? primitive handlers don't need them, and native handlers should probably treat them as private (i.e. third-party code should not make any assumptions about these names - they are defined by and for the handler's own use only); in theory, code analysis tools will want to know all bound names; then again, the easiest way to do code analysis in iris it to execute the script against alternate libraries that have the same signatures but different behaviors (e.g. whereas a standard `switch` handler lazily matches conditions and only evaluates the first matched case, an analytical `switch` handler would evaluate all conditions and all cases to generate an analysis of all possible behaviors)
    
    typealias Parameter = (name: Symbol, binding: Symbol, coercion: Coercion) // TO DO: include docstring? // binding is only needed in native handlers when different to label (e.g. in `foo(bar:baz as TYPE)`, bar is the parameter name and baz is the name under which the parameter value is stored in the handler's stack frame)
    
    static let nominalType: Coercion = asHandlerInterface
    
    // TO DO: how/where to capture defining module's ID (e.g. for error reporting)
    let name: Symbol
    let parameters: [Parameter] // single parameter? (how to pattern-match, bind values to handler scope?) // TO DO: linked list vs array vs record (records might use linked list internally, since they're ordered key-value sets)
    let result: Coercion // rename parameters/result to input/output?
    
    let isEventHandler: Bool // if true, unmatched arguments are silently ignored; if false, all arguments must be matched (this allows `when EVENT…` event handlers to ignore arguments that are not of interest to them, while ensuring `to ACTION…` command handlers do not ignore anything); TO DO: this needs more work (NativeHandler.call() isn't smart enough to step over an unmatched argument; might be simpler to implement event handler as separate struct) // TO DO: can primitive handlers be event handlers, or will they always be command handlers? // TO DO: should this be attribute of Handler rather than HandlerInterface? (i.e. the interface is arguably what appears as the first operand between the `to`/`when` operator and its second [action] operand)
    
    // what about introspectable user documentation and other metadata?
    
    // caution: generated glues should use init(name:parameters:result:isEventHandler); native handlers should use validatedInterface(name:parameters:result:isEventHandler)
    
    init() {
        self.name = nullSymbol
        self.parameters = []
        self.result = asAnything
        self.isEventHandler = false
    }
    
    init(name: Symbol, parameters: [Parameter], result: Coercion, isEventHandler: Bool = false) {
        self.name = name
        self.parameters = parameters
        self.result = result
        self.isEventHandler = isEventHandler
    }
    
    // TO DO: move this up to AsHandlerInterface?
    static func validatedInterface(name: Symbol, parameters: [Parameter], result: Coercion, isEventHandler: Bool = false) throws -> HandlerInterface {
        var uniqueLabels = Set<Symbol>(), uniqueBindings = Set<Symbol>()
        let parameters = parameters.map{ (name: Symbol, binding: Symbol, coercion: Coercion) -> Parameter in
            // TO DO: in native handler definitions, binding should always be given while label is optional; that said, we may want to keep current logic depending on where AsHandlerInterface coercion does its validation (since the same coercion may be applied to primitive as well as native handler interfaces)
            let name = name == nullSymbol ? binding : name
            let binding = binding == nullSymbol ? name : binding
            uniqueLabels.insert(name)
            uniqueBindings.insert(binding)
            return (name, binding, coercion)
        }
        let interface = self.init(name: name, parameters: parameters, result: result, isEventHandler: isEventHandler)
        if name == nullSymbol || uniqueLabels.contains(nullSymbol)
            || uniqueLabels.count != parameters.count || uniqueBindings.count != parameters.count {
            throw BadInterfaceError(interface)
        }
        return interface
    }
    
    
    func toRecord(in scope: Scope, as coercion: RecordCoercion) throws -> Record {
        return Record([(Symbol("name"), self.name),
                       (Symbol("input"), OrderedList(self.parameters.map({$0.coercion}))), // TO DO: what about including binding names?
                       (Symbol("output"), self.result)], as: asRecord) // TO DO: what coercion?
    }
}


