//
//  environment.swift
//  iris-lang
//

// TO DO: when `«include:…»` annotations are used, how to lazily inject individual handlers into script's [global] scope on first lookup? (one option is to pass specialized Environment subclass as parent, or else hide `frame`'s exact implementation behind a dictionary-like protocol, so that when initial lookup fails to find handler in script's own scope, all included scopes are searched and the returned handler[s] are composed into multimethods if needed and added to scope)


// one advantage[?] of 'editable boxes' + write-once environment slots over 'write-many' environment slots is that set()-ing is primarily a get()-based operation, particularly when resolving chunk expressions which are essentially a chained series of get()-s that ultimately return a single struct that provides a single standardized API for performing all operations - get/set/delete/move/etc - on the selected value[s]; whereas if we have to implement get(), set(), delete(), etc on everything we're probably going to go nuts with implementation [bear in mind the chunk expr's result does not actually have to resolve everything itself; at minimum it only needs to capture the query as a first-class value, deferring the actual resolution until later - essential for Apple event IPC, and also open to collection-specific algorithms and query optimizers when applied to local values (e.g. applying a chunk expr to a String using string-specific scan&slice algorithms is far more efficient than a generic array-processing algorithm that would decompose the string to an Array of single-character strings before operating on that, as CocoaScripting.framework's standard Text Suite implementation seems wont to do)]



// environments (and other scopes?) need to be introspectable, e.g. when generating error messages/tracebacks/userdocs; Q. in the case of libraries, how should they store the library's identifying information? (e.g. should `id/name/version of @.com.example.mylib` be a standard idiom? what about other metadata, e.g. userdocs, operator tables?)

// Values may implement accessor/mutator protocols, allowing attribute lookups; where mutator is implemented, consider how this interacts with struct's pass-by-value semantics (it is likely that mutable values will be implemented as class wrapper[s] around the original Value)

// scopes are always implemented as classes; these are always pass-by-reference, being common state shared by all dependents of a scope

// Q. to what extent should scripts be able to directly reference scopes? (e.g. `current_scope`, `global_scope`, `scope named NAME`) Q. libraries should all appear in global namespace under a common root, e.g. `XXXXX.com.example.mylib`; e.g. `use_library {com.example.mylib}` would merge the library's symbols into the global namespace [caveat: how do we deal with name collisions?]); think Frontier/Plan9 namespace; e.g., if libraries are implemented as write-protected Environment instances, it'd be simpler for Environment class to implement Value protocol rather than wrap it in a Library struct; each library is then mounted directly into global env (or whatever the mount point should be); only question is how are operator and documentation tables handled (may need to subclass Environment to hold those; alternatively, we could store metadata in standard slots under reserved names [also keep in mind that documentation should be lazily loaded from library bundle to avoid unnecessary overheads; ditto for localizations, although we still need to figure out exactly how that will work])

// assuming a universal library namespace that identifies every library by reverse domain name (c.f. Frontier's object database namespace), any library may be referenced by its full ID, e.g. `do_this {…} of @com.example.MyLib` at any time, leaving the runtime to lookup/prompt user to install/etc the library; if so, the `use_library` command's main purpose would be to import a library's symbols into the script's own namespace, allowing them to be accessed directly (thus `use_library @com.example.MyLib` is roughly equivalent to Python's `from com.example.mylib import *`, or C's `#include "com/example/mylib.h"`); the other reason, of course, is to import operators; bear in mind that 'includes' do tend to kick up a stink regarding potential name collisions between libraries (whereas C will report compile-time errors, Python's `from MODULE import…` will silently mask any existing names, which may lead to unexpected behaviors; thus to avoid problems in Python _always_ use `import MODULE` for third-party dependencies; Swift, incidentally, ignores name collisions unless/until those symbols are referenced in code, in which case a compile-time error instructs the user to use full references to those symbols; the trick there being to convert implictly referenced imported symbols to explicit during compilation, which isn't something we can do for interpreted scripts)

