//
//  formatter.swift
//  libiris
//
//  quick-n-dumb formatter for R&D, not final, use
//

import Foundation

// TO DO: also consider using lexer chain to provide basic keyword highlighting: that has the advantage that it can color code as user types as it only needs to recognize single tokens, not entire structures; thus lexer can provide pretty printer with a quick first-pass stage highlighting keyword/name/string/number/annotation semantics only, with further formatting (e.g. whitespace normalization, indentation, structural analysis) being applied as parser completes the larger structural units (lines, blocks)

// TO DO: implement a lexer-only PP for applying VT100 color codes in iris-shell (ideally this should be inserted into the live lexer chain right just before the parser stage; it may even be possible to run lexer stage as soon as certain characters are typed, e.g. space, allowing coloring-as-you-type, although that will need to have some external knowledge of quoting characters as words within annotations and string literals shouldn't be colored as keywords/identifiers, obvs)


// TO DO: being a Lisp-y language, a better approach to pretty printing is to evaluate an AST using a non-standard environment that returns handler-like objects which generate the corresponding source code; the same architecture can then be used for linting, transpiling, profiling, etc; non-standard environments can also introspect a live run-time environment to determine its available handlers and their interfaces and synthesize their own equivalents (also useful in linting and transpiling, and also a3c)
//
// one question is how to deal with blocks and other literals: if we want to substitute, we’ll have to provide API hooks for instantiating block-like/value-like values in parser; however, it would be better to use existing types and keep customization points limited to Environment and Handler: aside from avoiding extra complexity, this allows the same AST instance to be evaluated in multiple contexts (e.g. syntax-checking+pretty-printing, linting, and run-time) without having to clone/rebuild a separate copy for each (the only caveat being that linting/PP/etc handlers must not be captured by commands’ run-time Handler caching, but that’s controlled by Handler.isStaticBindable so shouldn't be a problem; of course, once run-time handlers are static-bound, that can't be [easily?] reversed)
//
// need to give some thought to how non-standard AST evaluation will interact with coercion system: obviously coercions should not apply to argument and return values in the conventional sense, as these values are just proxies for whatever task is really being performed; at a push, we can add a dedicated 'visitor' API to Value protocol, but that requires additional code rather than just reusing the code path we already have (it’s already painful having separate native and bridging APIs; if we can't reuse the native ones for other tasks then we should reconsider their design)
//

// TO DO: parenthesize operations to override operator precedence as needed

// TO DO: should Symbol implement default literalDescription that single-quotes anything outside of C-like identifiers (see .unquotedName); problem here is that names are defined by custom lexer stage, e.g. NameLexer, not base lexer (which only defines built-in punctuation and sub-word components)

// TO DO: language really needs annotation support before pretty printing can be implemented (otherwise PP will “disappear” comments, etc); also need to decide default layout rules, and how to annotate elective formatting (e.g. lists and records laid out vertically using LF separators instead of horizontally using commas; blocks laid out horizontally instead of vertically, non-essential parens)


let delimitingChars = linebreakCharacters.union(whitespaceCharacters).union(punctuationCharacters)


func isUnquotedName(_ string: String) -> Bool {
    // the easiest way to determine if a given name needs single-quoted is to see if it lexes as a single .unquotedName
    // TO DO: this assumes a standard lexer chain (c.f. IncrementalParser); eventually this should reuse [the relevant portion of] whatever lexer chain was actually used to parse the given code
    guard let lexer = BaseLexer(string) else { return false }
    let reader = NameReader(lexer)
    let (token, nextReader) = reader.next()
    if case .unquotedName(_) = token.form, case .endOfCode = nextReader.next().0.form { return true }
    return false
}



open class BasicFormatter {

    private var indentation = ""
    
    private(set) public var result = ""
    
    func append(_ string: String) {
        // TO DO: this is inserting extra chars into multi-line string literal, which is wrong
        if let first = string.first, let last = self.result.last {
            if !delimitingChars.contains(first) && !delimitingChars.contains(last) {
                self.result += " "
            } else if linebreakCharacters.contains(last) {
                self.result += self.indentation
            }
        }
        self.result += string.replacingOccurrences(of: "\n", with: "\n\(self.indentation)")
    }
    
