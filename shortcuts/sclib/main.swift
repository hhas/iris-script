//
//  main.swift
//  sclib
//

import Foundation
import iris

// TO DO: iris parser could use some profiling (120KB actions glue file takes ~4sec to parse)


let args = CommandLine.arguments

if args.count != 2 {
    print("USAGE: sclib GLUEDIR")
    print(args)
    exit(1)
}


extension IncrementalParser {
    
    func loadGlue(_ file: URL) throws {
        self.read(try String(contentsOf: file, encoding: .utf8))
        guard let script = self.ast() else {
            let errors = self.errors()
            if errors.isEmpty { throw InternalError(description: "Found syntax errors in glue.") }
            throw InternalError(description: "Found syntax errors in glue: \(errors)")
        }
        let _ = try script.eval(in: env, as: asAnything)
        self.clear()
    }
}

func importGlue(from dir: URL) {
    let parser = IncrementalParser(withStdLib: false)
    let env = parser.env
    stdlib_loadCoercions(into: env)
    stdlib_loadConstants(into: env)
    sclib_loadHandlers(into: env)
    sclib_loadCoercions(into: env)
    sclib_loadOperators(into: env.operatorRegistry)
    do {
        try parser.loadGlue(dir.appendingPathComponent("shortcut types.iris-glue"))
        try parser.loadGlue(dir.appendingPathComponent("shortcut actions.iris-glue"))
    } catch {
        print("Failed: \(error)")
    }
    //print(env.frame.keys)
    parser.read("""
        
        random_number {minimum: 1, maximum: 10}
        
    """)
    guard let script = parser.ast() else { print("Error:", parser.errors()); exit(5) }
    do {
        let result = try script.eval(in: env, as: asAnything)
        print("Result:", result)
    } catch {
        print("Error:", error); exit(5)
    }
}


importGlue(from: URL(fileURLWithPath: args[1]))