// BTW, the infix dot (`.`) operator is a synonym for `of` with operands reversed, thus could also be written as `do_this {…} of MyLib of example of @com`, although that form is not canonical for [reverse] domains; the dot-form may also be conducive to parse-time optimization if additional assumptions can be made based on its appearance, i.e. `foo.bar.baz` specifically describes a domain, whereas `baz of bar of foo` is a standard chunk expr; caveat Python/JS/Swift/etc users may be tempted to overuse/abuse the dot form given its familiar [to them] appearance)

// note that scriptable apps could also be referenced by bundle ID, e.g. `tell @com.example.MyApp do … done` (caveat: *individual* name segments will need single-quoted should they contain any hyphens, which is ugly and unintuitive, e.g. `tell @com.‘some-vendor’.‘some-app’ do … done`); this'd avoid need for a distinct `application NAME` command; it could even be used for file system access (since the Unix FS is really just one big abstract namespace that in theory can host any object that implements 'file' read/write behaviors, though of course Plan9 does a much more complete job of actually applying this principle); in which case `@Users.jsmith.Documents`, `@current_user.Documents`, `@Desktop.somefile`, etc are possible, although the need for single-quoting is likely to get really unpleasant; still, consider how JS uses A["B"] as synonym for `A.B`


// Q. how should we deal with nested/recursive library imports? (particularly 'include'-style imports) [TBH this is more a question of what libraries are automatically included on standard startup, e.g. stdlib, as these need to be automatically present in *all* imported libraries]; arguably the greater challenge is indicating when NOT to include the stdlibs in a script [loathe to rely on hashbang lines with CLI interpreter switches; I suppose we could use a reserved annotation, e.g. `«configure:…»` or possibly one of the 'free' ASCII symbols - \|^~` - ]; reserved annotations would probably be better as the same form can be used to declare localization requirements (e.g. switching number literal parsing from the standard US format to European-style, or reading command names in user's native tongue); reserved annotations could even be used for library imports (since annotations are much easier for parser to pick out and process during compilation, and can be pre-localized without filling up the script's own namespace); similarly, superglobals might be declared solely using «@NAME:VALUE» annotations (again, anything that lives outside the normal runtime namespace+lifetime probably want to have its own predefined syntactic+semantic namespace and rules which the language runtime can read but not write [since there are certain things we do not want a running script to be able to do, such as rewriting its own sandboxing rules])


// TO DO: implement development environments, i.e. custom Environment classes whose `get()` returns some or all handlers enclosed in specialized wrappers that perform additional actions on `call()` before/after forwarding the call to the original handler; e.g. ProfilingHandler would log microsecond times at which `call()` was entered and exited; DebuggingHandler could provide breakpoint-like behavior by suspending on `call()` until a 'continue' signal is received, and also log the command's input and output values for external inspection; MockHandler could generate a GUI form given the underlying handler's signature, allowing user to inspect its input value and enter their own output value - handy for prototyping/testing scripts while that handler is buggy/unfinished)


// TO DO: assume an OS sandbox around script runtime that blocks all external resources (kernel APIs) as standard, instead relying on dependency injection where availability of external  is negotiated between script (which declares resource requirements) and runtime supervisor (which injects XPC connections to approved resources only into runtime subprocess upon launch, typically 'mounting' these resources in the runtime's superglobal namespace, e.g. `@com.apple.finder` is analogous to AS's `application id "com.apple.Finder"`, except that the available functionality is opt-in with greater granularity, e.g. whole-app/permission-to-automate/access-group[s]) [in an ideal world, the supervisor would launch every runtime subprocess instance with dynamically configured sandbox permissions, thereby avoiding every Mach-transported syscall having to travel 'runtime->supervisor->kernel' rather than 'runtime->kernel']; note that a script's sandbox permissions must be fully declarable using [top-level] `«…»` code annotations, i.e. a source-code-only script must contain all information required to run that script on any machine (similar to being able to identify all library dependencies by reverse domain, in order to prompt user if any libs need d/l-ed and installed from external repo before script can run), and these permission annotations must be recursively resolvable, e.g. if a third-party library interacts with iTunes, it should declare its own sandbox annotations; when a script imports that library it should not need to explicitly re-declare those annotations; this implies source code is parsed by the supervisor process, which looks up imported libraries' operator/permission/etc tables and passes the script's AST along with all imported libraries' ASTs to the runtime subprocess for execution [alternatively, it could do a very limited, fast parse of the script source that extracts sandbox-related annotations and superglobal names only, leaving the runtime to do the full source code parse]