    public init() { }
    
    //
    
    public func indent() {
        self.indentation += "\t"
    }
    public func dedent() {
        self.indentation.removeLast()
    }
    
    public func name(_ name: Symbol) {
        self.append(isUnquotedName(name.label) ? name.label : "‘\(name.label)’")
    }
    
    public func elements(_ items: [Value], _ separator: String) {
        self.walk(items[0])
        for item in items.dropFirst() {
            self.append(separator)
            self.walk(item)
        }
    }
    
    //

    public func opaque(_ value: Value) {
        self.append("«opaque_value: \(value)»")
    }

    public func atomic(_ value: AtomicValue) {
        switch value {
        case let v as Bool:
            self.append(v ? "true" : "false")
        case is NullValue:
            self.append("nothing")
        case let v as Symbol:
            self.append("#\(v.label)") // TO DO: add single quotes if label is empty or contains restricted chars
        default: self.opaque(value)
        }
    }
    
    public func scalar(_ value: ScalarValue) {
        switch value {
        case let v as Text:
            self.append(v.literalDescription())
        case let v as Number:
            self.append(v.literalDescription())
        case let v as Int:
            self.append(Number(v).literalDescription())
        case let v as Double:
            self.append(Number(v).literalDescription())
        case is NullValue:
            self.append("nothing")
        default: self.opaque(value)
        }
    }
    
    public func complex(_ value: ComplexValue) {
        self.opaque(value)
    }

    //
    
    public func command(_ value: Command) {
        if let match = value.operatorPattern {
            var operands = value.arguments.map{ $0.value }
            //print(operands)
            for p in match.exactMatch { p.format(operands: &operands, using: self) }
        } else {
            self.append(value.name.label) // TO DO: single-quote if needed
            // TO DO: use FP syntax for nested commands? or just parenthesize the entire command?
            // TO DO: if first argument is unlabeled and is a record, FP syntax MUST be used, e.g. `foo {{bar:1}, baz:…}`
            if !value.arguments.isEmpty {
                for (label, value) in value.arguments {
                    self.append(" ")
                    if !label.isEmpty { self.append("\(label.label): ") }
                    self.walk(value)
                }
            }
        }
    }
    
    public func block(_ value: Block) {
        let begin: String, ended: String, separator: String, isMultiLine: Bool
        if let (beginSymbol, endedSymbol) = value.operatorDefinition?.blockKeywords() {
            (begin, ended) = (beginSymbol.label, endedSymbol.label)
            isMultiLine = true
            separator = "\n"
        } else {
            (begin, ended) = ("(", ")")
            isMultiLine = value.data.count > 1
            separator = isMultiLine ? "\n" : ", "
        }
        self.append(begin)
        if !value.data.isEmpty {
            self.indent()
            if isMultiLine { self.append(separator) }
            self.elements(value.data, separator)
            self.dedent()
        }
        if isMultiLine { self.append(separator) }
        self.append(ended)
    }
    
    public func list(_ value: OrderedList) {
        self.append("[")
        if !value.data.isEmpty {
            self.elements(value.data, ", ")
        }
        self.append("]")
    }
    
    public func dict(_ value: KeyedList) {
        if value.data.isEmpty {
            self.append("[:]")
        } else {
            self.append("[")
            self.append(value.map{ "\(self.walk($0.value)): \(self.walk($1))" }.joined(separator: ", "))
            self.append("]")
        }
    }
        
    public func record(_ value: Record) {
        self.append("{")
        self.append(value.map{ ($0.isEmpty ? "" : "\($0.label): ") + "\(self.walk($1))" }.joined(separator: ", "))
        self.append("}")
    }
    
    //
    
    public func walk(_ value: Value) {
        switch value {
        case let value as OrderedList:  self.list(value)
        case let value as KeyedList:    self.dict(value)
        case let value as Block:        self.block(value)
        case let value as Command:      self.command(value)
        case let value as Record:       self.record(value)
        case let value as ComplexValue: self.complex(value)
        case let value as ScalarValue:  self.scalar(value)
        default:                        self.opaque(value)
        }
    }
}

//

