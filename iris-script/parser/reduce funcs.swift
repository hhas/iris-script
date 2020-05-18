//
//  reduce funcs.swift
//  iris-script
//

import Foundation


func show(stack: Parser.Stack, from index: Int) {
    print()
    print("STACK DUMP [\(index)..<\(stack.count)]:")
    for f in stack[index..<stack.count] { print(" ", f.reduction, "\t\t", f.matches) }
    print()
}

func reducePrefixOperator(stack: inout Parser.Stack, from index: Int) {

}

func reduceInfixOperator(stack: inout Parser.Stack, from index: Int) {

}

func reducePostfixOperator(stack: inout Parser.Stack, from index: Int) {

}

func reduceAtomOperator(stack: inout Parser.Stack, from index: Int) {

}

func reducePrefixOperatorWithConjunction(stack: inout Parser.Stack, from index: Int) {
    
}

func reducePrefixOperatorWithSuffix(stack: inout Parser.Stack, from index: Int) {
    
}



func reduceOrderedListLiteral(stack: inout Parser.Stack, from index: Int) {
    
}

func reduceKeyedListLiteral(stack: inout Parser.Stack, count: Int) {
    //show(stack: stack, from: index)
    let index = stack.count - count - 1
    var items = [KeyedList.Key: Value]()
    var i = index + 1 // ignore `[`
    while i < stack.count - 1 { // ignore `]`
        guard case .value(let k) = stack[i].reduction, let key = (k as? HashableValue)?.dictionaryKey else {
            fatalError("Bad Key") // should never happen
        }
        i += 2 // step over key + colon
        guard case .value(let value) = stack[i].reduction else {
            fatalError("Bad Value") // should never happen
        }
        i += 1 // step over value
        if case .separator(_) = stack[i].reduction { i += 1 }
        while case .lineBreak = stack[i].reduction { i += 1 }
        items[key] = value
        print(key, value)
    }
    stack.removeLast(count)
    stack.append((.value(KeyedList(items)), [])) // TO DO: should probably return reduced value
}

func reduceRecordLiteral(stack: inout Parser.Stack, from index: Int) {
    
}

func reduceGroupLiteral(stack: inout Parser.Stack, from index: Int) {
    
}

func reduceParenthesizedBlockLiteral(stack: inout Parser.Stack, from index: Int) {
    
}

func reduceCommandLiteral(stack: inout Parser.Stack, from index: Int) {
    
}