import Foundation



class NullScope: Scope {
    
    // always returns nil (unless there's a delegate)
    func get(_ name: Symbol) -> Value? {
        return nil
    }
    
    func subscope() -> Scope { return self }
}

let nullScope = NullScope()


// Q. how should global scopes treat imported modules? (each native module is a read-locked environment populated with library-defined handlers and other values; Q. what about primitive modules? could use Environment subclass that populates frame dictionary)


public class Environment: MutableScope {
    
    internal let parent: Environment?
    
    internal let isLocked: Bool // can `set` operations initiated on child scopes propagate to this scope?
    
    internal var frame = [Symbol: Value]() // TO DO: should values be enums? (depends if environment implements `call(command)`)
    
    init(parent: Environment? = nil, withWriteBarrier isLocked: Bool = true) {
        self.parent = parent
        self.isLocked = isLocked
    }
    
    func get(_ name: Symbol) -> Value? {
        if let result = self.frame[name] { return result }
        var isLocked = false // write-protected scopes can modify themselves but cannot be modified from sub-scopes
        var parentScope: Environment? = self.parent
        while let scope = parentScope {
            if scope.isLocked { isLocked = true }
            if let value = scope.frame[name] {
                // if the slot's value is an EditableValue box, we need to keep that box so that any state changes in the original are seen across all shared references; however, if the scope in which the value was found is protected by a write-barrier we must also ensure that these shared instances can't be modified by code outside of that original scope (roughly analogous to declaring a `private(set) public var` in Swift, except that hopefully we're a bit more thorough in ensuring 'read-only' really means that, given that Swift still permits an ostensibly read-only, i.e. `let`-bound, value to be mutated if it's a class instance, making reasoning about [im]mutability in Swift code a right old maze of both visible complexity and hidden gotchas)
                return !isLocked || value.isMemoizable ? value : ScopeLockedValue(value, in: scope)
            }
            parentScope = scope.parent
        }
        return nil
    }
    
    // Q. `set` needs to walk frames in order to overwrite existing binding if found; should it also try delegate? (seems likely)
    
    // TO DO: by checking for name in parent scopes, this must prevent masking *except* where parameter names are concerned
    
    // TO DO: `set` takes slot name only; what if a chunk expr is given, e.g. `set field_name of slot_name to new_value`? probably better to get() slot, and determine action from there (one challenge: get-ing an editable box needs to discard the box if a write-barrier is crossed)
    
    func bind(name: Symbol, to value: Value) { // called by [Native]Handler.call() when populating handler's stack frame; this does not check for name masking/duplicate names (the former is unavoidable, but as the handler controls those parameter names it will know how to address masked globals [either by renaming its parameters or by using a chunk expr to explicitly reference the masked name's scope], while HandlerInterface is responsible for ensuring all parameter and binding names are unique)
        self.frame[name] = value
    }
    
