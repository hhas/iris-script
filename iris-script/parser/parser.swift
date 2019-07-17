//
//  parser.swift
//  iris-script
//


// bottom-up parser with [optional] operator tables


// Q. how can bottom-up parser assist code editor's autocorrect/autocomplete? i.e. having parsed N tokens representing an incomplete/invalid expression, how can editor inspect the token stack and partial/failed pattern matches to propose potential completions/corrections


// it should be possible to construct a complete parse tree, even with syntax errors/ambiguities (these should be captured as `Unresolved`/`Unbalanced` nodes; unbalanced nodes should attempt to re-balance unbalanced quotes [Q. what heuristic to determine likeliest insert point[s] for balancing quote]); 'unresolved' nodes will also be necessary if token sequences cannot always be resolved to [right-associative] commands (bear in mind that all commands are unary; in absence of terminating punctuation/unambiguously terminating operator, the next token is taken as right-hand operand); it's up to editor to generate one or more best-guesses as to user's *actual* intent, using whatever [possibly incorrect and/or probably incomplete] contextual information is currently available

// operator tables are populated when loading libraries (Q. could/should operator availability be scoped? if limited to a single, global operator table, operators must be imported at top of script, before any other code); need to decide how/when libraries are imported (e.g. operator definitions should be available while incrementally parsing, e.g. in code editor)

// Q. how will libraries regulate operator injection, to provide safe, predictable namespace customization even when an older/newer version of a library is imported [since library developers may need/wish to add/remove/modify operator definitions]; one option is to version library's operator definitons separately to library releases, e.g. `«use: @com.example.foo(>1.2).syntax[.1], @net.example.bar.syntax.3»`

/*
 
1. reserved punctuation (part of core language, hardcoded into lexer):

    () [] {} -- group, list, record

    «» -- annotation

    “”" -- string literal

    ‘’' -- word literal (words only need to be quoted when disambiguating from identically named operators; Q. should operator's underlying command always have the same name as canonical operator, with only difference being quoted vs non-quoted? or are there any arguments for command names being different to canonical operator, e.g. `intersect {a,b}` vs `a ∩ b`? although if that's the case then the command name should probably be quoted with the unquoted form automatically defined as an operator synonym, e.g. `‘intersect’ {A,B}` == `A intersect B` == `A ∩ B` [basically, if the operator doesn't mask the command name, users may attempt to use that name elsewhere in their code])

    ,; -- expr separators (note that `;` pipes the result of left-hand command as first argument to right-hand command'; i.e. `A{B};C{D,E}` == `C{A{B},D,E}`); the right-hand expr may optionally be preceded by a [single?] linebreak in addition to other whitespace, allowing long expr sequences to be wrapped over multiple lines for readability)

    .?! -- block terminators (typically single-line, and optional given that linebreaks terminate blocks by default); `?` and `!` act as 'safety' modifiers, wherein the preceding block's evaluation may be altered wrt 'unsafe' operations (e.g. `?` could halt on unsafe operations and prompt user before proceeding; `!` would force unsafe operations to be applied without any warning or rollback/undo; runtime callback hooks would allow the exact behaviors for each to be customized); caution: `.` is parsed wrt adjoining tokens/whitespace, e.g. `foo. bar` (expr separator) is distinct from `foo.bar` (attribute selector) is distinct from `-1234.56` (decimal separator) is distinct from `192.168.1.1` (literal-specific)

    #@ -- name prefixes, aka 'hashtag' (symbol) and 'mentions' (superglobal); will need to decide how superglobals are defined and when and where they are loaded (roughly analogous to global functions and environment variables defined in .zhrc, they are primarily of use in interactive mode; when used in distributable scripts, they'll need to be 'baked' as every user defines different @names to mean different things); Q. how to distinguish user-defined @NAMEs from system-defined? e.g. if we define the runtime's 'external' namespace (c.f. Frontier's object database) using reverse domains, we get a crazy number of TLDs (`@com`, `@org`, `@uk.net`, `@xxx`, etc. etc) implicitly polluting that namespace; we could use `@` vs `@@` to distinguish user vs universal scopes; [also caution: it's awfully easy to type `@.com.example.foo` instead of `@com.example.foo`, and they are too close visually to use both forms to mean different things, so we need to pick one and enforce it]
 
 
2. do not reserve [e.g.]:

    +-*×/÷=≠<>≤≥& (stdlib-defined operators); Q. if `!=` is defined as operator synonym for `≠`, how do we override the `!` char's reserved meaning?

    $ -- currency prefix (i.e. chars that have a clear, common meaning should not be used to mean other things)

 
3. undecided:
 
    _ -- underscore (this will probably be part of 'word' pattern, though could be tokenized separately and reassembled by parser; the more granular approach being naturally conducive to editor formatting [underscores can appear at 50% transparency]/help representations [where whole-word/dictionary-driven matching and headings display naturally use spaces rather than underscores])
 
    ~^`|\ -- these currently have no special meaning, but could be reserved punctuation if needed (they have the advantage of being ASCII chars that appear on standard keyboards)
 
 */


