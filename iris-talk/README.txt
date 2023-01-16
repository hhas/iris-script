= README

An interactive `iris-talk` shell with built-in stdlib (common operators, flow control), aelib (Apple event IPC), and shell-command libraries, provided for demonstation purposes.


== Installation

Place the pre-built `iris-talk` executable in a suitable location on your shell’s search `$PATH` (e.g. in `/usr/local/bin/`) and run in Terminal.app:

    % iris-talk

Alternatively, build the "iris-talk (run in Terminal)" scheme in Xcode. This will build the `iris-talk` command-line executable (including its AppleEvent and SwiftAutomation dependencies) and launch it in Terminal.app for testing.


== Example usage

    ✎ set my_name to "Bob"
    ☺︎ “Bob”
    ✎ to hi {name} run "Hello, " & name & "!"
    ☺︎ «handler: ‘say_hello’ {name as anything} returning anything»
    ✎ say hi my_name
    ☺︎ “Hello, Bob!”

(✎ = code input prompt; … = multi-line input; ☺ = return value on success; ☹ = syntax/evaluation error)

Lists (`[...]`), records (`{...}`), and blocks (`do...done` or `(...)`) can be entered over one or more lines. The parser will continue reading lines until all incomplete structures are correctly closed. Use commas and/or linebreaks to separate multiple values (including commands).

On pressing Return, the entered code is read. If its syntax is valid it is recolored for readability [1] and executed immediately [2], otherwise a limited error message is displayed.

The shell supports basic readline/VT100/Emacs bindings and behaviors, e.g. Ctrl-C to cancel a line.

== Builtin help

To view a list of the shell's built-in commands:

    ✎ help

`iris-talk` supports `stdlib` and `aelib` commands, in addition to its own builtins. To list all available commands:

    ✎ commands

Stdlib also defines operator syntax (keyword-based syntactic sugar) for several commands, e.g.

    ✎ ‘+’ {2, 3}

is more commonally written as:

    ✎ 2 + 3

To list currently-loaded operator syntax:

    ✎ operators

(Note that operator-defined words and symbols are reserved keywords. To use a reserved keyword as a normal command name, enclose it in single quotes.)


== Application scripting examples [3]

	tell app "com.apple.Finder" to get name of home
	
	tell app "com.apple.Music" to play any track

	say {"Now playing: " & tell app "com.apple.Music" to get name of current_track}

aelib supports AppleScript-like syntax for building and sending Apple event queries and commands (minus AppleScript's arbitrary keyword injection and other ambiguities), providing access to the very high-level programmatic query-driven UIs that already exist in dozens of macOS productivity and lifestyle apps. [4]


== Footnotes

[1] The VT100 pretty printer currently applies the following styles to parsed code:

* bold red = command name
* bold orange = record property/argument label
* violet = operator keyword
* green = symbol value literal
* blue = other value literal

[2] The shell's 'built-in `say` command uses the `Tessa` voice. Installing the high-quality "Tessa (Enhanced)" is recommended (System Settings > Accessibility > System voice > Manage voices...).

[3] Caveat apps must for now be targeted by their Bundle ID string. This should be replaced by persistent global `@Apps` "mentions" namespace (e.g. `@Apps.com.apple.Music`), allowing sandbox IO permission requirements to be represented directly within scripts, using existing `?` and `!` punctuation to distinguish optional vs pre-granted dependencies from "ask permission on first use" (AppleScript-style behavior).

[4] A similar `sclib` library for accessing the less powerful but cross-platform App Extensions used by Siri Shortcuts is TBC.
