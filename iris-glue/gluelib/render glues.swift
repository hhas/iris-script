//
//  render glues.swift
//  iris-glue
//
//  GlueRenderer implements API for reading .iris-glue files and writing .swift glue files
//

// TO DO: what about generating Info.plist for LIBNAME.iris-library bundle?

// TO DO: how best to support UTI and library version in file name? (versioning in file name allows multiple versions of a library to exist in same directory structure; however we’ll need to decide how loader should handle versioning)

// TO DO: what about operator patterns that do not map to commands, e.g. `do…done` reduces to an annotated `Block` with no underlying command so does not have a `swift_handler…requires…` glue definition; currently the `do…done` operator definition must be manually added to stdlib’s operator glue but really needs to be added by glue definition (otherwse a separate library loading method will need to be added for importing manually-coded definitions); similarly, atomic operators such as `nothing`, `true`, `false`, `π`, etc are defined as constants which also do not have underlying handlers but still require operator definitions

import Foundation
import iris


public struct GlueError: Error, CustomStringConvertible {

    public let description: String
}


typealias OpaqueHandlerGlues  = OpaqueValue<[Symbol:HandlerGlue]>
typealias OpaqueRecordGlues   = OpaqueValue<[Symbol:RecordGlue]>
typealias OpaqueCoercionGlues = OpaqueValue<[Symbol:CoercionGlue]>
typealias OpaqueEnumGlues     = OpaqueValue<[Symbol:EnumGlue]>

let handlerGluesKey  = Symbol(".handler_glues")
let recordGluesKey   = Symbol(".record_glues")
let coercionGluesKey = Symbol(".coercion_glues")
let enumGluesKey     = Symbol(".enum_glues")


func addGlueStore<T>(for key: Symbol, to env: ExtendedEnvironment) -> OpaqueValue<[Symbol:T]> {
    let glues = OpaqueValue([Symbol:T]())
    env.define(key, glues)
    return glues
}

public struct GlueRenderer {
    
    private let parser: IncrementalParser
    private let handlerGlues: OpaqueHandlerGlues
    private let recordGlues: OpaqueRecordGlues
    private let coercionGlues: OpaqueCoercionGlues
    private let enumGlues: OpaqueEnumGlues
    
    public let libraryName: String
    
    public init(libraryName: String) throws {
        // TO DO: validate library name (it should eventually be a UTI, although this will need further swizzling to be used in Swift glue’s load funcs’ names; mostly it depends on how we name the external entry points to primitive/native libraries so the library loader can find and call them)
        self.libraryName = libraryName
        let parser = IncrementalParser(withStdLib: false)
        self.parser = parser
        gluelib_loadHandlers(into: parser.env)
        gluelib_loadOperators(into: parser.env.operatorRegistry) // essential operators used in glue defs; these may be overwritten by stdlib operators
        stdlib_loadConstants(into: parser.env) // mostly needed for coercions
        gluelib_loadConstants(into: parser.env) // TO DO: for now this overrides [e.g.] stdlib-defined asText with asString; longer-term we need some way to indicate if generated glue code should use native vs primitive coercion
        self.handlerGlues = addGlueStore(for: handlerGluesKey, to: parser.env)
        self.recordGlues = addGlueStore(for: recordGluesKey, to: parser.env)
        self.coercionGlues = addGlueStore(for: coercionGluesKey, to: parser.env)
        self.enumGlues = addGlueStore(for: enumGluesKey, to: parser.env)
    }
    
    public func read(file: URL) throws {
        self.parser.read(try String(contentsOf: file, encoding: .utf8))
    }
    
    public func write(to outDir: URL) throws {
        guard let script = self.parser.ast() else {
            let errors = self.parser.errors()
            if errors.isEmpty { throw GlueError(description: "Found syntax errors in glue.") }
            throw GlueError(description: "Found syntax errors in glue: \(errors)")
        }
        let _ = (try script.eval(in: parser.env, as: asAnything))
        let handlerGlues = self.handlerGlues.data.values.sorted{$0.signature < $1.signature}
        let recordGlues = self.recordGlues.data.values.sorted{$0.swiftType < $1.swiftType}
        let coercionGlues = self.coercionGlues.data.values.sorted{$0.swiftType < $1.swiftType}
        let enumGlues = self.enumGlues.data.values.sorted{$0.swiftType < $1.swiftType}
        let operatorGlues = handlerGlues + coercionGlues.compactMap{ $0.constructor }
        try handlersTemplate.render((self.libraryName, handlerGlues),
                                    to: "\(self.libraryName)_handlers.swift", in: outDir)
        try handlerStubsTemplate.render((self.libraryName, handlerGlues),
                                        to: "\(self.libraryName) handler stubs.swift", in: outDir)
        try recordsTemplate.render((self.libraryName, recordGlues),
                                   to: "\(self.libraryName)_records.swift", in: outDir)
        try recordStubsTemplate.render((self.libraryName, recordGlues),
                                       to: "\(self.libraryName) record stubs.swift", in: outDir)
        try coercionsTemplate.render((self.libraryName, coercionGlues),
                                     to: "\(self.libraryName)_coercions.swift", in: outDir)
        try enumsTemplate.render((self.libraryName, enumGlues),
                                 to: "\(self.libraryName)_enums.swift", in: outDir)
        try enumStubsTemplate.render((self.libraryName, enumGlues),
                                     to: "\(self.libraryName) enum stubs.swift", in: outDir)
        try operatorsTemplate.render((self.libraryName, operatorGlues),
                                     to: "\(self.libraryName)_operators.swift", in: outDir)
    }
}


extension TextTemplate {
    
    func render(_ options: T, to file: String, in directory: URL) throws {
        try self.render(options).write(to: directory.appendingPathComponent(file), atomically: true, encoding: .utf8)
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