/* commands:

 
    foo

    bar {1, 2, 3}
 
    bar {for: 1,to: 2, by: 3}

    bar 1 to: 2 by: 3

 
    right-associative, so:
 
    foo bar baz -> foo {bar {baz}}
 

 
 Q. for defining values, use `set NAME to VALUE` and/or `NAME: VALUE`? (note that updating an existing editable value requires `set`; main reason to allow `name:expr` form is to define value in current scope, which can mask an existing name in parent scope; this would require such definitions to appear before other code; somewhat analogous to `property NAME: VALUE` in AS, except it could be used in any scope)

 
 
*/


// `if TEST EXPR` is a double-postfix operator syntax sugar over a two-parameter command, `‘if’ {test:BOOL_EXPR, action:BLOCK_EXPR}`, which returns result of action block if test is true or `did_nothing` if test is false (c.f. Boolean operators in Icon which return an operand's result to indicate true or 'failed' to indicate false); multiple tests may be combined using `else` infix operator, which evals the left operand then, if that returns `did_nothing`, evals the right operand and returns the result of that; this provides better compositionality than Swift's atomic `if...elseif...else...` statement (e.g. `while TEST EXPR1 else EXPR2` will perform EXPR2 if `while` command performs zero iterations); note that while the nested commands would normally read poorly in absence of operator sugar, e.g. `else{else{if {test1,action1},if {test2,action2}},action3}`, this visually awkward nesting can be avoided by using core-syntax's 'pipe' punctuation (where `A{B};C{D}` is equivalent to writing `C{A{B},D}`) to give `if {test1,action1}; else {if {test2,action2}}; else {action3}`; e.g. programmatically assembled data-processing 'pipelines' (c.f. Shortcuts workflows) can use `;` to yield reasonably human-readable script code without having to use library-defined operators


import Foundation


// Q. how should match-tree deal with repeating elements, e.g. `[` -> `]` / `:` `]` / EXPR [`:` EXPR `,`|`,`]

// match-tree roots (leftmost punctuation): [ ( { « "“” '‘’ IDENTIFIER DIGITS PREFIX_OP CURRENCY_SYMBOL; what about +- (may be prefix ops or part of a number literal)

// rightmost [match-terminating] punctuation: ] ) } » "“” '‘’ . ? !

// separator punctuation: , ; : (this terminates an expr match and begins another)

// LF terminates non-quoted matches

// note that angled single/double quote chars can provide weak hints as to whether parser is entering or exiting a string literal; this may be helpful when disambiguating syntax errors (usually when existing code containing pretty-printed string literals is being modified; users will typically type new string literals using straight quotes), but should be taken with a pinch of salt (code editors that auto-'fix' typographers' quotes as user types don't always insert the right form, plus quotes aren't guaranteed to remain correct if user has moved code around)

