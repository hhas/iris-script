//
//  tests.swift
//  iris-script
//

import Foundation
import iris



func test() {
  //  runScript(" set a to 4. write a. write if true then false. write if false then false else true.")
   // runScript(" optional text ")
   // runScript(" to foo run write “bar” \n foo ") // TO DO: FIX: using optional/default coercion modifiers is still buggy: handler throws error on return (it should return `nothing` instead)
    
    runScript("to foo returning anything run (if false then 1). foo.")
    
   // runScript(" [\n[\n] ")//{ [ (1, 3) , 2 + 4, 5 ]}")
    
    return;
    
    // get document at 1
    // (‘get’ {‘at’ {‘documents’, 1}})
    
    // get documents whose (name is_same_as "Test")
    // (‘get’ {‘whose’ {‘documents’, ‘is_same_as’ {‘name’, "Test"}}})
    
    runScript("""
    tell app “com.apple.TextEdit” to do
        make new: #document at: end of documents with_properties: {name: “Test”, text: “Hello again!”}
        get text of every document
    done
    """)
    
    return;
    
    
    runScript(" foo bar baz" )
    runScript("  if (a) + b = c then get documents at 2 thru -1   ")
    
    
    runScript("  if a + (b)  then 3 ")
     runScript(" if 1 then 2 else 3  ")
    
   runScript(" foo 1 bar: baz fub 4 mod: 3 ")
//return;
    
   // runScript(" if 1 then 2  ")
  //  runScript(" if 1 then 2 else 3  ")
    
 //   runScript(" file at 1 ")
 //   runScript(" file at 1 of home ")
 //   runScript(" get file at 1 ")
 //   runScript(" get name of file at 1 ")
 //   runScript(" get name of file at 1 of home ")
    
   // return;
    /*
    runScript(" ( 1 ) ")
    runScript(" ( \n 1 ) ")
    runScript(" ( 1 \n ) ")
    runScript(" ( \n 1 \n ) ")
    runScript(" ( \n\n 1 \n\n\n ) ")
    */
    
    //runScript(" ( \n + - + 2 \n ) ")
    
    runScript(" ( - 1 ) + 2 * three -4")
    runScript(" ( - 1 ) + 2 * three - 4")
    runScript(" 1 + 2 * 3 - 4")
    
    //return;
    //
    // end of documents -- fails on full match of left operand [but there seems to be general problem with arg expr not reducing nested command]
    runScript("tell app “TextEdit” to make new: #document at: end of documents with_properties: {name: “Test”, text: “blah”}.")

   // runScript(" end of 1 ")
    
    //runScript("make a: x b: 2")

    
    // TO DO: minor(?) bug in pattern matching parensed group as it appears to have two full matches of which only one is correct: “WARNING: discarding extra matches in shift(): [«match `(…)` U66 O6 G5: (.startGroup EXPR) .endGroup ()✔︎ 0», «match `(…)` U69 O6 G5: (.startGroup LF) .endGroup ()✔︎ 0»]”
    runScript(" if 1 then do, 5 + 6, done else (-7 ÷ -8) ")

  //  return;
    
    runScript(" 2 * foo +  5 / - 1 ")
    
   runScript(" 2 * foo -1  / 4")
    
    
     runScript(" f x - (1+1)") // TO DO: FIX: exception on unreduced command
    
    //return;
    
   // runScript(" if 1 then if 2 then 3 else 4 ") // TO DO: FIX: exception on unreduced `if` token 
    
   // runScript(" foo + --+- 2 ");
    
    //runScript("make new: #document at: end of documents with_properties: {name: “Test”, text: “blah”}.")

    
    runScript(" if 1 then (5 + 6) ");
    
    runScript(" if 1 then (5 + 6) else (-7 ÷ -8) ");
    
    runScript(" if 1 then do, 5 + 6, done else (-7 ÷ -8) ");
    
    runScript(" if 1 then 5 + 6 ");
    
    //runScript(" if 1 then 5 + 6 else -7 ÷ -8 "); // TO DO: BUGGY
    
    //runScript(" if 1 then do , 5 + 6 , done else -7 ÷ -8 ");

    //runScript(" if 1 then 5 + 6 else -7 ÷ -8 "); // TO DO: this is very problematic: operator precedence wants to terminate `if…then…` after `5`, but user intention is for `then` clause to perform `5+6` and `else` clause to perform `-7 ÷ -8`; there are also questions over allowing/rejecting LFs around the two action exprs
    
    //runScript(" a;b;c;d "); return;
    
  //   runScript(" if 1,2 then 3 "); return;
    
   // runScript(" 2 * 2 ")

    //    runScript("Foo, bar; baz to: bip; fub, bim.")
    
  //  return;
    
   // runScript(" if -1 * 2 + -3 = -4 then 5 + 6 else -7 ÷ -8 "); // TO DO: this needs to generate a syntax error as `5+6` terminates the operator (since infix `+` is lower precedence than `if`); TO DO: need to decide which operators should bind tighter than flow control (e.g. user intent is pretty obvious here; it gets thorny when commands are also introduced, but we need to find a reasonable balance)
    
    runScript("tell app “TextEdit” to make new: #document at: end of documents with_properties: {name: “Test”, text: “blah”}.")
    
  //  return;
    
//    runScript(" -1 thru -2 "); return;

  // runScript(" foo 1 + bar baz: 2 ")

  //  runScript(" foo - 1  ")
    
    // runScript("set a to: 2") // TO DO: this fails with unhelpful/misleading output: `set…to…` is defined as an operator, so incomplete `set…` match is discarded (with warning about reduction failure) and produces `a{to:3}` (error handling system may want to check for common mistakes, two of which are putting colons after conjunctions, and not putting colons after argument names); parser also needs to insert .error/SyntaxErrorDescription to cover any missing match ranges (TBH it may be better to capture the entire EXPR rather than parts of it: a relatively coarse error may be less helpful, but is also less likely to yield incorrect interpretations of the remaining tokens or misleading explanations of problem)

 //   runScript(" if 1 then if 2 then 3 else 4 ") // TO DO: FIX: parser currently loses `if 1 then` portion with message “Missing first matcher[s] for 0...3” (it will also help if PP parenthesized `if 3…` operation to make clear which operation binds the `else 4` clause)
    
   //  runScript(" 1 else 2 else 3 ")
    
    runScript(" if 1 then 2 else 3 ")
    
    runScript(" if 1 then 2 else if 3 then 4 ")
    
    runScript(" if 1 then 2 else if 3 then 4 else 5 ") // ‘else’ {‘if’ {1, 2}, ‘else’ {‘if’ {3, 4}, 5}}

  //  return;

    
  //  runScript(" if 1 then if 3 then 4 else 6 ") // dangling “else” is resolved by associating with outermost “if” (since `if` binds more tightly than `else`)
    
    // the conundrum here occurs when a compound `if…then…else…` expression is nested as the primary action of another `if…then…else…`, e.g. `if t1 then if t2 then a1 else a2 else a3`
    
    // ‘else’ {‘if’ {‘t1’, ‘else’ {‘if’ {‘t2’, ‘a1’}, ‘a2’}}, ‘a3’}
    //runScript("(if t1 then (if t2 then a1 else a2)) else a3")
  //  print("WANTS: ‘else’ {‘if’ {‘t1’, ‘else’ {‘if’ {‘t2’, ‘a1’}, ‘a2’}}, ‘a3’}")

    // ‘else’ {‘if’ {‘t1’, ‘else’ {‘if’ {‘t2’, ‘a1’}, ‘a2’}}, ‘a3’} // wrong
    //
    //
   // runScript("if t1 then (if t2 then a1 else a2) else a3")

  //  runScript("if t1 then if t2 then a1 else a2 else a3")
    
    //runScript("if (t1,2) then (a1,2) else (a2,4)")
    
    runScript("if t1 then a1")
    runScript("if t1 then a1 else a2")
        
  //  return;
    
    // problem with composable infix `else` is that it wants to bind with alternating tightness
    //
    //            if t2 then a1                      -- p100
    //                                               -- if_t2_ wants a1 so must have higher precedence than _else_a2
    //                          else a2              -- lp90
    //                                               -- if_t1_if_t2_a1_else_a2 wants to capture
    // if t1 then                                    -- rp80
    //                                               -- and having got that, else
    //                                  else a3      -- lp70
    

    // wonder if both ops have same precedence, but `else` associates .left or .right depending on whether there's another else to its right

    
    
    runScript("foo * bar") // ‘*’ {‘foo’, ‘bar’}
    
    // where a command name is followed by operator with both prefix and infix/postfix forms, determine which form to use based on whitespace before and/or after operator (Swift has similar whitespace-sensitive rules, e.g. `1-2` and `1 - 2` are valid but `1- 2` and `1 -2` are syntax errors)
    runScript("foo - 1") // ‘-’ {‘foo’, 1}
    runScript("foo-1")  // ‘-’ {‘foo’, 1}
    runScript("foo -1") // ‘foo’ {-1}`
    runScript("foo- 1") // ‘-’ {‘foo’, 1}
    
    runScript("get name of file at 1 of home")
    
  //  return;

  //  return;
    
    runScript("1 + 1")
    
    runScript(" [] ")
    runScript(" [:] ")
    runScript(" () ")
    runScript(" {} ")
    
    runScript(" [1] ")
    runScript(" [2:3] ")
    runScript(" (4) ")
    runScript(" {5} ")
    
    runScript(" {foo: 1} ")
    runScript(" {foo: 1, bar: 2, baz: fub zim bim zub} ")
    runScript(" {foo: 1, bar: 2, baz: fub zim bim: zub} ")
    runScript(" {foo: 1, bar: 2, baz: fub zim: bim zub} ")
    runScript(" {mod: 1, div: 2} ")

  //  return;
    
    runScript(" foo bar baz ") // ‘foo’ {‘bar’ {‘baz’}}
    

  //  runScript("foo [1, 2,\n3\n [:]] arg: “yes” um: false.")

    runScript("1 + 2 / 4.6") // TO DO: operator parsing is still buggy

    runScript("foo bar baz: fub zim: bip {dob} nag: 0")

    runScript("tell app “TextEdit” to make new: #document at: end of documents with_properties: {name: “Test”, text: “blah”}")

    runScript("[1, 2, 3, 4, 5, 6], 7.")

    runScript("1, [2, 3]! 4, 5.")

    runScript("Foo, bar; baz to: bip; fub, bim.") //     Foo, fub {baz {bar, to: bip}}, bim

    runScript("make new: #document at: end of documents with_properties: {name: “Test”, text: “blah”}.")

    runScript("get name of file at 1 of home")

    runScript("1, do, 2, 3, 4, 5, done \n 6") // note: no separator between `done` and `6` ends parsing prematurely; hopefully table-driven parser will be better at autocorrecting punctuation // TO DO: this currently fails in reduceExpressionBeforeConjunction(:…), mostly likely a bug when parsing `do…done`

    runScript("if 1 + 1 = 2 then beep, write “ok”! 5, 6, 7, 8, 9! 000.")

    runScript("tell app “TextEdit” to make new: #document at: end of documents with_properties: {name: “Test”, text: “blah”}.")

    runScript("to foo run write “ok”, bar. baz, gub, guf.")

    runScript("To say_hello to: name run write “Hello, ” & name & “!”. Say_hello to: “World”.")

    runScript("write 2 + 2")

    runScript("document at 1")

    runScript("1 + 1 = 2") // -> true

    runScript("if 1 + 2 = 5 then write “ok”.")

    runScript("set Bob to “Tim”. if 1 + 2 = 3 then write 6, write bob, write 9 ÷ 2.") // TO DO: couple issues with this: 1. comma after `write 6` should probably be autocorrected to period to make clear that `if` expr ends there; 2. `write 9 ÷ 2` is most likely intended by user to print result of 9÷2, but `÷` is lower precedence than `write` so parses as `(write 9) ÷ 2`; how best to identify potental ambiguities between user’s intent and machine’s interpretation, and how best to clarify automatically/flag for user attention/prompt for user to make her intent explicit?

    runScript("Set name to “Bob”. If 1 + 2 = 3 then write true, write name, write [9 ÷ 2].")

    runScript("if 1 + 1 = 5 then “BOO!”")

    runScript("tell app “iTunes” to get name of current_track") // TO DO: readCommand should return on encountering `to` keyword but throws instead

    runScript("if 1+1=4 then 1 else -1")

    runScript("document at 1")

    runScript("tell app “com.apple.TextEdit” to get every word of text of document at 1")
        // ["hello", "again"]

    /*
    runScript("""
        tell app “com.apple.TextEdit” to do
            make new: #document at: end of documents with_properties: {
                name: “Test”,
                text: “hello again”
            }
        done
        """)
    */
    runScript("tell app “com.apple.TextEdit” to get first document whose text is “” and name begins_with “Untitled”")
    
        // TO DO: problem is that 'thru' binds tighter than 'at'; we could make 'thru' bind looser than [inner] at if we change outer 'at' to different operator, e.g. 'documents from document at 2 thru document at 3'; Q. would it be practical/wise to define infix 'to' operator for constructing ranges, e.g. `1 to 10`? Q. how does `to` know when to clear left? e.g. `a to b` is ambiguous, as it could read as `a {'to' {b}}`

    runScript("tell app “com.apple.TextEdit” to get documents from (document at 2) thru (document at 3)")
    
        // TO DO: `tell` parsefunc needs to match `to` keyword, but defining an infix `to` operator causes that to match instead, resulting in failed parse
        //
        // alternative is to give up on `from…to…` and use `in…thru…` (though ideally we want a generalized solution that will use same rules regardless of i18n)

    runScript("tell app “com.apple.TextEdit” to get documents from 2 thru -1")
    
    
    runScript("""
        Set a to 3, set b to true. If 3 + a = 4 then "A" else if b then "B" else "C".
        """)

    runScript(" if a then (b, c, d) else (e, f). ") // TO DO: sentence blocks (multiple comma-separated exprs) in `then clause` are problematic as punctuation has lower precedence than operators; would need to special-case parsing of block operands

    runScript(" if a then (b, c, d) else (e, f). ")

    runScript(" a + - b ")

    runScript(" [1:2, 3:4, 5:6] ")

    runScript(" 1 + 2 * -3 ")

    runScript(" a 1 b: 2 c: 3")

    runScript(" [1,2,4] ")

    runScript(" [1:2, 3:4, 5:6], [1,3,6], (7), (), (8,9), {a:0, b:3} ")

    runScript(" 1 + [2,4] * 3 ")

    runScript(" 1 + 2 * -3 ")

    runScript(" 1 = 2 + 3 ")

    runScript(" 1 + 2 = 3 ")

    runScript(" 1 + 2 * 3 = 4 ")

    //runScript(" if -1 * 2 + -3 = -4 then 5 + 6 else -7 ÷ -8 ")
    
        // full punctuation command syntax

    runScript("  {1, bar: 2, baz: fub, mod: 3} ")

    runScript(" foo {1} ")

    runScript(" foo ")
    
        // low-punctuation command syntax

    runScript(" foo ")

    runScript(" foo 1 ")

    runScript(" foo baz: 2 ")

    runScript(" foo baz: 2 mod: 3 ")

    runScript(" foo 1 baz: 2 mod: 3 ")

    runScript(" foo baz: 2 mod: 3 of 4 + bar fub: 5 ") // ‘+’ {‘foo’ {baz: 2, mod: ‘of’ {3, 4}}, ‘bar’ {fub: 5}}

        // low-punctuation command syntax with nested commands (commands nested within an LP command can have record argument, non-record direct argument, or no argument only; i.e. labeled arguments after a nested command belong to the outer LP command)

    runScript(" foo fub: bar baz: 2") // ‘foo’ {fub: ‘bar’, baz: 2}

    runScript(" foo fub: bar 3 baz: 2") // ‘foo’ {fub: ‘bar’ {3}, baz: 2}

    runScript(" foo fub: bar zim boo 3 baz: 2") // ‘foo’ {fub: ‘bar’ {3}, baz: 2}

    runScript(" foo fub: bar zim boo baz: 2")

    runScript(" foo fub: bar baz: 2")

    runScript(" foo baz: bar")

    runScript(" foo bar baz")

    runScript(" foo bar ")
    
        // TO DO: where an operator is both infix and prefix, need to decide if it's an argument to left command or if the left command is the left operand to the operator; currently these all parse `-` as infix operator

    runScript(" foo - bar ") // infix `-`

    runScript(" foo -bar ") // assuming this follows WS rule and parses as `foo {'-' {bar}}`, we may want the PP to parenthesize the argument as `foo {-bar}` to make clear to user how it has interpreted that code

    runScript(" foo - 1 ") // infix `-`

    runScript(" foo -1 ") // PP might not need to parenthesize the argument here as `-1` is fairly obviously a number literal, and thus clearly intended by the user(?) as an argument to `foo`

    runScript(" document at 1 ") // `document at 1` *must* take `document` as the left operand to `at`, regardless of precedence, since `at` has no prefix form (infix only)

    runScript(" get document at 1 ") // should reduce to `get{'at'{document{}, 1}}`

    runScript(" foo of bar ") // here the infix `of` operator MUST terminate `foo` command, regardless of precedence (command precedence only comes into play if there is an expr inbetween `foo` and `of`, e.g. `foo 1 of 2`)

    runScript(" foo 1 bar: 2 ")

    runScript(" foo 1 ")

    runScript(" foo 1 bar: 2 mod: 3 ") // ‘foo’ {1, bar: 2, mod: 3}

    runScript(" foo 1 bar: baz mod: 3 ") // ‘foo’ {1, bar: ‘baz’, mod: 3}

    runScript(" foo 1 bar: baz fub 4 mod: 3 ") // ‘foo’ {1, bar: ‘baz’ {‘fub’ {4}}, mod: 3}

    runScript(" foo -1 bar: 2 ") // TO DO: still breaks (need to work on ambiguous operator)

    runScript(" if -1 * - 2 + ---3 = -4 then -5 + -6 else -7 ÷ -8 ") // ‘else’ {‘if’ {‘=’ {‘+’ {‘*’ {-1, -2}, -3}, -4}, ‘+’ {-5, -6}}, ‘/’ {-7, -8}}

    runScript("To say_hello {to: name} run write “Hello, ” & name & “!”. Say_hello to: “World”.") // TO DO: buggy parse omits `write “Hello, ” &`

    runScript("tell app “com.apple.TextEdit” to get documents at 2 thru -1")

    runScript("if (a) + b = c then get documents at 2 thru -1 ") // TO DO: still got problems with disambiguating `+`/`-` when it appears at start of direct argument

    runScript("  documents at 2 thru -3  ") // ‘at’ {‘documents’, ‘thru’ {2, -3}}

    runScript("  get documents at 2 thru 3  ") // ‘get’ {‘at’ {‘documents’, ‘thru’ {2, 3}}}

    runScript("  get documents at 2 thru -3  ") // this explodes as it's treating `-` as infix even though it must be prefix (since it follows infix operator)

    runScript("bim {foo: bar} ")

    runScript(" -1 or - 2 + 3 ")

    runScript(" 1 + 2 * - 3 ") // note: `-` must match as unary operator; `*` match as binary operator even though its right operand is only partially matched as `-`, i.e. it *could* be the start of an EXPR [but isn't yet known for sure]

    runScript(" if 1 * 2 - 3 = 4 then 5 ")

    runScript(" if 1 + 2 = 3 then 4 ")

    runScript(" a -1 ")

    runScript(" nothing ")

    runScript(" 1 + -2 ")

    runScript(" foo 1 bar: 2 baz: 3 ")

    runScript(" foo 1 + a bar: 3 ")

    runScript(" (8,9) ")
    
    
    
    return;

   // runScript(" f x - 1") // this should parse as `-{f{x},1}`

    runScript(" f a: b - 1") //

    runScript(" f a: b of c - 1 ") // `of` needs to bind more tightly than arg label, i.e. `-{f{a:of{b,c}},1}`

    runScript(" a b c ") // this throws parsing error as inner commands can't be LP, but could do with better error message (currently 'expected label in ‘a’ command but found <.unquotedName("c") _"c"_>'); Q. how to suggest corrections? e.g. `a {b {c}}`, `a {b, c}`, `a {b, c: …}`
    
        // TO DO: "a + 1" mis-parses as `a {+1}`
    
        // TO DO: name arg is currently limited to AsLiteralName, but also needs to accept a reference

    runScript("set a of b to 3")

    runScript("set n to app “com.apple.TextEdit”, tell n to get document 1") // TO DO: parser prematurely exits after the 1st `n`; how to match `to` as stop word here? might pass closure thru parser that performs all stop-word/boundary checks; alternatively, leave it for now and address in table-driven parser

    runScript("tell app “com.apple.Finder” to get document_files from 2 thru -1 of home")

    
        // TO DO: need decision on whether or not to overload `set` command to perform local assignment; within a `tell app…` block it current sends an AE (or tries to); one option is to define `me`/`my` atom for use in references, e.g.:
        //
        //  tell app “com.apple.TextEdit” to set my foo to get document 1"
        //
        // we could describe the problem in terms of dispatch-on-first-argument-type, e.g. when first operand is a reference to a target object (e.g. `set end of documents to…` invokes application-defined `set` handler), vs a reference to a local slot (`set end of bars to…` invokes stdlib-defined `set` handler); however, we should also consider that `get`/`set` remote application state is clean simple unambiguous behavior, whereas overloading `set` but not `get` is inconsistent while overloading `get` is redundant (assuming local refs, unlike remote queries, self-resolve on eval)
        //
        // on reflection, looks like `set` should be app-only, or reference-only [if get/set apply to local refs, that is arguably more consistent with remote messaging than with local name binding]
        //
        // Q. if local queries require explicit `get` to resolve, e.g. `get B of A`, then how should dot-form/superglobals behave, e.g. `@A.B`/`A.B`/`B of @A`?

    runScript("Set Bob to “Tim”. Write Bob.")

    runScript("foo 1 as (editable integer)") // TO DO: possible to treat `editable integer` as non-nested command, given it appears as an operand to `as` operator?

    runScript("x: 1")

    runScript("x: 1 as editable integer, y: 2")
    
        // colon pair for assignment is simplest [within an expr sequence]; is it sufficient for it to implement eval? // one caution: `foo: bar, baz` will bind result of baz, not bar; use period/linebreak to terminate colon's right operand
    
        // TO DO: this still leaves question on how to assign when a reference, not identifier, is given; e.g. `set end of bars to…`

    runScript("tell app “com.apple.TextEdit” to get text of documents")

    runScript("write true")

    runScript("if 1 + 2 = 3, 4 then 6, 8, 9.") // this (correctly) reports parse error on unexpected `then` keyword

    runScript("if 1 + 2 = 3, 4, 5, 6.") // this does parse successfully (parser treats first comma as equivalent to `then` separator); PP should probably convert to canonical form

    runScript("if (1 + 2 = 5, true) then write “ok”.") // this also parses successfully; Q. should parser/pp have the smarts to flag the parensed sequence as "suspect", given that the `1+2=5` is effectively a no-op (bear in mind it's also a way to accidentally/deliberately hide effectful operations)

    
    // TO DO: changes to colon rules mean that `{i}:bar` is no longer legal structure; the [nested/parent?] record subsequently fails to reduce and parser aborts complaining about unreduced the .endToken
 //   runScript("map {foo, using: {i}: bar}; fub") // this works and is unambiguous
  //  runScript("foo; map using: {i}: bar; fub") // this works [as long as proc has explicit label], but the right-side of colon pair captures `bar; fub` whereas the user may reasonably expect both colons to be top-level, as they are in `foo; bar; baz` (i.e. semicolons should probably terminate nested sentences)

    
    //runScript("foo; map {i}: bar; fub") // TO DO: reject this syntax as ambiguous? it parses as `((‘map’ {‘foo’, ‘i’}: ‘fub’ {‘bar’}))`, which isn't what's intended (left side of colon pair within a block expr should always be a literal name; thus any form of `cmd, name{…}:…` or `cmd; name:…` should be rejected due to existence of argument record)

    //runScript("foo; map ({i}: bar); fub") // this works: `(‘fub’ {‘map’ {‘foo’, ({‘i’}: ‘bar’)}})`

    //runScript("foo; map {{i}: bar}; fub") // TO DO: this needs to provide better error description (the procedure Pair needs to be parensed to distinguish it from a record field Pair [albeit one with an invalid label type])

    //runScript("foo; map {({i}: bar)}; fub") // TO DO: this fails due to parser bug (probably readRecord being unaware of parens)



    // TO DO: this STILL doesn't parse correctly; it should group as:
    //
    //  ((if t1 then ((if t2 then a1) else a2)) else a3)
    //
    // which parsrs as:
    //
    //  ‘else’ {‘if’ {‘t1’, ‘else’ {‘if’ {‘t2’, ‘a1’}, ‘a2’}}, ‘a3’}
    //
    runScript("if t1 then if t2 then a1 else a2 else a3")


    
    runScript("  do, 1, 2,\n 3\ndone ") // `do \n 1 \n 2 \n 3 \n done` (note: reduceKeywordBlock and Block struct don't yet preserve original expr delimiters, and the indent level will always be 1 tab until a full pretty printer is implemented)
    runScript("1\n do, 2,\n done, 3")
    
    runScript("1, ( 2, 3 ), 4")

    runScript(" if 1, then 2. ") // returns a syntax error due to misplaced delimiter (`,`) after test EXPR (`1`)

    
    
}





func test4() {
    
    //print(PatternValue(Pattern.keyword("test")))
    
    // TO DO: sort out operand labels (and get rid of left/middle/right), and re-add keyword alias support to patterns
    
    var s: String
    
    //s = "3/4 = true. [1,2]. if this then do,foo bar: baz,done"
    
    //s = "true and true "
    
    //s = " “helo” "
    
    s = " {foo:true} "
    
    
    let parser = IncrementalParser()
    
   // parser.read(" “abc ")

   // parser.read(" def” ")

    parser.read(s)
    
    if let script = parser.ast() {
        //print(script, type(of:script))
        
        let f = VT100ValueFormatter()
        
        let result = f.format(script)
        
        print(result)
    } else {
        print("Couldn't parse script.")
    }
    let _ = s
 
    
}
