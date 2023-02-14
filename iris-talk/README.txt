= README

An interactive iris shell with stdlib (common operators, flow control), aelib (Apple event IPC support), and iris-shell libraries included. Its CLI is minimally functional, for demonstration purposes only.

Iris is a work in progress. May contain bugs; no warranty given, use at own risk. See the README in the iris-script Xcode project for more information on the language design, syntax, and development.


== Installation

Place the `iris-talk` executable into a directory on your shell’s search `$PATH` (e.g. copy it into `/usr/local/bin/`, or append its current location to $PATH in your `~/.zprofile`) and run in Terminal.app:

    % iris-talk

== Example usage

	Welcome to the iris interactive shell. Please type `help` for assistance.
    ✎ set my_name to "Bob"
    ☺︎ “Bob”
    ✎ to hi {name} perform "Hello, " & name & "!"
    ☺︎ «handler: ‘hi’ {name as anything} returning anything»
    ✎ say hi my_name
    ☺︎ “Hello, Bob!”
    
On pressing Return, the entered line is read. If it is valid code, it is recolored for readability [1] and executed immediately [2]. If the code is invalid, a limited error message is displayed.

	✎ = code input prompt
	… = multi-line input
	? = default text input (`read`) prompt
	☺ = return value on success
	☹ = syntax/evaluation error

Lists (`[...]`), records (`{...}`), and blocks (`do...done` or `(...)`) can be entered over one or more lines. The parser will continue reading lines until all incomplete structures are correctly closed. Use commas and/or linebreaks to separate multiple values (including commands).

Iris syntax includes a built-in “pipe” operator (`;`), allowing commands to be written sequentially so that the result of one command is passed as first argument to the next:

	✎ To hi {name} perform "Hello " & name & "!".
	…
	✎ Say "Who are you?"; read; hi; say.
	Who are you? Sam
	☺︎ “Hello Sam!”

Iris is modular. All behavior is provided by command handlers; including math and logic operations, flow control, and defining new commands (`To…`).  Iris provides a core set of value types: Booleans, numbers, strings, lists, records, blocks. Commands are iris values too: an iris script can be interpreted as instructions to perform, data to manipulate, or any combination of both. 


== Builtin help

To view a list of the shell's built-in commands:

    ✎ help

`iris-shell` supports `stdlib` and `aelib` commands, in addition to its own builtins. To list all available commands:

    ✎ commands

Stdlib also defines custom operator syntax (keyword-based syntactic sugar) on top of some frequently-used commands. For example:

    ✎ ‘+’ {2, 3}

is more easily written as:

    ✎ 2 + 3

To list currently-loaded operator syntax:

    ✎ operators

Note that words and symbols defined for use by operators become reserved keywords. To use a reserved keyword as a normal command name, enclose it in single quotes.

The shell supports basic readline/VT100/Emacs bindings and behaviors, e.g. Ctrl-L to clear; Ctrl-C to cancel a line.

== Application scripting examples [3]

	tell app "com.apple.Finder" to get name of home
	
	tell app "com.apple.Music" to play any track

	say {"Now playing: " & tell app "com.apple.Music" to get name of current_track}

aelib supports AppleScript-like syntax for building and sending Apple event queries and commands (minus AppleScript's arbitrary keyword injection and other ambiguities), providing access to the very high-level programmatic query-driven UIs available today in dozens of popular macOS productivity and lifestyle apps. [4]


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
