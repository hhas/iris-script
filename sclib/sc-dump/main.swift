//
//  main.swift
//  sclib
//

import Foundation
import iris


let args = CommandLine.arguments

if args.count != 3 {
    print("USAGE: sc-dump SRC DEST")
    print(args)
    exit(1)
}

let src = args[1]
let dest = args[2]

print("reading", src)
do {
    guard let data = InputStream(url: URL(fileURLWithPath: src)) else {
        throw InternalError(description: "Can’t open \(src)")
    }
    data.open()
    defer { data.close() }
    guard let actions = try PropertyListSerialization.propertyList(with: data, format: nil) as? [String:Dict] else {
        throw InternalError(description: "Can’t read \(src)")
    }
    
    
    var glue = try FileHandle(forWritingTo: URL(fileURLWithPath: dest))
    glue.truncateFile(atOffset: 0)
    defer { glue.closeFile() }
    
    for (id, dict) in actions.sorted(by: {$0.key.lowercased() < $1.key.lowercased()}) {
        if let s = readAction(id: id, action: dict) {
            glue.write(s.data(using: .utf8)!)
        }
    }
    print("wrote", dest)
} catch {
    print("failed", error)
}
