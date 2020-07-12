//
//  test clause.swift
//  iris-script
//

import Foundation
import AppleEvents


// override comparison/containment/logical operators' stdlib handlers within `whose` operator's right operand
struct TestClauseScope: Accessor {
    
    let appData: NativeAppData
    let reference: Reference
    
    init(appData: NativeAppData) {
        self.appData = appData
        self.reference = Reference(appData: appData, desc: RootSpecifierDescriptor.its)
    }
    
    // TO DO: magic strings bad; need to standardize mechanism by which operator/command names are overridden/[re]declared, and ensure canonical, not alias, names are always used
    
    func get(_ name: Symbol) -> Value? {
        switch name {
        case "<":               return ComparisonSelector(appData: self.appData, form: .lt, isNumeric: true)
        case "is_before":       return ComparisonSelector(appData: self.appData, form: .lt, isNumeric: false)
        case "≤":               return ComparisonSelector(appData: self.appData, form: .le, isNumeric: true)
        case "is_not_after":    return ComparisonSelector(appData: self.appData, form: .le, isNumeric: false)
        case "=":               return ComparisonSelector(appData: self.appData, form: .eq, isNumeric: true)
        case "is_same_as":      return ComparisonSelector(appData: self.appData, form: .eq, isNumeric: false)
        case "≠":               return ComparisonSelector(appData: self.appData, form: .ne, isNumeric: true)
        case "is_not_same_as":  return ComparisonSelector(appData: self.appData, form: .ne, isNumeric: false)
        case ">":               return ComparisonSelector(appData: self.appData, form: .gt, isNumeric: true)
        case "is_after":        return ComparisonSelector(appData: self.appData, form: .gt, isNumeric: false)
        case "≥":               return ComparisonSelector(appData: self.appData, form: .ge, isNumeric: true)
        case "is_not_before":   return ComparisonSelector(appData: self.appData, form: .ge, isNumeric: false)
        case "begins_with":     return ComparisonSelector(appData: self.appData, form: .beginsWith, isNumeric: false)
        case "ends_with":       return ComparisonSelector(appData: self.appData, form: .endsWith, isNumeric: false)
        case "contains":        return ComparisonSelector(appData: self.appData, form: .contains, isNumeric: false)
        case "is_in":           return ComparisonSelector(appData: self.appData, form: .isIn, isNumeric: false)
        // TO DO: convenience `does_not_begin_with` forms
        case "AND":             return BinaryLogicalSelector(appData: self.appData, form: .AND)
        case "OR":              return BinaryLogicalSelector(appData: self.appData, form: .OR)
        case "NOT":             return UnaryLogicalSelector(appData: self.appData)
        default:    return self.reference.get(name)
        }
    }
    
    // in addition to delegating lookups, this must also define comparison+logic methods (Q. would it be simpler to make Reference.lookup hookable?)
}

// note: this is why first-use binding is preferable to parse-time binding: operator names are the same, but the handlers they bind are contextual [caution: these handlers must match on operand type[s] and delegate when neither operand is a [literal?] [test?] reference]

struct TestClause: Value {
    
    var description: String {
        //print(">>>",self.desc)
        switch self.desc {
        case let desc as ComparisonDescriptor:
            if let left = try? self.appData.unpack(desc.object) as Any,
                let right = try? self.appData.unpack(desc.value) as Any {
                // TO DO: use operand type to determine which operator syntax (numeric vs non-numeric) to use (in the event that both operands are references, should probably default to non-numeric names)
                switch desc.comparison {
                case .lessThan:
                    return "\(left) < \(right)"
                case .lessThanOrEqual:
                    return "\(left) ≤ \(right)"
                case .equal:
                    return "\(left) = \(right)"
                case .notEqual:
                    return "\(left) ≠ \(right)"
                case .greaterThan:
                    return "\(left) > \(right)"
                case .greaterThanOrEqual:
                    return "\(left) ≥ \(right)"
                case .beginsWith:
                    return "\(left) begins_with \(right)"
                case .endsWith:
                    return "\(left) ends_with \(right)"
                case .contains:
                    return "\(left) contains \(right)"
                case .isIn:
                    return "\(left) is_in \(right)"
                }
            }
        case let desc as LogicalDescriptor:
            print("logical")
            if let ops = try?  self.appData.unpack(desc.operands) as [Any] { // TO DO: better unpacking, operand count checks; how best to format >2 operands?
                switch desc.logical {
                case .AND:
                    return "\(ops[0]) AND \(ops[1])"
                case .OR:
                    return "\(ops[0]) OR \(ops[1])"
                case .NOT:
                    return "NOT \(ops[0])"
                }
            }
        default: ()
        }
        return "«TestClause \(self.desc)»"
    }
    
    static let nominalType: Coercion = asTestClause
    
    let appData: NativeAppData
    let desc: TestDescriptor
    
}


