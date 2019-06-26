//
//  handler interface.swift
//  iris-lang
//

import Foundation



struct HandlerInterface: ComplexValue { // native representation is a record; how best to convert to/from that?
    
    var description: String {
        return "\(self.name.name) {\(self.parameters.map{ "\($0.name): \($1.name == "" ? "…" : $1.name) as \($2)" }.joined(separator: ", "))} returning \(self.result)"
    }
    
    typealias Parameter = (label: Symbol, binding: Symbol, coercion: Coercion) // TO DO: include docstring? // binding is only needed in native handlers when different to label (e.g. in `foo(bar:baz as TYPE)`, bar is the parameter name and baz is the name under which the parameter value is stored in the handler's stack frame)
    
    let nominalType: Coercion = asHandlerInterface
    
    // TO DO: how/where to capture defining module's ID (e.g. for error reporting)
    let name: Symbol
    let parameters: [Parameter] // single parameter? (how to pattern-match, bind values to handler scope?) // TO DO: linked list vs array vs record (records might use linked list internally, since they're ordered key-value sets)
    let result: Coercion // rename parameters/result to input/output?
    
    let isEventHandler: Bool // if true, unmatched arguments are silently ignored; if false, all arguments must be matched (this allows `when EVENT…` event handlers to ignore arguments that are not of interest to them, while ensuring `to ACTION…` command handlers do not ignore anything); TO DO: this needs more work (NativeHandler.call() isn't smart enough to step over an unmatched argument; might be simpler to implement event handler as separate struct) // TO DO: can primitive handlers be event handlers, or will they always be command handlers?
    
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
        let parameters = parameters.map{
            // TO DO: in native handler definitions, binding should always be given while label is optional; that said, we may want to keep current logic depending on where AsHandlerInterface coercion does its validation (since the same coercion may be applied to primitive as well as native handler interfaces)
            (label: Symbol, binding: Symbol, coercion: Coercion) -> (label: Symbol, binding: Symbol, coercion: Coercion) in
            let label = label == nullSymbol ? binding : label
            let binding = binding == nullSymbol ? label : binding
            uniqueLabels.insert(label)
            uniqueBindings.insert(binding)
            return (label, binding, coercion)
        }
        let interface = self.init(name: name, parameters: parameters, result: result, isEventHandler: isEventHandler)
        if name == nullSymbol || uniqueLabels.contains(nullSymbol)
            || uniqueLabels.count != parameters.count || uniqueBindings.count != parameters.count {
            throw BadInterfaceError(interface)
        }
        return interface
    }
}


