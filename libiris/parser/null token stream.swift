//
//  null token stream.swift
//  libiris
//

import Foundation



struct EndOfDocumentReader: DocumentReader {
    
    private let script: ImmutableScript
    
    var code: String { return script.code }

    let token = endOfCodeToken
    var location: Location { return (self.script.lines.count, 0) }
    
    init(_ script: ImmutableScript = ImmutableScript(lines: [], code: "")) {
        self.script = script
    }
    
    func next() -> DocumentReader {
        return self
    }
}


