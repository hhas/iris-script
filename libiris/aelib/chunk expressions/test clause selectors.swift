//
//  test clause selectors.swift
//  iris-script
//

import Foundation
import AppleEvents


protocol TestSelector: Handler { }

extension TestSelector {
 
    static var nominalType: NativeCoercion { return asHandler.nativeCoercion }
}



struct ComparisonSelector: TestSelector {
    
    // TO DO: should left operand always be [its-based] reference, or is it reasonable to allow its-base reference to appear on either side?
    
    var name: Symbol { // TO DO: merge into Selector enum
        let names: (numeric: Symbol, nonnumeric: Symbol)
        switch self.form {
        case .lt: names = ("<", "is_before")
        case .le: names = ("≤", "is_not_after")
        case .eq: names = ("=", "is_same_as")
        case .ne: names = ("≠", "is_not_same_as")
        case .gt: names = (">", "is_after")
        case .ge: names = ("≥", "is_not_before")
        case .beginsWith: names = ("begins_with", "begins_with")
        case .endsWith:   names = ("ends_with", "ends_with")
        case .contains:   names = ("contains", "contains")
        case .isIn:       names = ("is_in", "is_in")
        }
        return self.isNumeric ? names.numeric : names.nonnumeric
    }
    
    var description: String { return "\(self.interface)" }
    
    var interface: HandlerInterface {
        return HandlerInterface(name: self.name,
                                parameters: [("left", "reference", asReference.nativeCoercion),
                                             ("right", "value", asValue.nativeCoercion)], // TO DO: right is test clause, although we don't yet have a coercion for that (can't use AsComplex as it's protocol-based)
            result: asTestClause.nativeCoercion)
    }
    
    enum Selector {
        case lt
        case le
        case eq
        case ne
        case gt
        case ge
        case beginsWith
        case endsWith
        case contains
        case isIn
    }
    
    let appData: NativeAppData
    let form: Selector
    let isNumeric: Bool
    
    func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        if command.arguments.count != 2 { throw BadSelectorError() }
        let left = try asReference.coerce(command.arguments[0].value, in: scope).desc as! ObjectSpecifierDescriptor
        let operandType: NativeCoercion = self.isNumeric ? asNumber : asValue
        let right = try self.appData.pack(operandType.coerce(command.arguments[1].value, in: scope))
        let result: TestDescriptor
        switch self.form {
        case .lt: result = left <  right
        case .le: result = left <= right
        case .eq: result = left == right
        case .ne: result = left != right
        case .gt: result = left >  right
        case .ge: result = left >= right
        case .beginsWith:  result = left.beginsWith(right)
        case .endsWith:    result = left.endsWith(right)
        case .contains:    result = left.contains(right)
        case .isIn:        result = left.isIn(right)
        }
        return TestClause(appData: self.appData, desc: result) as! T.SwiftType
    }
}

struct UnaryLogicalSelector: TestSelector {
    
    var description: String { return "\(self.interface)" }
    
    var interface: HandlerInterface {
        return HandlerInterface(name: "NOT",
                                parameters: [("right", "", asTestClause.nativeCoercion)],
                                result: asTestClause.nativeCoercion)
    }
    
    let appData: NativeAppData
    
    func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        if command.arguments.count != 1 { throw BadSelectorError() }
        let right = try asTestClause.coerce(command.arguments[0].value, in: scope).desc
        return TestClause(appData: self.appData, desc: LogicalDescriptor(NOT: right)) as! T.SwiftType
    }
}

struct BinaryLogicalSelector: TestSelector {
    
    var description: String { return "\(self.interface)" }
    
    var interface: HandlerInterface {
        return HandlerInterface(name: self.form.rawValue,
                                parameters: [("left", "", asTestClause.nativeCoercion),
                                             ("right", "", asTestClause.nativeCoercion)],
                                result: asTestClause.nativeCoercion)
    }
    
    enum Selector: Symbol {
        case AND = "AND"
        case OR  = "OR"
    }
    
    let appData: NativeAppData
    let form: Selector
    
    func call<T: SwiftCoercion>(with command: Command, in scope: Scope, as coercion: T) throws -> T.SwiftType {
        if command.arguments.count < 2 { throw BadSelectorError() }
        let operands = try command.arguments.map { try asTestClause.coerce($0.value, in: scope).desc }
        switch self.form {
        case .AND: return TestClause(appData: self.appData, desc: LogicalDescriptor(AND: operands)) as! T.SwiftType
        case .OR:  return TestClause(appData: self.appData, desc: LogicalDescriptor(OR: operands)) as! T.SwiftType
        }
    }
}