// what about [optional/required] whitespace matching? should that be an step in the partial match, or should prefix and/or postfix ws be declared as part of the match pattern; also, how to indicate where cosmetic linebreaks are permitted within match

// Q. how should matcher deal with annotations? (tempted to asssociate them with the preceding token on stack)


// we could do parser combinators, but that arguably locks up contextual knowledge that could benefit orthogonal tools (e.g. autocorrect); table-based matching allows free inspection of tables and partial match states; if we need a language for it then either EBNF or similar pattern matching language that can be implemented as simple recursive descent parser

/*
 
 Q. how easy/hard to define match patterns as Array<Token>? ExpressibleBy allows some conciseness (strings = literal matches)
 
 
 LINEFEED
 
 WHITESPACE
 
 
 DIGIT: '0' | '1' | … | '9'
 
 NUMBER: DIGIT+ // note that signs and separators are not included, nor are scientific/currency/quantity
 
 NAME_QUOTE: ( "'" | "‘" | "’" )
 
 NAME: ( ALPHA | '_' ) ( ALPHA | DIGIT | '_' )* | NAME_QUOTE QUOTED_NAME_CHAR* NAME_QUOTE ) // Q. should unquoted name be any non-reserved-punctuation character sequence? (probably; e.g. `22°C` is number plus '°C')
 
 STRING_DELIMITER: ( '“' | '”' | '"' )
 
 STRING: STRING_DELIMITER QUOTED_STRING_CHAR* ( STRING_DELIMITER STRING_DELIMITER QUOTED_STRING_CHAR* )* STRING_DELIMITER
 
 LIST: '[' ']' | '[' EXPR ( ',' EXPR )* ']'
 
 KEYED_PAIR: EXPR ':' EXPR // caution: if we define PAIR as an EXPR, we will need some way to ensure […] contains all pairs or no [unparenthesized] pairs (alternatively, we could just let the parser decide the list type based on the first item, and flag subsequent inconsistencies, e.g. `[foo:1,bar,baz:3]` -> `[foo:1,«bad_syntax: missing_token name»:bar,baz:3]`, or `[1,2,foo:bar]` ->`[1,2,«bad_syntax: unparenthesized_pair (foo:bar)»]`)
 
 KEYED_LIST: '[' ':' ']' | '[' KEYED_PAIR ( ',' KEYED_PAIR )* ']' // non-empty form is same as list's, except EXPR's type is `EXPR:EXPR`
 
 NAMED_PAIR: NAME ':' EXPR
 
 FIELD: FIELD | EXPR //  note that name is not matched against operator tables; thus `{as:…}` is a valid record, although referencing that field will still require quoting: `‘as’ of {as:…}`; this should avoid any confusion when reading low-punctuation commands, as any name suffixed by a colon cannot be confused for an operator name; thus `get file 1 of home as: alias` is distinct from `get file 1 of home as alias`, but we should be able to annotate operator definitions with common gotchas which the parser can look out for and notify the code editor advising clarification when encountered [actually, the low-punctuation command parser should be able to detect argument/operator name ambiguities automatically; no need for library developers to describe common gotchas that can be detected automatically])
 
 RECORD: '{' '}' | '{' FIELD ( ',' FIELD )* '}'
 
 GROUP: '(' EXPR ( ',' EXPR )* ')'
 
 COMMAND: NAME | NAME RECORD | NAME EXPR | NAME EXPR? NAMED_PAIR* // name-only | name with record or expr that will be coerced to single-item record | low-punctuation command (this will use 'latest' association when reading nested commands, i.e. FIELDs will bind to the latest command name that was read by default; Q. how to make library-defined handler interfaces available to parser in order to auto-assist disambiguation? and how should aggressive/automatic should auto-associate be?); Q. how to disambiguate `name {…} name:expr`? as `(name {…}) «bad_syntax: unexpected_token (name:expr)»` or as `name {{…}, name:expr}`? 'latest' rule says label belongs to last command name encountered, which would mean treating the preceding record as command's direct parameter; OTOH, `foo bar {} baz:fub` indicates that `bar{}` is complete command so baz:fub belongs to `foo` (real question here is how often will a command's first argument value be a record; this is more likely to happen if we eschew JS-like objects with single-dispatch methods attached for structural typing and multimethods [although in idiomatic use most commands will be written with an identifier literal, not a record literal, as the record is stored once then passed around])
 
 // operator tables need to be [fully] loaded before we can begin matching operator names
 
 OPNAME: NAME // caveat NAME must be an operator-table defined name, as any name not in operator tables is treated as a command name
 
 PREFIX_OP: OPNAME EXPR
 
 POSTFIX_OP: OPNAME NAME
 
 INFIX_OP: EXPR OPNAME EXPR
 
 ATOMIC_OP: OPNAME
 
 DOUBLE_POSTFIX_OP: OPNAME EXPR EXPR
 
 OPERATOR: PREFIX_OP | POSTFIX_OP | INFIX_OP | ATOMIC_OP | DOUBLE_POSTFIX_OP
 
 EXPR: STRING | LIST | KEYED_LIST | RECORD | GROUP | COMMAND | OPERATOR
 
 
 // in practice, operand exprs may be of specific types (e.g. `to HandlerInterface Block`); how best to parameterize these for individual operator definitions? [it won't affect tokenization or standard parsing behavior; however, the additional info may be used by code editor in providing on-the-fly contextual syntax checking with autocorrect, autocomplete, etc] (Q. should arity be parameterized? or do we really want to discourage complex multi-operand operators [e.g. `if TEST EXPR else EXPR` or, worse, `if TEST EXPR (elif TEST EXPR)* (else EXPR)?`] in favor of simple, composable operators [e.g. `if TEST EXPR` and `EXPR else EXPR`])
 
 // what about comparison operators where we want to normalize operands via `as` clause? that's kinda tricky to compose, because [depending on precedence] `a > b as TYPE` either parses as `(a < b) as TYPE` or `a < (b as TYPE)`, where the former is redundant and the latter is unhelpful [as user would normally parenthesize that intent for visual clarity anyway]; e.g:
 //
 // NORMALIZING_INFIX_OP: EXPR OPNAME EXPR 'as' EXPR=Coercion // or maybe Literal(Coercion) if we don't want user parameterizing it [c.f. AppleScript]
 
 // Q. should currency symbols be defined as operators (possibly with no-whitespace rules), or should they be 'OTHER' tokens that the numeric parser can match (given a match table of known currency formats)? e.g. entoli uses a discrete numeric parser just to match numbers (the same parser is used for text->number coercions) [A. probably not operators, as operators won't work well for units due to the amount of namespace pollution that'll create - e.g. is `m` an operator or an identifier? - although leading currency symbols will still need to be in some sort of table that invokes the numeric parser to process them]

 
 
 // how best to match number-like values such as quantities, currencies, dates, times, IPaddrs: `12.5g` `$50`, `2019-08-05`, `12:42:00`, `192.168.1.1`

 
 // Q. if we build match tree out of classes, should repeating matches be represented by weakref'd recursive nodes, or by indexes (where entire graph is structured as an array, with each transition represented as relative [forward/backward] offset/absolute index for next state [we'd need a separate hash of token names to offsets when building the graph])
 
 
 // when lexer encounters `-`/`+` character, what to do next? not sure lexer should be switching behaviors, but don't really want main parser to have to deal with numbers, e.g. `-123,456.78` is effectively 6 tokens that should reduce to 1 [with the extra caveat that Int/Double don't capture formatting info - should we punt formatted numbers to Number (which wouldn't capture original string either, but could auto-format when pretty-printing numerical values); bear in mind that Double also isn't guaranteed to preserve original number as written due to FP imprecision]
 
 
 // mind that match tree nodes aren't unique (EXPR appears in multiple chains, e.g. `[expr(,expr)*]` vs `{expr(,expr)*}`)
 
 */
