//
//  incremental parser.swift
//  libiris
//
//  temporary until EditableScript is finished
//

// TO DO: rethink APIs for composing and using per-line and per-block lexers (current design is confusing and a pain to work with; the goal is to record progress as immutable readers, each of which encapsulates one token and the reader for the next, but if the adapter chain never needs to change itself mid-parse then new readers can probably be vended without having to reconstruct the entire adapter pipeline every single time, instead using existing shift-reduce mechanics to partially reduce the original token stream, with a push-API at one end for appending new code and a pull-API at the end for extracting tokens); it also doesn't help that there are different APIs for single-line-only and multi-line-capable readers (although one could also argue that multi-line readers are getting into parser’s territory; the only distinction being that they still only deal with atomic structures, strings and annotations, unlike the complex nested structures that demand a full parser)


// TO DO: multiline string literals don't work correctly


import Foundation


// Q. mutating the source lexer in-place defeats purpose of immutable lexer adapters; would it not be simpler to start a new lexer chain for the new [line of] code and assign that to Parser.current?


public struct IncrementalDocumentReader: DocumentReader {
    
    private let lexer: LineReader
    
    public var code: String { self.lexer.code }
    
    public let token: Token
    
    public var location: Location = (0, 0)
    
    init(lexer: LineReader) {
        (self.token, self.lexer) = lexer.next()
    }
    
    public func next() -> DocumentReader {
        return IncrementalDocumentReader(lexer: self.lexer)
    }
}

struct EndOfLineReader: DocumentReader { // outputs .linebreak before other tokens, which may not be ideal
    
    var code: String { return "" }

    let token = lineBreakToken
    var location: Location { return (0, 0) }
    
    let nextReader: DocumentReader
    
    func next() -> DocumentReader {
        return self.nextReader
    }
}



public class IncrementalParser {
    
    typealias LineReaderAdapter = (LineReader) -> LineReader
    
    public let env = ExtendedEnvironment()
    
    private let operatorReader: LineReaderAdapter
    private var parser: Parser
    
    private var lastToken: Token.Form?

    public func lineReaderAdapter(_ lexer: LineReader) -> LineReader {
        return NumericReader(self.operatorReader(NameModifierReader(NameReader(QuoteReader(UnicodeReader(lexer))))))
    }
    
    public var adapterHook: (LineReader) -> LineReader = { $0 }
    
    public init(withStdLib useStdlib: Bool = true) {
        if useStdlib {
            stdlib_loadHandlers(into: self.env)
            stdlib_loadOperators(into: self.env.operatorRegistry)
            stdlib_loadConstants(into: self.env)
        }
        self.operatorReader = newOperatorReader(for: self.env.operatorRegistry)
        self.parser = Parser(tokenStream: EndOfDocumentReader(), operatorRegistry: self.env.operatorRegistry)
    }
    
    public func clear() {
        self.parser = Parser(tokenStream: EndOfDocumentReader(), operatorRegistry: self.env.operatorRegistry)
    }
    
    func newLexer(_ code: String) -> LineReader? {
        if let baseLexer = BaseLexer(code) {
            return self.adapterHook(self.lineReaderAdapter(baseLexer))
        } else {
            return nil
        }
    }
    
    public func read(_ code: String) {
        // TO DO: if last token was partial quote then create RemainingStringQuoteReader to continue that
        let lexer: LineReader
        if case .beginningOfQuote = self.lastToken {
            lexer = RemainingStringQuoteReader(code, resumeLexer: { self.newLexer($0) ?? EndOfCodeReader() })
        } else if case .middleOfQuote = self.lastToken {
            lexer = RemainingStringQuoteReader(code, resumeLexer: { self.newLexer($0) ?? EndOfCodeReader() })
        } else if let baseLexer = BaseLexer(code) {
            lexer = self.adapterHook(self.lineReaderAdapter(baseLexer))
        } else {
            return
        }
        let doc = IncrementalDocumentReader(lexer: lexer)
        try! self.parser.replaceReader(EndOfLineReader(nextReader: doc))
        self.parser.parseScript()
        self.lastToken = self.parser.tokenStack.last?.form
        //print("lastToken:", self.lastToken as Any); print()
    }
    
    public func ast() -> AbstractSyntaxTree? { // being a “stealth-Lisp”, an iris AST is just a native Value (currently a Block) // TO DO: once annotation support is implemented, annotation and layout information will also be attached to the AST value (we'll probably want to make it a class for this so that top-level annotations can be stored more easily; also, while Command is a class so easily annotatable, other [literal] values are generally structs so would require wrappers to annotate, which we want to avoid as traversing AST is heavily recursive as it is; putting these annotations in AST as well will avoid adding run-time overheads, though will increase complexity as each indirect annotation will need some way to reference the Value to which it applies)
        return self.parser.ast()
    }
    
    public func errors() -> [NativeError] {
        return self.parser.errors()
    }
    
    public func incompleteBlocks() -> [(startIndex: Int, startBlock: String, stopBlock: String)] {
        return self.parser.incompleteBlocks()
    }
}

