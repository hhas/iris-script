//
//  general stdlib.swift
//

/*
 Primitive libraries are implemented as Swift funcs that follow standardized naming and parameter/return conventions; all bridging code is auto-generated. Clean separation of native/bridging/primitive logic has big advantages over Python/Ruby/etc-style modules where primitive functions must perform all their own bridging:
 
 - faster, simpler, less error-prone development of primitive libraries
 
 - auto-generated API documentation
 
 - optimizing cross-compilation to Swift (e.g. when composing two primitive functions that return/accept same Swift coercion, boxing/unboxing steps can be skipped)
 */


// TO DO: consider subdividing stdlib, e.g. allowing DSLs to import only those categories they need


// Q. when implementing FS interaction (ideally by mounting filesystem resources as values within the global @namespace, is there any way to take advantage of APFS's copy-on-write file versioning, such that we can observe the outputted file as distinct to the inputted file, even when it's the same 'file', thus supporting file-level Undo where the user can run a script, inspect the new resource, and revert it to the previous version if isn't what they intended? not to mention something approaching referential transparency in IO operations, since two file objects with the same path but different versions are not equal [obviously, openfile(path) is still problematic, though even that might be dealt with by taking an 'attime' argument with current time as its default; thus openfile(path,at:DATE) would open the version of the file that existed at that date, and the only time ref transparency will fail is if that file revision is old enough to have been dearchived to reclaim storage space, in which case that's a halting error])

// TO DO: try implementing a repeating pattern for `&` operator, e.g. `foo & bar & baz` should reduce to a single command that joins an N-ary list of operands in a single operation (aside from testing parser implementation, this should also simplify partial evaluation and allow cross-compilation to idiomatic Swift code as interpolated string literals)

// TO DO: need to decide on Swift- vs Icon-style semantics (one option might be to define 'true' as a wrapper struct that encloses the actual value, allowing it to be obtained when needed, e.g. when chaining conditional operators as `a < b < c`, while displaying as "true" by default; similarly, 'false' would enclose only those values that may represent a false state: `false`, `nothing`, `did_nothing` [Q. should `did_nothing` be the standard "false" value returned by comparison operators, same as for `if`, `while` flow control tests? could be dicey? if so, would need to ensure `did_nothing` is immediately promoted to `nothing`/`false` if not intercepted by `else` clause])




/******************************************************************************/



func isA(value: Value, coercion: NativeCoercion, commandEnv: Scope) -> Bool { // TO DO: should this suppress side-effects? (or at least side-effects involving external resources, e.g. by evaling with a sub-scope that blocks access to [environment-bound] resources?)
    fatalError("TODO")
    //return (try? value.eval(in: commandEnv, as: coercion)) != nil // try coercing value to specified coercion and return 'true' if it succeeds or 'false' if it fails (an extra trick is to cache successful Coercions within the value, allowing subsequent tests to compare coercion objects instead of coercing the value itself, though of course this cache will be invalidated if the value is mutated) // note: there is difference between using coercions to test coercion suitability ('protocol-ness') of a Value vs checking its canonical coercion (e.g. `coercion of someValue == text`); allowing the latter may prove troublesome (novice users tend to check canonical coercion for equality when they should just check compatibility), so will need more thought (maybe use `EXPR isOfExactType TYPE`/`exactTypeOf EXPR`); plus it all gets extra thorny when values being checked are blocks, thunks, references, etc (should they be evaled and the result checked [which can cause issues where expression has side-effects or its result is non-idempotent], or should their current coercion [`codeBlock`, `lazyValue`, `reference`] be used? [note: AppleScript uses the former approach in an effort to appear simple and transparent to users, and frequently ends up causing confusion instead])
}

// TO DO: what about comparing object identities? (how often is that really needed? ideally it shouldn't be included as it doesn't fit with native "say what you need" [coerce before consuming] and "if it looks right, it is" [structural, not nominal, typing] idioms)



/******************************************************************************/
// I/O

// TO DO: when working with streams, would it be better for bridging code to pass required pipes to call_NAME functions as explicit arguments? need to give some thought to read/write model: e.g. rather than implicitly accessing stdin/stdout/stderr/FS/network/etc pipes directly (as `print` does here), 'mount' them in local/global namespace as Values which can be manipulated via standard get/set operations (note: the value's 'coercion' should be inferred where practical, e.g. from filename extension/MIME coercion where available, or explicitly indicated in `attach` command, enabling appropriate transcoders to be automatically found and used) (TO DO: Q. could coercions be used to attach transcoders, avoiding need for special-purpose command? e.g. `let mountPoint = someURL as atomFeed`; i.e. closer we can keep to AEOM/REST semantics of standard verbs + arbitrary resource types, more consistent, composable, and learnable the whole system will be)

// signature: write(value: anything)
// requires: stdout

func write(value: Value) { // TO DO: this needs to take optional `to:` argument containing external resource to write to; if omitted default value is the host environment's standard 'console' (in shell environment, this'd be stdout); the alternative is to implement standardized `read`/`write` methods on objects representing IO channels, although `tell @CHANNEL to read/write…` syntax arguably doesn't read as well
    print(value)
}

