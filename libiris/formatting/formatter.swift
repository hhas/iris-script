//
//  formatter.swift
//  libiris
//
//  quick-n-dumb formatter for R&D, not final, use
//

import Foundation

// TO DO: lexer-based formatting should apply on entering whitespace/delimiters for basic styling-as-you-type; parser should, on completing reductions, yield pretty printed representation of that reduction (PP may use same basic styling as per-token formatting, or it may provide more sophisticated analysis, e.g. `tell TARGET to ACTION` operator’s action block may style commands whose handlers are defined in TARGET differently to those whose handlers come from script context, although that requires side-effect-free partial evaluation of target expression outside of run-time, which in turn requires machine-readable annotations to operator description and/or command/handler)


// TO DO: also consider using lexer chain to provide basic keyword highlighting: that has the advantage that it can color code as user types as it only needs to recognize single tokens, not entire structures; thus lexer can provide pretty printer with a quick first-pass stage highlighting keyword/name/string/number/annotation semantics only, with further formatting (e.g. whitespace normalization, indentation, structural analysis) being applied as parser completes the larger structural units (lines, blocks)

// TO DO: implement a lexer-only PP for applying VT100 color codes in iris-talk (ideally this should be inserted into the live lexer chain right just before the parser stage; it may even be possible to run lexer stage as soon as certain characters are typed, e.g. space, allowing coloring-as-you-type, although that will need to have some external knowledge of quoting characters as words within annotations and string literals shouldn't be colored as keywords/identifiers, obvs)


// TO DO: being a Lisp-y language, a better approach to pretty printing is to evaluate an AST using a non-standard environment that returns handler-like objects which generate the corresponding source code; the same architecture can then be used for linting, transpiling, profiling, etc; non-standard environments can also introspect a live run-time environment to determine its available handlers and their interfaces and synthesize their own equivalents (also useful in linting and transpiling, and also a3c)
//
// one question is how to deal with blocks and other literals: if we want to substitute, we’ll have to provide API hooks for instantiating block-like/value-like values in parser; however, it would be better to use existing types and keep customization points limited to Environment and Handler: aside from avoiding extra complexity, this allows the same AST instance to be evaluated in multiple contexts (e.g. syntax-checking+pretty-printing, linting, and run-time) without having to clone/rebuild a separate copy for each (the only caveat being that linting/PP/etc handlers must not be captured by commands’ run-time Handler caching, but that’s controlled by Handler.isStaticBindable so shouldn't be a problem; of course, once run-time handlers are static-bound, that can't be [easily?] reversed)
//
// need to give some thought to how non-standard AST evaluation will interact with coercion system: obviously coercions should not apply to argument and return values in the conventional sense, as these values are just proxies for whatever task is really being performed; at a push, we can add a dedicated 'visitor' API to Value protocol, but that requires additional code rather than just reusing the code path we already have (it’s already painful having separate native and bridging APIs; if we can't reuse the native ones for other tasks then we should reconsider their design)
//

// TO DO: parenthesize operations to override operator precedence as needed

// TO DO: should Symbol implement default literalDescription that single-quotes anything outside of C-like identifiers (see .unquotedName); problem here is that names are defined by custom lexer stage, e.g. NameLexer, not base lexer (which only defines built-in punctuation and sub-word components)

// TO DO: language really needs annotation support before pretty printing can be implemented (otherwise PP will “disappear” comments, etc); also need to decide default layout rules, and how to annotate elective formatting (e.g. lists and records laid out vertically using LF separators instead of horizontally using commas; blocks laid out horizontally instead of vertically, non-essential parens)



private let delimitingChars = linebreakCharacters.union(whitespaceCharacters).union(punctuationCharacters)

// this is a conservative subset of identifier characters
private let startOfIdentifier = wordCharacters.union(underscoreCharacters)
private let restOfIdentifier = startOfIdentifier.union(digitCharacters)


