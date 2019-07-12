//
//  lexer.swift
//  iris-script
//

import Foundation


// needs to distinguish:

// reserved punctuation

// contiguous alphanumeric (digits, Latin, Cyrillic, Arabic, Han, etc) with interstitial underscores

// linebreaks

// contiguous whitespace

// any other contiguous chars


// Q. how best to match combinations of alnum and symbol chars, e.g. `-180°C`, `($12.20)`?


// when tokenizing for pretty-printing/code highlighting, how to organize tokens/offsets for different display representations (e.g. basic formatting describes token types - name/operator/string literal/number literal/punctuation/annotation - but other presentations - e.g. hierarchical [literate] outline, where heading annotations and handler definitions are highlighted - should be easily and instantly switchable; similarly, library-defined command and operator names should highlight when a given library import is selected; plus syntax errors, semantic ambiguities, unrecognized names, constraint mismatches, suspect spellings, character spoofing, etc should all be highlightable [spoofing checks will need to look for mixed alphabets within words, although quite how that'll work with languages that naturally mix character sets will need further thought])


// code editor also needs ability to indicate inferred punctuation when user highlights command (e.g. `set x to: y` is shorthand for explicit `set {x, to: y}`), though this is probably parser's responsibility

// Q. should underscore (`_`) be tokenized separately to contiguous digit/alpha chars? (that puts onus on parser to determine underscore's meaning); assmuning underscores [like commas] are treated as separator tokens, how should they be disambiguated? e.g. for long decimal numbers, it would be helpful if commas can be used as thousands separators, though this requires disambiguation from commas used as expr separators (e.g. as determined by presence/absence of other whitespace after comma; non-linebreak whitespace might even be classed as a 'separator', with a partial parser sitting between lexer and full parser responsible for resolving separators and nothing else; this would also make it easier to localize number parsing in general, allowing user scripts to declare, e.g. `number_format #European` to switch numeric parsing from standard UK/US `1,234,567.89` format to `1.234.567,89` without needing special hooks into lexer/parser)


// note that simple 'dumb' rules should be applied when parsing punctuation-less commands: the goal is to achieve the simplest, flattest (i.e. most predictable) structure that is syntactically correct; inferring the correct semantic groupings (which may involve reassociating some arguments with different commands [or flagging for user to resolve when ambiguous] once detailed handler interface information for those commands is available), e.g. flattest resolution of `foo bar: 1 baz: fub zub: 2` is `foo {bar: 1, baz: fub, zub: 2}`, whereas tail resolution is `foo {bar: 1, baz: fub {zub: 2}}`; even more matches are possible if all arguments are unlabeled, e.g. `foo 1 bar 2 3` might be `foo {bar, 2, 3}`, `foo {bar {2}, 3}`, or `foo {bar {2, 3}}` (not to mention `foo 1, bar 2 3` is a possible interpretation if we also anticipate users forgetting to type the expr separator [a common novice error in kiwi])


// another reason to keep lexer-parser coupling really loose is when parsing for quoting balancing/indentation only; again, that doesn't require full parser, and shouldn't even care about meanings of words or separator punctuation between them; it should only look for quoting chars - [](){}«»"“”'‘’ - and surrounding whitespace (while not structural, whitespace indentation can be inspected to best-guess where code editor should propose re-balancing unbalanced quotes to user)


// important: when disambiguating +/- and other operators that are both prefix and infix, it is necessary to examine whitespace on both sides of operator, along with preceding symbol [if it's a name], e.g. `foo-2` = `foo - 2` = `foo {} - 2`, whereas `foo -2` = `foo {-2}` and `foo- 2` is flagged as a syntax error (Q. since scripts containing syntax errors can still be run, how should this syntactic construct be represented in AST?)

// Q. given that handlers are first-class values, how should an ambiguous syntactic construct such as `foo {1, 2} baz` be treated? it may be user forgot to insert expr separator (e.g. `,`) after record, or it may be that the 'foo' handler returns another handler which is to be invoked with the `baz` expr as its argument; probably best to flag as ambiguous and move on (c.f. a word processor's grammar checker); if the user runs the script unamended then, as with other syntax errors, this AST node should prompt for clarification if/when evaled; e.g. if we define a grammatical convention where parens disambiguate chained calls `(foo…)(baz), - i.e. `(COMMAND1)(ARGUMENT2)`, which is clearly distinct from `COMMAND1, COMMAND2` - then the code editor can substitute the correct representation and continue; caution: also consider `foo 1 2 baz`, which is arguably even more ambiguous - assuming implicit record punctuation, it is read as `foo {1, 2, baz}`; we can avoid this ambiguity if implicit records are limited to an initial field which may be unlabeled followed by zero or more fields which MUST be labeled, e.g. `foo 1 by: 2 baz` gets us back to the initial two interpretations (missing expr separator/chained call) and resolve from there as before (given that SDEF-defined commands already follow this pattern, this is probably a reasonable compromise, plus it encourages use of labeled over unlabeled arguments which is both more robust against future handler interface changes and makes user's code much more self-explanatory)


// Q. should operator-defined names default to command names if code's fixity doesn't match, or should they be treated as syntax error? e.g. `mod` is an infix operator, so what if it appears with one or no operands? [since the operator and command names are the same, it's going to invoke the operator's underlying command in any case]; TBH, this is more a question of multimethods, as the most obvious homonym, `-`, requires two different implementations for prefix vs infix use, but whereas entoli/sylvia defined two different command names, `negate` vs `subtract`, we really want to keep the canonical name as `-` in both cases (although `negate` and `subtract` could still be defined as synonyms [Q. how to control synonyms’ invisible namespace pollution?])