    func set(_ name: Symbol, to newValue: Value) throws {
        if let value = self.get(name) { // if name is already bound in current or parent scope, try to update it
            try value.set(nullSymbol, to: newValue) // throws if value is immutable or defined in a locked scope
            self.bind(name: name, to: value) // adding the found value to the current scope prevents it being overwritten by a subsequent `define(…)`; i.e. `define(…)`, unlike `set`, is allowed to mask names in parent scopes, as long as those names have not yet been used in the current one [i.e. we don't want, say, a command inside a conditional or loop to call the parent implementation in some iterations and the local implementation in others, as that really screws up Command's first-call memoization behavior, and will likely complicate native-to-Swift cross-compilation too]; problem is that this hoisted value ignores its original scope's write boundaries (capturing an immutable version of the value here isn't an option, as that value will no longer reflect changes to the original); for now, we can try putting in an extra wrapper that preserves both its locks and relation to the original, though really not sure if that's going to work in practice or if it creates more problems than it solves; if it doesn't work then we'll need some other way to prevent `define` from masking a value); the other option would be to adopt an AS-like approach to handler definition and command dispatch, where handlers are defined and bound to a scope at compile-time as opposed to our current approach of defining and binding them entirely during execution (a-la Python/JS); the AS approach has the benefit of all slots being known at compile-time, which may assist editing and introspection tools, but probably requires the parser to hardcode their syntactic special forms (which may break homoiconicity and definitely limits metaprogramming); the Py/JS approach keeps scopes open and extensible during execution (handy for library 'includes' and dynamic object construction, and works within existing library-supplied syntax support) // TO DO: hoisting a handler doesn't eval it, so it won't strongref its original scope (which it needs to do when retained outside of its original context)
        } else { // create new binding with this name in the current scope
            self.frame[name] = newValue
        }
    }
    
    func subscope(withWriteBarrier isLocked: Bool) -> MutableScope {
        return Environment(parent: self, withWriteBarrier: isLocked)
    }
    
    // TO DO: implement call()? if adopting entoli-style 'everything is a command' semantics, Commands would call this rather than call Handlers directly, allowing lighterweight storage of 'variable' values (i.e. enum rather than closure)
}



extension Environment {
    
    // TO DO: how to implement multimethods? should extending an existing slot be implicit/explicit?
    
    // unlike `set`, `define` adds a new item to the current frame so doesn't check for existing names in parent scopes
    
    func define(_ name: Symbol, _ value: Value) {
        self.bind(name: name, to: value)
    }
    func define(coercion: Coercion) {
        self.bind(name: coercion.name, to: coercion)
    }
    
    func define(_ interface: HandlerInterface, _ action: @escaping PrimitiveHandler.Call) { // called by library glues
        // this assumes environment is initially empty so does not check for existing names
        self.bind(name: interface.name, to: PrimitiveHandler(interface: interface, action: action, in: self))
    }
    
    func define(_ interface: HandlerInterface, _ action: Value) throws { // called by `to`/`when` handler
        // this checks current frame and throws if slot is already occupied (even if EditableValue)
        if self.frame[interface.name] != nil { throw ExistingNameError(name: interface.name, in: self) }
        self.bind(name: interface.name, to: NativeHandler(interface: interface, action: action, in: self))
    }
}




class TargetScope: MutableScope { // TO DO: what uses (if any) does this have outside of `tell` blocks? (it is not currently a general-purpose delegate, as only `get` accesses up both scopes; `set` bypasses the target [primary] scope as it's read-only and accesses the parent [secondary] scope)
    
    internal let target: Accessor
    internal let parent: MutableScope
    
    init(target: Accessor, parent: MutableScope) {
        self.target = target
        self.parent = parent
    }
    
    func get(_ name: Symbol) -> Value? {
        //print("TargetScope.get(\(name))")
        return self.target.get(name) ?? self.parent.get(name)
    }
    func set(_ name: Symbol, to value: Value) throws { // TO DO: should this attempt self.target.set(…) first, delegating to parent on error?
        try self.parent.set(name, to: value) // TO DO: what if name is already defined in target scope? should we check that first and throw if found? (otherwise names may be set that cannot be get)
    }
    func subscope(withWriteBarrier isLocked: Bool) -> MutableScope { // TO DO: what should this return?
        return TargetScope(target: self.target, parent: self.parent.subscope(withWriteBarrier: isLocked) as! Environment)
    }
}
