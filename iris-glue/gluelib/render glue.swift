//
//  glue renderer.swift
//  iris-glue
//
//  GlueRenderer implements API for reading .iris-glue files and writing .swift glue files
//

// TO DO: what about generating Info.plist for LIBNAME.iris-library bundle?

// TO DO: how best to support UTI and library version in file name? (versioning in file name allows multiple versions of a library to exist in same directory structure; however we’ll need to decide how loader should handle versioning)

// TO DO: should glue files include date generated and glue version as code comments and/or API? or is that information more appropriate to Info.plist?

import Foundation
import iris


public struct GlueError: Error, CustomStringConvertible {

    public let description: String
}


typealias OpaqueHandlerGlues = OpaqueValue<[Symbol:HandlerGlue]>

let asHandlerGlues = AsComplex<OpaqueHandlerGlues>(name: "opaque_handler_glues")

let handlerGluesKey = Symbol(".handler_glues")

typealias OpaqueHandlerInterface = OpaqueValue<HandlerInterface?>

let currentHandlerInterfaceKey = Symbol(".handler_interface")


public struct GlueRenderer {
    
    private let parser: IncrementalParser
    private let handlerGlues: OpaqueHandlerGlues
    
    public let libraryName: String
    
    public init(libraryName: String) throws {
        // TO DO: validate library name (it should eventually be a UTI, although this will need further swizzling to be used in Swift glue’s load funcs’ names; mostly it depends on how we name the external entry points to primitive/native libraries so the library loader can find and call them)
        self.libraryName = libraryName
        let parser = IncrementalParser(withStdLib: false)
        gluelib_loadHandlers(into: parser.env) // TO DO: what handlers must gluelib define? Q. what about optionally loading stdlib handlers (and operators?) into a parent scope, for metaprogramming use? (this option should be off by default, not least to allow unimpeded generation of stdlib glue, and because it adds complexity that straightforward glue definitions don’t need)
        gluelib_loadOperators(into: parser.env.operatorRegistry) // essential operators used in glue defs; these may be overwritten by stdlib operators
        gluelib_loadConstants(into: parser.env)
        stdlib_loadConstants(into: parser.env) // mostly needed for coercions
        self.parser = parser
        let handlerGlues = OpaqueHandlerGlues([:])
        parser.env.define(handlerGluesKey, handlerGlues)
        let handlerInterface = OpaqueHandlerInterface(nil)
        parser.env.define(currentHandlerInterfaceKey, handlerInterface)
        self.handlerGlues = handlerGlues
    }
    
    public func read(file: URL) throws {
        self.parser.read(try String(contentsOf: file, encoding: .utf8))
    }
    
    public func write(to outDir: URL) throws {
        guard let script = self.parser.ast() else {
            throw GlueError(description: "Found errors in glue: \(self.parser.errors())")
        }
        let _ = (try script.eval(in: parser.env, as: asAnything))
        guard let handlerGlues = (parser.env.get(handlerGluesKey) as? OpaqueHandlerGlues) else {
            throw GlueError(description: "Can’t get \(handlerGluesKey.label).")
        }
        let handlersGlueFile = outDir.appendingPathComponent("\(self.libraryName)_handlers.swift")
        let operatorsGlueFile = outDir.appendingPathComponent("\(self.libraryName)_operators.swift")
        let handlersStubFile = outDir.appendingPathComponent("\(self.libraryName) stubs.swift")
        let glues = handlerGlues.data.values.sorted{$0.name < $1.name}
        try handlersTemplate.render((self.libraryName, glues))
            .write(to: handlersGlueFile, atomically: true, encoding: .utf8)
        try operatorsTemplate.render((self.libraryName, glues))
            .write(to: operatorsGlueFile, atomically: true, encoding: .utf8)
        try handlerStubsTemplate.render((self.libraryName, glues))
            .write(to: handlersStubFile, atomically: true, encoding: .utf8)
    }
}


// convenience function for converting a single glue file

extension URL {
    var isGlueFile: Bool { return self.lastPathComponent.lowercased().hasSuffix(".iris-glue") }
}

extension GlueRenderer {
    
    func read(_ url: URL, _count: Int = 0) throws -> Int {
        var count = _count
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw GlueError(description: "Glue file not found: \(url.path)")
        }
        if isDirectory.boolValue {
            for url in try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).sorted(by: {$0.lastPathComponent < $1.lastPathComponent}) {
                if url.isGlueFile { count += try self.read(url) }
            }
        } else if url.isGlueFile {
            print("Reading glue file: \(url.lastPathComponent)")
            try self.read(file: url)
            count += 1
        }
        return count
    }
}

public func renderGlue(glueFile: URL, outDir: URL) throws {
    var isDirectory: ObjCBool = false
    if !FileManager.default.fileExists(atPath: outDir.path, isDirectory: &isDirectory) {
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: false)
    } else if !isDirectory.boolValue {
        throw GlueError(description: "Output path is not a directory: \(glueFile.path)")
    }
    // TO DO: validate library name
    let glueName = glueFile.lastPathComponent
    guard let offset = glueName.lastIndex(of: ".") else { throw GlueError(description: "Bad glue file name (expected `LIBNAME.iris-glue`): \(glueFile.lastPathComponent)") }
    let name = String(glueName.prefix(upTo: offset))
    let renderer = try GlueRenderer(libraryName: name)
    let count = try renderer.read(glueFile)
    if count == 0 {
        throw GlueError(description: "No glue files found in \(glueFile)")
    } else {
        print("Read \(count) glue file[s].")
    }
    try renderer.write(to: outDir)
    print("Wrote glue files to:", outDir.path)
}


