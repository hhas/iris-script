//
//  token stack.swift
//  iris-script
//

import Foundation


// TO DO: whereas token readers allow easy rollback to an earlier state simply by storing the [immutable] reader at that position and restoring it later on, ASTBuilder is a shared stateful object


class ASTBuilder {
    
    enum Form {
        case token(Token)
        case listBuilder(ListBuilder)
        case keyedListBuilder(KeyedListBuilder)
        case recordBuilder(RecordBuilder)
        case blockBuilder(BlockBuilder)
        case node(Value)
    }
    
    private(set) var stack = [Form]()
    
    
    func shift(_ token: Token) {
        switch token.form {
        case .startList:()
        case .startRecord:
            self.stack.append(.recordBuilder(RecordBuilder()))
        case .endRecord:
            if let head = self.stack.last, case .recordBuilder(let builder) = head {
                self.stack[-1] = .node(builder.reduce())
            }
        default:
            if case .value(let value) = token.form {
                self.stack.append(.node(value))
            } else {
                self.stack.append(.token(token))
            }
        }
    }
    
    func annotate(_ annotation: Token) {
        print("TO DO: attach \(annotation)")
    }
    
    func reduce(by count: Int) { // TO DO: pop n tokens, pass to pattern's reducer func, and put resulting value back on stack
    }
}
