//
//  main.swift
//  profile
//

import Foundation




extension IncrementalParser {
    
    func loadGlue(_ file: URL) throws {
        let s = try String(contentsOf: file, encoding: .utf8)
        self.read(s)
        print("read", Date().timeIntervalSince(t3))
        guard let script = self.ast() else {
            let errors = self.errors()
            if errors.isEmpty { throw InternalError(description: "Found syntax errors in glue.") }
            throw InternalError(description: "Found syntax errors in glue: \(errors)")
        }
       // let t2 = Date()
       // let _ = try script.eval(in: env, as: asAnything)
       // print("eval", Date().timeIntervalSince(t2))
    }
}



func test() {
    
    let parser = IncrementalParser(withStdLib: false)
    let registry = parser.env.operatorRegistry
    registry.add(["shortcut_action", .expression, "requires", .expression], 180)
    registry.add([.expression, .keyword("returning"), .expression], 300)
    registry.add([.expression, "as", .expression], 350)
    registry.add([.expression, "OR", .expression], 360)
    registry.add([.expression, "but_not", .expression], 360)
    registry.add([.keyword("optional"), .optional(.expression), .optional([.keyword("with_default"), .boundExpression("with_default", "default_value")])], 1500, .left)
    registry.add([.keyword("record"), .optional(.boundExpression("of_type", "record_type"))], 1500, .left)

    do {
    try parser.loadGlue(URL(fileURLWithPath: "/Users/has/swift/iris-script/shortcuts/glues/shortcut actions.iris-glue"))
        print("ok")
    } catch {
        print(error)
    }
}


test()

