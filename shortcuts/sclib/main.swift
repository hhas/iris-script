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
        let s = try String(contentsOf: file, encoding: .utf8)
        let t3 = Date()
        self.read(s)
        print("read", Date().timeIntervalSince(t3))
        guard let script = self.ast() else {
            let errors = self.errors()
            if errors.isEmpty { throw InternalError(description: "Found syntax errors in glue.") }
            throw InternalError(description: "Found syntax errors in glue: \(errors)")
        }
        let t2 = Date()
        let _ = try script.eval(in: env, as: asAnything)
        print("eval", Date().timeIntervalSince(t2))
    }
}

func importGlue(from dir: URL) {
    let t = Date()
    let parser = IncrementalParser(withStdLib: false)
    let env = parser.env
    stdlib_loadCoercions(into: env)
    stdlib_loadConstants(into: env)
    sclib_loadHandlers(into: env)
    sclib_loadCoercions(into: env)
    sclib_loadOperators(into: env.operatorRegistry)
    print(Date().timeIntervalSince(t))
    do {
        try parser.loadGlue(dir.appendingPathComponent("shortcut types.iris-glue"))
        try parser.loadGlue(dir.appendingPathComponent("shortcut actions.iris-glue"))
    } catch {
        print("Failed: \(error)")
    }
    //print(env.frame.keys)
}


let t = Date()
importGlue(from: URL(fileURLWithPath: args[1]))
print(Date().timeIntervalSince(t))
