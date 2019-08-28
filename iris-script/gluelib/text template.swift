//
//  text template.swift
//  gluelib
//

import Foundation


// TO DO: should render funcs [re]throw?


@dynamicMemberLookup
protocol Node {
    var name: String { get }
    subscript(dynamicMember name: String) -> Node { get }
    func set(_ content: String)
    func map<S: Sequence>(_ values: S, using renderer: (Node, S.Element) -> Void)
    func map<S: Sequence, T>(_ values: S, with options: T, using renderer: (Node, S.Element, T) -> Void)
    func delete()
}

extension Node {

    func set<T>(_ content: T) {
        self.set(String(describing: content))
    }
}


class MultipleNode: Node {
    
    let name: String
    let elements: [Node]
    
    init(_ parent: Node, _ name: String, _ elements: [Node]) {
        if elements.isEmpty { print("Warning: no `\(name)` elements found in `\(parent.name)` node.") }
        self.name = name
        self.elements = elements
    }
    
    subscript(dynamicMember name: String) -> Node {
        return MultipleNode(self, name, self.elements.map{ $0[dynamicMember: name] }) // TO DO: flatMap?
    }
    
    func set(_ content: String) {
        for element in self.elements { element.set(content) }
    }
    
    func map<S: Sequence>(_ values: S, using renderer: (Node, S.Element) -> Void) {
        for element in self.elements { element.map(values, using: renderer) }
    }
    
    func map<S: Sequence, T>(_ values: S, with options: T, using renderer: (Node, S.Element, T) -> Void) {
        for element in self.elements { element.map(values, with: options, using: renderer) }
    }
    
    func delete() {
        for element in self.elements { element.delete() }
    }
}

let trimPattern = try! NSRegularExpression(pattern: "\\s+\\Z")

private extension String {
    
    func trimTrailingWhitespace() -> String {
        return trimPattern.stringByReplacingMatches(in: self, range: NSRange(location: 0, length: self.count), withTemplate: "")
    }
    
}

@dynamicMemberLookup
class TextNode: Node, CustomDebugStringConvertible {
    
    var debugDescription: String { return "<\(type(of:self))\n\(self.structure())>" }
    
    private let head: String
    private var elements = [TextNode]()
    internal var separator: String = ""
    private var body: String?
    
    let name: String
    
    init(head: String, name: String) {
        self.head = head
        self.name = name
    }
    
    internal func append(_ node: TextNode) {
        self.elements.append(node)
    }
    
    func copy() -> TextNode {
        let node = TextNode(head: self.head, name: self.name)
        node.elements = self.elements.map{$0.copy()}
        node.separator = self.separator
        return node
    }
    
    subscript(dynamicMember name: String) -> Node {
        let nodes = self.elements.filter{ $0.name == name }
        return nodes.count == 1 ? nodes[0] : MultipleNode(self, name, nodes)
    }
    
    func set(_ content: String) {
        self.body = content
    }
    
    func delete() {
        self.body = ""
    }
    func map<S: Sequence>(_ values: S, using renderer: (Node, S.Element) -> Void) {
        var result = [String]()
        for value in values {
            let node = self.copy()
            renderer(node, value)
            result.append(node._render())
        }
        self.body = result.joined(separator: self.separator)
    }
    
    func map<S: Sequence, T>(_ values: S, with options: T, using renderer: (Node, S.Element, T) -> Void) {
        var result = [String]()
        for value in values {
            let node = self.copy()
            renderer(node, value, options)
            result.append(node._render())
        }
        self.body = result.joined(separator: self.separator)
    }
    
    private func _render() -> String {
        return (self.body ?? self.elements.map{$0.render()}.joined(separator: ""))
    }
    
    func render() -> String {
        return self.head + self._render()
    }
    
    private func structure(_ depth: String = "") -> String {
        var result = [String]()
        if !self.name.isEmpty { result.append(depth + (self.elements.isEmpty ? "" : "+") + self.name + "\n") }
        for element in self.elements { result.append(element.structure(depth + "\t")) }
        if !self.elements.isEmpty && !self.name.isEmpty { result.append(depth + "-" + self.name + "\n") }
        return result.joined(separator: "")
    }
}


class TextTemplate<T>: TextNode {
    
    typealias Renderer<T> = (Node, T) -> Void // no generic varargs, so kludge it with single generic argument for now
    
    private let renderer: Renderer<T>

    init(_ template: String) {
        self.renderer = { (Node, Void) -> Void in () }
        super.init(head: "", name: "")
        self.parse(template)
    }
    
    init(_ template: String, using renderer: @escaping Renderer<T>) {
        self.renderer = renderer
        super.init(head: "", name: "")
        self.parse(template)
    }
    
    func render(_ options: T) -> String {
        let node = self.copy()
        self.renderer(node, options)
        return node.render()
    }
    
    private func parse(_ template: String) {
        // TO DO: fatalError if name in reserved names (copy, set, map, etc)
        // TO DO: customizable delimiters? (currently hardcoded as "««"+"»»"), option to disable auto-trimming
        var stack: [TextNode] = [self]
        var start = 0
        var isSep = false
        try! NSRegularExpression(pattern: "««([-+/]?)([a-z]+)»»", options: .caseInsensitive)
            .enumerateMatches(in: template, range: NSRange(location: 0, length: template.count)) {
            (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, _) -> Void in
            if let match = match {
                
                let form = (template as NSString).substring(with: match.range(at: 1))
                let name = (template as NSString).substring(with: match.range(at: 2))
                
                let m = match.range(at: 0)
                let s = (template as NSString).substring(with: NSRange(location: start, length: m.location - start))
                let prefix = form == "" ? s : s.trimTrailingWhitespace()
                start = m.location + m.length
                switch form {
                case "+":
                    let node = TextNode(head: prefix, name: name)
                    stack.last!.append(node)
                    stack.append(node)
                case "-":
                    if isSep {
                        stack.removeLast().separator = prefix
                        isSep = false
                    } else {
                        let node = stack.removeLast()
                        if node.name != name { fatalError("Mismatched tags: `+\(node.name)` and `-\(name)`") }
                        node.append(TextNode(head: prefix, name: ""))
                    }
                case "/":
                    if stack.last!.name != name { fatalError("Mismatched tags: `+\(stack.last!.name)` and `/\(name)`") }
                    isSep = true
                default:
                    let node = TextNode(head: prefix, name: name)
                    stack.last!.append(node)
                }
            }
        }
        if stack.count != 1 { fatalError("Malformed template.") }
        stack[0].append(TextNode(head: (template as NSString).substring(from: start), name: ""))
    }
}


