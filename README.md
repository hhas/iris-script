# iris-script

An experiment in modern end-user language design, hybridizing [hopefully] the best aspects of Logo and AppleScript, with bits of Perl, Tcl, Lisp, Swift, etc thrown in as appropriate. Obvious anagram. Implemented in Swift.

## Example

    tell app “com.apple.TextEdit” to do
        make new: #document at: end of documents with_properties: {name: “Test”, text: “Hello again!”}
        get text of every document
    done

    ➞ [“Hello again!”]


## Build

Dependencies:

* [SwiftAutomation](https://github.com/hhas/SwiftAutomation)
* [AppleEvents](https://github.com/hhas/AppleEvents)

Ad-hoc tests are currently run under the `iris-test` target.


## Try it

The iris-script project includes `iris-talk`, a basic interactive command-line interface (REPL) for demonstration use. 

Example usage (✎ indicates input prompt):

    ✎ say "Hello World!"
    ☺︎ “Hello World!”

See iris-talk/README.txt for more information.


## Features

Homoiconic, minimalist core language, with only two foundational concepts: values and commands. “Everything is a Command.” The core language and concepts must be quickly and easily learned; everything else should be discoverable if/as/when needed.

Readable, word-based syntax with basic English-like punctuation rules. Each built-in punctuation has a single, unambiguous meaning:

lists:
    
    […]
    
records:

    {…}
    
grouping (of zero or more expressions):
    
    (…)

string literals can be written using “typographer’s quotes” as well as traditional straight quotes:

    “…”  
    "…"

Commas, periods and/or linebreaks are used as expression delimiters. 

Colons denote `label: value` pairs; semi-colons denote “pipes” (`foo; bar {2}`  ➞ `bar {foo, 2}`).

Standard built-in value types: numbers, strings, symbols (“hashtags”), lists (both ordered and key-value; aka arrays and dictionaries), records (tuple-struct hybrid).

Syntactic support (via chainable lexers) for currencies, weights and measures, e.g. `$12.02`, `42kg`, `97.5°C`. Literal representations of dates and times should be achievable too: `2020-07-11`, `06:40:55`.

Identifiers use `snake_case`. This allows easy, unambiguous detection of word boundaries within multi-word names, and should allow tooling to fuzzily match space-separated words against known identifiers and replace spaces with underscores automatically. Pretty printers may also de-emphasize underscores (e.g. by reducing opacity) for a more “English-like” visual appearance without losing semantic clarity.

Commands and blocks (sequences of expressions) are also first-class values; thus iris code is also iris data.

Shift-reduce parser with some customizations to detect expression boundaries and to identify and reduce commands and operators using PEG-style pattern matching. Bottom-up parsing supports incremental/interactive use. Syntax errors are non-halting, enabling rough/unfinished code to be at least partially executed in debug mode, even with typos.

Ubiquitous use of parameterizable coercions (which are also first-class values) for automatic type conversion and constraint checking, e.g. `list` returns a basic (unspecialized) list coercion, whereas `list {of: whole_number {from: 0, to: 100}, min: 4, max: 4}` returns a list coercion with additional element type and length constraints. Code is untyped; however, handler interfaces can include coercion information to provide both auto-generated user documentation and run-time conversions and checks that handler arguments and results are suitable for use. Weak latent structural rather than strong nominal typing: “If a value looks acceptable, it [generally] is.”

No built-in behavior beyond evaluating values. All other behavior is provided by library-supplied handlers. This includes “standard” behaviors such as assignment and flow control. e.g. It is trivial to define a JSON-style data-transfer language and safely parse and render it: instantiate an `Environment` containing no commands or operators except those used to represent `true`/`false`/`nothing` and evaluate code in that. Similarly, the `iris-glue` code generator imports only a subset of stdlib functionality (coercions) and instead obtains its main behavior from `gluelib`.

Commands are effectively unary prefix operators with an arbitrary name and optional (record) operand, e.g.:

    make {new: #document, at: end of documents, with_properties: {name: “Test”}}

For convenience, an argument’s record punctation can usually be omitted: 

    make new: #document at: end of documents with_properties: {name: “Test”}

Arguments are matched by label where given or by position where not, e.g. given a handler with interface `foo {x as integer, y as integer}`, `foo x: 10 y: 20` and `foo {10, 20}` are both acceptable.

Unlike most imperative languages, command arguments are evaluated by the receiving handler, not at the call site. This allows for deferred evaluation of command arguments, where argument expressions are passed unevaluated and unbound (in a primitive handler), or automatically thunked with the command’s scope  before being added to a native handler’s body scope, to be evaluated later only if/when needed. Flow control operations are thus implemented as ordinary handlers; the only difference is in the parameter type, e.g. `if {test as boolean, action as expression, alternate_action as expression}`.

Library-defined commands may be skinned with library-defined operator syntax. e.g. The above code, represented as commands only (single quotes escape names):

    ‘tell’ {‘app’ {"com.apple.TextEdit"}, (
        ‘make’ {new: #‘document’, at: ‘of’ {‘end’, ‘documents’}, with_properties: {name: "Test", text: "Hello again!"}}, 
        ‘get’ {‘of’ {‘text’, ‘every’ {‘document’}}}
    )})

“No variables.” (Distinctions between values, variables, and types are confusing to novices.) Values stored under symbolic names are retrieved using commands of the same name. Immutable, bind-on-first-use behavior is default.

Separate operators for performing math vs non-math comparisons (similar to Perl where numbers and text are one type), e.g. `4 < 12`, `“Bob” is_before “Sue”`, ensuring predictable behavior, e.g. `“4” < 12` ➞  `true`. (Contrast e.g. AppleScript/JavaScript where mixed-type comparisons behave differently according to operand order.)

Coercion-based native⬌Swift bridging API for implementing primitive library functions, ensuring clean separation between Swift implementation and automatically generated native-to-Swift bridging glue code. Glue definitions are written in iris and evaluated via the `gluelib` library. e.g. The `if…then…else…` handler’s glue definition, including custom operator syntax:

    to ‘if’ {test: condition as boolean, then: action as expression, 
             else: alternative_action as expression} returning anything requires {
        can_error: true
        use_scopes: #command
        swift_function: ifTest {condition, action, alternativeAction}
        operator: {[keyword “if”, expr “condition”, keyword “then”, expr “action”,
                    optional sequence [keyword “else”, expr “alternative_action”]],
                   precedence: 101}
    }

    
and its underlying Swift implementation:
    
    func ifTest(condition: Bool, action: Value, alternativeAction: Value, commandEnv: Scope) throws -> Value {
        return try asAnything.coerce(condition ? action : alternativeAction, in: commandEnv)
    }

(Contrast the complexity and coupling of Python/Ruby’s C bridging APIs.)

Interpreter is implemented as slow (but very introspectable) AST walker. Rich native-language interface metadata and clean decoupling of underlying primitive functions should enable partial/full transpilation of native iris code to optimized Swift code, e.g. eliminating redundant native➞primitive➞native bridging coercions so that Swift functions can pass Swift values directly. 

e.g. Consider the expression:

    “HELLO, ” & uppercase my_name

Handler definitions:

    to uppercase {text as string} returning string requires { }
    
    to ‘&’ {left as string, right as string} returning string requires {
        can_error: true
        swift_function: joinValues
        operator: {form: #infix, precedence: 340}
    }

Swift functions:

    func uppercase(text: String) -> String { return text.uppercased() }

    func joinValues(left: String, right: String) throws -> String { return left + right }

Generated Swift code, obviating the unnecessary `String➞Text➞String` bridging coercions between the `uppercase` and `&` (concatenation) commands:

    let native_value  = try env.get("my_name")
    let swift_value   = try asString.coerce(native_value, in: env)
    let swift_result  = try joinValues(left: "HELLO, ", right: uppercase(text: swift_value))
    let native_result = asString.wrap(swift_result, in: env)

Additional transpiling optimizations might include storing values directly in Swift variables rather than native `Environment` slots and replacing simple function calls with template-based Swift code:

    let swift_result = "HELLO, \(swift_my_name.uppercased())"


## TO DO

* improve iris-talk:

  * non-interactive mode for executing script files from STDIN/FILE arguments.

  * organize commands and operators listings, grouping by category (currently all names are listed alphabetically) with wildcard search.

  * live pretty-printing of code as the user types.
  
  * future pretty-printer plugins could also format commands providing different types of feedback during different stages in authoring and testing processes: decribing categories of behavior (safe vs destructive, referentially transparent vs side-effects), identifying by library, flagging detected syntax errors and suspected logic errors or ambiguity, etc.

  * voice input

* greatly improve error reporting, both in parsing and evaluation

* handler overloading/multiple dispatch

* should `to` and `when` operators use `to...do...done` instead of `to...run do...done`? It is rare that a handler will run only a single command, and `to...run...` reads unnaturally in practical use when combined with `do...done` block. This disrupts the consistency found in other operators which take an action to execute, where a single command or block of commands can be used interchangeably (though this is still available via the underlying `'to'` command; it is only ). The alternative is to replace the `run` keyword with one that reads more naturally, c.f. the "then" in `if...then do...done`.

* allow handler signature to specify custom piped-input-to-arguments mapping, e.g. in `foo; 'add'`, if `foo` command outputs a list of 2 numbers, it would be better if the `add` handler takes the first number as default value for its `left` parameter and second number as default value for `right`; currently the first command's output is always passed as first argument to the second, which is fine for handlers that use a single-dispatch OO calling convention that neatly fits the pipeline metaphor (e.g. `trim_text {the_text, which_ends}`), but less so for rules with multiple parameters of equal importance (e.g. `add {left:number, right:number}`) or where the natural order of parameters wants the 'input' value to appear later in the parameters record (e.g. `replace_text {text_to_find, with_text, in_text}` wants to put it last; `bar; items 1 thru 10; fub` would also elide an explicit `...of VALUE` in favor of using the previous command's output, mapping down to `'items' {start, stop, of_value: default {input, any_collection}`)

* decide operator vs command precedence, e.g. `say "Hello " & "Bob."` says "Hello" then throws coercion error as `say` command returns nothing, and `&` requires string operands. i.e. The command name `say` binds tighter to "Hello " than the operator `&`; however the user's visible intention is to concatenate the strings and pass the result to `say`. Conversely, there are plenty of use cases where the command wants to bind more tightly than the operator, e.g. `sin x * y`. One option is fixed order of precedence: pick whichever is the more common case during language design phase and make that the standard behavior (which the user can override by parenthesizing). This is simple to implement, maintain, and teach; though it lacks user convenience (which increases friction and frustration in using the language). Another option might be adaptive precedence: the parser defers decisions on ambiguous binding orders until some/all argument and return types are known (or at least fairly guessable), then decide which combination is most likely to match the user's intent (falling back to asking the user directly if unable to make a best-guess). e.g. If the `say` handler is known to return nothing, one of the two possible combinations becomes logically invalid; thus the parser can conclude with high degree of certainty that the correct choice is to apply `&` first, then `say`; the secondary choice being to propose that there is a logic error in the code (i.e. the user intended to use a different command that does return text as `&`'s left operand'). OTOH, if `say` returns text (its current behavior) then either choice is equally valid code and the parser must rely on frequency weighting/previous experience to best-guess the user's intent. This mode will require live feedback via pretty-printing as the user enters code so the parser's proposed rewrite is instantly visible, encouraging the user to correct it immediately it's not her desired choice. The editor can remember the frequencies of its user's previous choices to improve its own predictions of the user's intent in future (i.e. a simple learning system); such choices might be pooled globally as learned collective knowledge (caveat bad actors polluting the weightings). In the case of adaptive precedence, it is best that the language ensures fixed-order precedence so that source code is aways stable and portable, with all adaptative decisions being made by the editor where the user feedback loop is explicit and immediate.

* editable scripts—currently iris supports whole-script and incremental line parsing, suitable for run-only and CLI shell respectively; eventually it should also support a syntax-directed document editor, where the parser maintains a mutable partial/whole AST representation of the program, allowing individual edits to a text (source code) buffer to be immediately applied to that AST, with API hooks for auto-suggest, auto-complete, auto-correct and other modern IDE/text authoring features

* interactive “debugging” mode (this includes using built-in `?` and `!` punctuation as customizable run-time modifiers, e.g. for triggering introspection breakpoints and “Are you sure?” guards on potentially destructive operations)

* pretty printer with support for user-customizable semantic as well as basic syntactic formatting (e.g. “stylize all commands imported from library X which manipulate lists of strings”; a Datalog interpreter might be appropriate for this) and editor hooks (e.g. when rewriting code, PP is indicating its own understanding of the code to user—where this understanding is uncertain, need to highlight the problem code and attach description of concern and any proposed clarifications, c.f. Word grammar checker)

* expand `stdlib` (e.g. see the basic data manipulation commands defined in `applescript-stdlib`)

* decide how best to support [e.g.] non-numerical comparisons, ensuring safe, predictable results within iris’s weak typing model (contrast AppleScript/JavaScript/PHP’s weak typing which makes comparison operations a fragile, hard-to-predict mess); currently `is_before`, `is_same_as`, etc operators can only compare case-insensitive strings; one possible solution is for individual operators to support an optional `as` clause, e.g. `foo is_before bar as list {of: case_sensitive_text}` (here, the `as` keyword is part of the `…is_before…as…` operator, and indicates that both operands should be coerced to lists of strings and compared case-sensitively); another possibility would be to provide a `considering COERCION run BLOCK` structure somewhat similar to AppleScript’s `considering/ignoring` blocks (but with clearly defined, limited scope of effect), which has the advantage of applying over multiple operations

* decimal support in `Numeric`, e.g. for use in currency calculations (also need to nail down rules for mixed math calculations; unlike Swift, where `Int` and `Double` are distinct types that cannot be mixed in math operations without explicit casting, numbers are freely interchangeable, within the precision and absolute range limits of `Double`); might also consider `BigNum` support and user-friendly comparison operations (e.g. unlike AppleScript, Swift, etc, `0.7 * 0.7 = 0.49` should return the expected *true* in spite of the precision errors inherent in FP math) 

* support chunk expressions (aka queries, or “references” in AppleScript) over native collection types (strings, lists, dictionaries, sets); in addition to providing feature parity with chunk expressions sent over AE bridge, an efficient engine for resolving these queries against standard Swift types can also provide the foundation for a new, SwiftUI-friendly Apple event-handling framework (similar to Cocoa Scripting, but platform-agnostic and without CS’s flaws)

* extensible annotation system (for code comments and TODOs, developer and user documentation, macros and metaprogramming, searchable “keyword” tags, etc)

* global namespace (c.f. Frontier, Unix file system) for presenting libraries, apps, and other [typically external] resources; this would use reverse domain names a-la UTIs with `@` prefix, e.g. `@com.example.foo.lib`; objects within this namespace can be addressed directly, e.g. `tell @com.example.foo to do_stuff` eliminating need for an explicit `import` command, and/or may be included into script’s own namespace (if the library defines custom operator syntax, this can also be included/excluded); e.g. adding `«include: @com.example.foo»` to the top of a script allows `do_stuff` to be referenced directly in the script’s body, without need for a `tell` block

* library import API; this includes a standard API for loading library resources (e.g. see `stdlib_loadHandlers`, `stdlib_loadOperators`, `stdlib_loadConstants`) plus support for top-level `«include: LIBNAME»` and `«exclude: LIBNAME»` annotations in scripts; `stdlib`’s handlers, constants, and operator syntax should be included by default, but may be excluded from individual scripts by adding an `exclude` annotation or starting interpreter with `--exclude…` flag)

* standard library packaging scheme; this will probably be zip-encoded bundles containing library scripts/binaries plus user documentation, tests, examples of use

* per-script sandboxing: given the limitations of macOS’s static app-level sandbox model, per-script sandboxing would require running each script in its own completely sandboxed XPC subprocess, with all script IO being performed via the XPC connection to its parent process; the parent process can then decide exactly which of those IO requests to carry out (e.g. a script may include a manifest of essential/optional external resources it wishes to work with explanations for each; the script host can then present that information to user as a single one-time checklist to fully/partially approve/reject as they wish)

* can/should handlers declare 1. errors they throw/rethrow, 2. required/optional IO, 3. other side-effects; if so, how? (primitive handlers already declare if they throw in glue requirements, though this information currently isn’t captured in HandlerType; native handlers can always throw in body; what about handlers that defer argument evaluation? and how should primitive handlers distinguish errors thrown in argument unpacking vs errors thrown in underlying body function?)

* a mediated IO model should also determine the design of the script’s own IO APIs, e.g. rather than have scripts work with arbitrary file paths and raw `open`/`read`/`write` commands, have the script “mount” any file system objects it wishes to access within the global `@` namespace (e.g. using top-level annotations which can be read at parse-/compile-time) and operate directly on them there: e.g. given a file resource, use the file’s UTI to determine the codec/coercion to use for basic read/write operations; thus a `.txt` file would normally read/write as `utf8_text`, a `.plist` file using a `plist` coercion built on `PropertyListSerialization`, etc, with the script able to attach more specific coercions—e.g. `markdown`, `intent_definition`—to the resource as needed (coercions should also indicate where read-write vs default read-only access is required, e.g. `«mount: “/path/to/file” as editable markdown»` would mount a resource at, say, `@path.to.file` which appears to script as a structured, editable Markdown document object)

* robust, easy-to-understand mutability model (experimenting with coercion-defined “editable boxes” within assign-once environment slots)

* finish Apple event bridge

* add `shortcutslib` for representing Shortcuts Actions as native commands and outputting scripts using those commands as `.shortcut` files

* add `formlib` for displaying commands as GUI forms, using handler interface metadata to present argument inputs as text fields, checkboxes, etc with tooltip documentation and input validation

* spellchecker support, with particular emphasis on checking underscored names as individual words (hence snake_case rather than camelCase) and identifying potentially misspelled operator names (which lexer will treat as command names, resulting in code that may still successfully parse but will produce an unintended result); this should also feed into development of auto-suggest/auto-complete/auto-correct APIs which authoring tools can use (“achieving correct code is an iterative process in which user and machine negotiate a common understanding of its intent until both agree”); this should also enable text-based authoring tools to accept spacebar instead of underscores at entry-time, automatically replacing spaces with underscores when names are already known or name boundaries can otherwise be inferred

* develop dictation UI for executing individual commands and/or writing scripts via voice input/output: this would build on above spellchecking, auto-c3, underscore replacement, and inflexion-inferred punctuation insertion, allowing naturalistic spoken input/output which is converted to/from exact code representation on the fly (with the ability to ask user for clarifications where needed)

* explore potential for automated language translations

* explore potential for symbolic DSL with algebraic syntax, e.g. `3𝓍²－2𝓎＋1`; most or all of this syntax can be achieved by adapting lexer chain and pretty-printer with custom stages; symbolic math, e.g. `x = 2y, z = 3x` ➞ `z = 6y`, will require more work to support (implementing fractional support in `Numeric`, allowing e.g. `1/3 * 2/3` ➞ `2/9` to be performed, may provide a stepping stone to that)

* live end-user documentation, including automatically-generated handler documentation using interface metadata and executable examples