extension Pattern {
 
    func format(operands: inout [Value], using formatter: BasicFormatter)  {
        switch self {
        case .keyword(let k):       formatter.append(k.name.label)
        case .sequence(let seq):    for p in seq { p.format(operands: &operands, using: formatter) }
        //case .name:                 return "NAME"
        //case .label:                return "LABEL"
        case .expression:           formatter.walk(operands.removeFirst())
        case .expressionLabeled:      fatalError("labeled expressions not yet supported")
        //case .token(let t):         return ".\(t)"
        case .testValue(_):         formatter.walk(operands.removeFirst())
        //case .delimiter:            return ", "
        //case .lineBreak:            return "LF"
        default: fatalError()
        }
    }
}





// terminal


public class VT100Formatter {
    
    enum VT100: String {
        
        var description: String { return self.rawValue }
        
        typealias RawValue = String
        case none         = ""
        case reset        = "\u{1b}[m"
        case bold         = "\u{1b}[1m"
        case faint        = "\u{1b}[2m"
        case underline    = "\u{1b}[4m"
        case red          = "\u{1b}[31m"
        case green        = "\u{1b}[32m"
        case yellow       = "\u{1b}[33m"
        case blue         = "\u{1b}[34m"
        case magenta      = "\u{1b}[35m"
        case cyan         = "\u{1b}[36m"
    }
    
    let nameStyle     = VT100.red.rawValue + VT100.bold.rawValue
    let labelStyle    = VT100.red.rawValue
    let operatorStyle = VT100.magenta.rawValue
    let numberStyle   = VT100.blue.rawValue
    let textStyle     = VT100.blue.rawValue
    let symbolStyle   = VT100.green.rawValue
    
    private var result = ""
    
    public init() { }
    
    private func faintUnderscores(_ s: Substring, _ color: String) -> String {
        return "\(color)\(s == "_" ? String(s) : s.replacingOccurrences(of: "_", with: "\u{1b}[2m_\u{1b}[m\(color)"))\u{1b}[m"
    }
    
    private var id = -1
    
    public func write(_ token: Token, _ id: Int) {
        // because LineReader.next() may be invoked more than once per state (e.g. when performing lookahead or rolling back when an optimistic match fails), we use an incrementing ID to filter out duplicate calls
        if id > self.id { self.id = id } else { return }
        if let ws = token.leadingWhitespace { result.append(String(ws)) }
        switch token.form {
        case .unquotedName:
            result.append(self.faintUnderscores(token.content, self.nameStyle))
        case .label:
            result.append(self.faintUnderscores(token.content, self.labelStyle))
        case .operatorName: // note: this currently applies to `nothing`, `true`/`false`, `π` as these are defined as atomic operators and the standard reductionForMatchedPattern() reduces down to command rather than to constant; see also TODO on `standard reducers.swift`
            result.append(self.faintUnderscores(token.content, self.operatorStyle))
        default:
            let code: String
            switch token.form {
            case .quotedName:                   code = self.nameStyle
            case .value(let v):
                switch v {
                case is Text:                   code = self.textStyle
                case is Int, is Double:         code = self.numberStyle
                case is Number:                 code = self.numberStyle
                case is Symbol:                 code = self.symbolStyle
                case is Bool, is NullValue:     code = self.symbolStyle
                default:                        code = ""
                }
            default:                            code = ""
            }
            result.append("\(code)\(token.content)\(code.isEmpty ? "" : "\u{1b}[m")")
        }
    }
    
    public func read() -> String {
        defer { self.result = "" }
        return self.result
    }
}


public struct VT100Reader: LineReader {
    
    private static var count: Int = 0
    
    let id: Int

    public var code: String { return self.reader.code }

    private let formatter: VT100Formatter
    private let reader: LineReader
    
    public init(_ reader: LineReader, _ formatter: VT100Formatter) {
        self.reader = reader
        self.formatter = formatter
        VT100Reader.count += 1
        self.id = VT100Reader.count
    }
    
    public func next() -> (Token, LineReader) {
        let (token, nextReader) = self.reader.next()
        formatter.write(token, self.id)
        return (token, VT100Reader(nextReader, self.formatter))
    }
}