public func quotableName(_ name: String) -> String {
    guard let c = name.first else { return "‘’" }
    if name.conforms(to: legalNameCharacters) {
        return (startOfIdentifier ~= c && name.conforms(to: restOfIdentifier)) ? name : "‘\(name)’"
    } else {
        // TO DO: what to insert if name contains single quotes, linebreaks, or other invalid characters?
        return name.map{ legalNameCharacters ~= $0 ? String($0) : "_" }.joined(separator: "")
    }
}


extension Environment {
    
    func defines(name: Symbol) -> Bool {
        return self.frame[name] != nil
    }
}

func toNameStyle(env: Environment?, name: Symbol) -> String {
    return (env?.defines(name: name) ?? false) ? userNameStyle : nameStyle
}


open class BasicFormatter {

    private var indentation = ""
    let env: Environment?
        
    func append(_ string: String, to result: inout String) {
        if let first = string.first, let last = result.last {
            if !delimitingChars.contains(first) && !delimitingChars.contains(last) {
                result += " "
            } else if linebreakCharacters.contains(last) {
                result += self.indentation
            }
        }
        result += string.replacingOccurrences(of: "\n", with: "\n\(self.indentation)") // TO DO: this is inserting extra chars into multi-line string literal, which is wrong
    }
    
    public init(env: Environment? = nil) {
        self.env = env
    }
    
    //
    
    public func indent() {
        self.indentation += "\t"
    }
    public func dedent() {
        self.indentation.removeLast()
    }
    
    public func elements(_ items: [Value], _ separator: String, to result: inout String) {
        result += self.format(items[0])
        for item in items.dropFirst() {
            result += separator
            result += self.format(item)
        }
    }
    
    //

    public func opaque(_ value: Value) -> String {
        return "«opaque_value: \(value)»"
    }
    
    public func formatOperator(_ name: Symbol) -> String {
        return name.label
    }
    
    //

    public func atomic(_ value: AtomicValue) -> String {
        switch value {
        case let v as Symbol:               return "#\(quotableName(v.label))"
        case let v as LiteralConvertible:   return v.literalDescription
        default:                            return self.opaque(value)
        }
    }
    
    public func scalar(_ value: ScalarValue) -> String {
        switch value {
        case let v as LiteralConvertible:   return v.literalDescription
        default:                            return self.opaque(value)
        }
    }
    
    public func complex(_ value: ComplexValue) -> String {
        return self.opaque(value)
    }

    //
    
    public func command(_ value: Command) -> String {
        var result = ""
        if let match = value.operatorPattern {
            var operands = value.arguments.map{ $0.value }
            //print(operands)
            result += match.exactMatch.map{ $0.formatOperation(for: &operands, in: self) }.joined(separator: " ")
        } else {
            result += quotableName(value.name.label)
            // TO DO: use FP syntax for nested commands? or just parenthesize the entire command?
            // TO DO: if first argument is unlabeled and is a record, FP syntax MUST be used, e.g. `foo {{bar:1}, baz:…}`
            if !value.arguments.isEmpty {
                for (label, value) in value.arguments {
                    result += " "
                    if !label.isEmpty { result += "\(quotableName(label.label)): " }
                    result += self.format(value)
                }
            }
        }
        return result
    }
    
    public func block(_ value: Block) -> String {
        var result = ""
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
        result += begin
        if !value.data.isEmpty {
            self.indent()
            if isMultiLine { result += separator }
            self.elements(value.data, separator, to: &result)
            self.dedent()
        }
        if isMultiLine { result += separator }
        result += ended
        return result
    }
    
    public func list(_ value: OrderedList) -> String {
        var result = "["
        if !value.data.isEmpty {
            self.elements(value.data, ", ", to: &result)
        }
        result += "]"
        return result
    }
    
    public func dict(_ value: KeyedList) -> String {
        var result = ""
        if value.data.isEmpty {
            result += "[:]"
        } else {
            result += "["
            result += value.map{ "\(self.format($0.value)): \(self.format($1))" }.joined(separator: ", ")
            result += "]"
        }
        return result
    }
        
