//
//  parser.swift
//  iris-script
//


// bottom-up parser with [optional] operator tables

// it should be possible to construct a complete parse tree, even with syntax errors/ambiguities (these should be captured as `Unresolved`/`Unbalanced` nodes; unbalanced nodes should attempt to re-balance unbalanced quotes [Q. what heuristic to determine likeliest insert point[s] for balancing quote]); 'unresolved' nodes will also be necessary if token sequences cannot always be resolved to [right-associative] commands (bear in mind that all commands are unary; in absence of terminating punctuation/unambiguously terminating operator, the next token is taken as right-hand operand); it's up to editor to generate one or more best-guesses as to user's *actual* intent, using whatever [possibly incorrect and/or probably incomplete] contextual information is currently available

// operator tables are populated when loading libraries (Q. could/should operator availability be scoped? if limited to a single, global operator table, operators must be imported at top of script, before any other code); need to decide how/when libraries are imported (e.g. operator definitions should be available while incrementally parsing, e.g. in code editor)

// Q. how will libraries mediate operator injection, to provide safe, predictable namespace customization even when an older/newer version of a library is imported [since library developers may need/wish to add/remove/modify operator definitions]; one option is to version library's operator definitons separately to library releases, e.g. `use_library com.example.foo with_operators: v1`

/*
 
 reserved punctuation:
 
 () [] {} -- group, list, record
 
 «» -- annotation
 
 “”" -- string literal
 
 ‘’' -- word literal (words only need to be quoted when disambiguating from identically named operators; Q. should operator's underlying command always have the same name as canonical operator, with only difference being quoted vs non-quoted? or are there any arguments for command names being different to canonical operator, e.g. `intersect {a,b}` vs `a ∩ b`? although if that's the case then the command name should probably be quoted with the unquoted form automatically defined as an operator synonym, e.g. `‘intersect’ {A,B}` == `A intersect B` == `A ∩ B` [basically, if the operator doesn't mask the command name, users may attempt to use that name elsewhere in their code])
 
 ,; -- expr separators (note that `;` pipes the result of left-hand command as first argument to right-hand command'; i.e. `A{B};C{D,E}` == `C{A{B},D,E}`); the right-hand expr may optionally be preceded by a [single?] linebreak in addition to other whitespace, allowing long expr sequences to be wrapped over multiple lines for readability)
 
 .?! -- block terminators (typically single-line, and optional given that linebreaks terminate blocks by default); `?` and `!` act as 'safety' modifiers, wherein the preceding block's evaluation may be altered wrt 'unsafe' operations (e.g. `?` could halt on unsafe operations and prompt user before proceeding; `!` would force unsafe operations to be applied without any warning or rollback/undo; runtime callback hooks would allow the exact behaviors for each to be customized)
 
 #@ -- name prefixes, aka 'hashtag' (symbol) and 'mentions' (superglobal); will need to decide how superglobals are defined and when and where they are loaded (roughly analogous to global functions and environment variables defined in .zhrc, they are primarily of use in interactive mode; when used in distributable scripts, they'll need to be 'baked' as every user defines different @names to mean different things)
 
 do not reserve:
 
 +-*×/÷=≠<>≤≥& (these are library-defined operators); Q. if `!=` is defined as operator synonym for `≠`, how do we override the `!` char's reserved meaning?
 
 */


import Foundation
