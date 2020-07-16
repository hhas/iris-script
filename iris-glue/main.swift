//
//  main.swift
//  iris-glue
//


// TO DO: FIX: operator definitions need ability to supply custom argument labels for use in underlying Commands (currently operators use generic label arguments—"left", "middle", "right"—which are unhelpful)


// TO DO: AsLiteralName coercion?; this'd allow aliases to be written directly as names rather than strings;

// TO DO: how to parameterize run-time return type? (TO DO: any primitive handler that evals native code need ability to pass result coercion as Swift func parameter; for now, best to declare requirement explicitly, c.f.     use_scopes:…)

// TO DO: should `use_scopes` argument also specify mutability requirements?

// TO DO: glue handler names shouldn't normally need single-quoted as (except for ‘to’, ‘as’, ‘returning’) they're not defined as operators when glue code is parsed

// TO DO: generic `left`/`right` arg labels are awful; use meaningful labels and binding names where practical and store that info in PatternDefinition to be used when reducing operators to annotated Commands

// TO DO: precedence should eventually be defined by tables describing relative ordering: for each group of operators (arithmetic, comparison, concatenative, reference, etc), ordering of operators within that group are described as a named table, i.e. (TABLENAME,Array<Set<OPNAME>>); these tables are then ordered relative to one another by Array<TABLENAME>; upon loading all operator definitions, the parser can assign numeric precedences for efficiency (although it may be simpler to store this as a separate [OPNAME:Int] dictionary rather than update PatternDefinition structs in-situ; one more level of indirection is unlikely to make any difference as it's not a bottleneck); main challenge is in deciding how to declare relative ordering of operator groups when these groups are defined across multiple libraries; e.g. if two unrelated third-party libraries define operator groups, those groups can be ordered relative to stdlib groups (e.g.. stdgrp3 < FOOGRP < stdgrp4), but not relative to each other (potentially a problem if BARGRP appears between stdgrp3 and 4 as well; for practical purposes the parser would have to forbid their direct composition, requiring explicit parentheses around one or other: `OP1 (EX OPB)` or `(OP1 EX) OPB`)

// TO DO: comparison and logic operators need higher precedence than `whose` operator (1200-1240?)


import Foundation
import iris


let args = CommandLine.arguments

if args.count != 3 {
    print("Usage: iris-glue GLUEFILE DESTDIR\n")
    print("Glue file must be named `LIBNAME.iris-glue`.\n") // TO DO: naming convention
    print("")
    exit(0)
}

do {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let glueURL = URL(fileURLWithPath: args[1], relativeTo: cwd)
    let outURL = URL(fileURLWithPath: args[2], relativeTo: cwd)

    try renderGlue(glueFile: glueURL, outDir: outURL)
} catch {
    fputs("\(error)\n", stderr)
}