    public func record(_ value: Record) -> String {
        var result = "{"
        result += value.map{
            ($0.isEmpty ? "" : "\($0.label): ") + self.format($1)
        }.joined(separator: ", ")
        return result + "}"
    }
    
    //
    
    public func format(_ value: Value) -> String {
        switch value {
        case let value as OrderedList:  return self.list(value)
        case let value as KeyedList:    return self.dict(value)
        case let value as Block:        return self.block(value)
        case let value as Command:      return self.command(value)
        case let value as Record:       return self.record(value)
        case let value as ComplexValue: return self.complex(value)
        case let value as ScalarValue:  return self.scalar(value)
        case let value as AtomicValue:  return self.atomic(value)
        default:                        return self.opaque(value)
        }
    }
}

//

extension Pattern { // this is assumed to be the exact operator pattern from which Command was created
 
    func formatOperation(for operands: inout [Value], in formatter: BasicFormatter) -> String {
        switch self {
        case .keyword(let k):       return formatter.formatOperator(k.name)
        case .sequence(let seq):    return seq.map{ $0.formatOperation(for: &operands, in: formatter) }.joined(separator: " ") // shouldn’t be needed
        //case .name:                 return "NAME"  // should only be used in command matchers
        //case .label:                return "LABEL" // should only be used in command matchers
        case .expression:           return formatter.format(operands.removeFirst())
        case .boundExpression:      return formatter.format(operands.removeFirst()) // TO DO: confirm this works as intended
        //case .token(let t):         return ".\(t)" // should only be used in block value matchers
        case .testValue(_):         return formatter.format(operands.removeFirst())
        //case .delimiter:            return ", "    // should only be used in block value matchers
        //case .lineBreak:            return "LF"    // should only be used in block value matchers
        default: fatalError("Can’t formatOperation() for complex/unmatched patterns.")
        }
    }
}





// terminal


enum VT100: String {
    
    var description: String { return self.rawValue }
    
    typealias RawValue = String
    case none         = ""
    case reset        = "\u{1b}[m"
    case bold         = "\u{1b}[1m"
    case faint        = "\u{1b}[2m"
    case underline    = "\u{1b}[4m"
    case red          = "\u{1b}[31m"
    case darkRed      = "\u{1b}[38;5;52m"
    case orange       = "\u{1b}[38;5;166m"
    case green        = "\u{1b}[38;5;28m"
    case yellow       = "\u{1b}[33m"
    case blue         = "\u{1b}[34m"
    case magenta      = "\u{1b}[35m"
    case violet       = "\u{1b}[38;5;92m"
    case cyan         = "\u{1b}[36m"
}

let nameStyle     = VT100.red.rawValue
let userNameStyle = nameStyle + VT100.bold.rawValue
let labelStyle    = VT100.orange.rawValue + VT100.bold.rawValue // e.g. `some_command x some_arg: y` shows command and argument names in similar colors
let operatorStyle = VT100.violet.rawValue
let numberStyle   = VT100.blue.rawValue
let textStyle     = VT100.blue.rawValue
let symbolStyle   = VT100.green.rawValue // TO DO: once implemented, global `@NAME...` namespace identifiers should also use this color; this helps associate "@MENTIONS" and "#HASHTAG" as being 'special' structures; the hashtag may be recolored blue-green to place it conceptually between a global name and a literal (`#` escapes an identifier so it isn't automatically looked up when evaluated but instead returns itself, whereas global identifier is an expression that resolves to a global object or sub-object bound to that particular name)
let resetStyle    = VT100.reset.rawValue




public class VT100ValueFormatter: BasicFormatter {
    
    public override func formatOperator(_ name: Symbol) -> String {
        return "\(operatorStyle)\(name.label)\(resetStyle)"
    }
    
