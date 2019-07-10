//
//  handler interface.swift
//  iris-lang
//

import Foundation



struct HandlerInterface: ComplexValue { // native representation is a record; how best to convert to/from that?
    
    var description: String {
        return "\(self.name.label) {\(self.parameters.map{ "\($0.label): \($1.label == "" ? "…" : $1.label) as \($2)" }.joined(separator: ", "))} returning \(self.result)"
    }
    
    // TO DO: store binding names separately? primitive handlers don't need them, and native handlers should probably treat them as private (i.e. third-party code should not make any assumptions about these names - they are defined by and for the handler's own use only); in theory, code analysis tools will want to know all bound names; then again, the easiest way to do code analysis in iris it to execute the script against alternate libraries that have the same signatures but different behaviors (e.g. whereas a standard `switch` handler lazily matches conditions and only evaluates the first matched case, an analytical `switch` handler would evaluate all conditions and all cases to generate an analysis of all possible behaviors)
    
    typealias Parameter = (name: Name, binding: Name, coercion: Coercion) // TO DO: include docstring? // binding is only needed in native handlers when different to label (e.g. in `foo(bar:baz as TYPE)`, bar is the parameter name and baz is the name under which the parameter value is stored in the handler's stack frame)
    
    let nominalType: Coercion = asHandlerInterface
    
    // TO DO: how/where to capture defining module's ID (e.g. for error reporting)
    let name: Name
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
    
    init(name: Name, parameters: [Parameter], result: Coercion, isEventHandler: Bool = false) {
        self.name = name
        self.parameters = parameters
        self.result = result
        self.isEventHandler = isEventHandler
    }
    
    // TO DO: move this up to AsHandlerInterface?
    static func validatedInterface(name: Name, parameters: [Parameter], result: Coercion, isEventHandler: Bool = false) throws -> HandlerInterface {
        var uniqueLabels = Set<Name>(), uniqueBindings = Set<Name>()
        let parameters = parameters.map{ (name: Name, binding: Name, coercion: Coercion) -> Parameter in
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
}