    public override func atomic(_ value: AtomicValue) -> String {
        return "\(value is Symbol ? symbolStyle : operatorStyle)\(super.atomic(value))\(resetStyle)"
    }
    
    public override func scalar(_ value: ScalarValue) -> String {
        return "\(value is NumericValue ? numberStyle : textStyle)\(super.scalar(value))\(resetStyle)"
    }
        
    public override func record(_ value: Record) -> String {
        var result = "{"
        result += value.map{
            ($0.isEmpty ? "" : "\(labelStyle)\($0.label):\(resetStyle) ") + self.format($1)
        }.joined(separator: ", ")
        return result + "}"
    }
    
    public override func command(_ value: Command) -> String {
        var result = "(" // options to use FP syntax (record arg) vs LP syntax (parensed as needed) vs mixed
        if let match = value.operatorPattern {
            // TO DO: operator formatting needs to compare precedence/associativity of adjacent operations and parenthesize as needed (ditto for LP commands, which are effectively prefix operators of commandPrecedence)
            var operands = value.arguments.map{ $0.value }
            //print(operands)
            result += match.exactMatch.map{ $0.formatOperation(for: &operands, in: self) }.joined(separator: " ")
        } else {
            result += "\(toNameStyle(env: self.env, name: value.name))\(quotableName(value.name.label))\(resetStyle)"
            // TO DO: use FP syntax for nested commands? or just parenthesize the entire command?
            // TO DO: if first argument is unlabeled and is a record, FP syntax MUST be used, e.g. `foo {{bar:1}, baz:…}`
            if !value.arguments.isEmpty {
                for (label, value) in value.arguments {
                    result += " "
                    if !label.isEmpty { result += "\(labelStyle)\(quotableName(label.label)):\(resetStyle) " }
                    result += self.format(value)
                }
            }
        }
        return result + ")"
    }
    
}



public class VT100TokenFormatter { // used by VT100Reader; applies VT100 codes to token stream
    
    private var result = ""
    let env: Environment?
    
    public init(env: Environment? = nil) {
        self.env = env
    }
    
    private func faintUnderscores(_ s: Substring, _ color: String) -> String {
        return "\(color)\(s == "_" ? String(s) : s.replacingOccurrences(of: "_", with: "\u{1b}[2m_\u{1b}[m\(color)"))\u{1b}[m"
    }
    
    private var id = -1
    
    public func write(_ token: Token, _ id: Int) {
        // because LineReader.next() may be invoked more than once per state (e.g. when performing lookahead or rolling back when an optimistic match fails), we use an incrementing ID to filter out duplicate calls
        if id > self.id { self.id = id } else { return }
        if let ws = token.leadingWhitespace { result.append(String(ws)) }
        switch token.form {
        case .unquotedName(let name):
            result.append(self.faintUnderscores(token.content, toNameStyle(env: self.env, name: name)))
        case .label:
            result.append(self.faintUnderscores(token.content, labelStyle))
        case .operatorName: // note: this currently applies to `nothing`, `true`/`false`, `π` as these are defined as atomic operators and the standard reductionForMatchedPattern() reduces down to command rather than to constant; see also TODO on `standard reducers.swift`
            result.append(self.faintUnderscores(token.content, operatorStyle))
        default:
            let code: String
            switch token.form {
            case .quotedName(let name):         code = toNameStyle(env: self.env, name: name)
            case .value(let v):
                switch v {
                case is Text:                   code = textStyle
                case is Int, is Double:         code = numberStyle
                case is Number:                 code = numberStyle
                case is Symbol:                 code = symbolStyle
                case is Bool, is NullValue:     code = symbolStyle
                default:                        code = ""
                }
            default:                            code = ""
            }
            result.append("\(code)\(token.content)\(code.isEmpty ? "" : "\(resetStyle)")")
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

    private let formatter: VT100TokenFormatter
    private let reader: LineReader
    
    public init(_ reader: LineReader, _ formatter: VT100TokenFormatter) {
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
