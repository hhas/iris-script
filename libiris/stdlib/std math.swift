//
//  math funcs.swift
//  libiris
//

import Foundation
import Darwin

// TO DO: how best to support [e.g.] `a < b < c`? the crude solution would be to define every combination of `<≤≥>` as trinary operators, but that is clunky; Icon solves this very elegantly by using success(value)/failure instead of conventional true/false, but we want to use Booleans for pedagogical purposes; one option might be for `EXPR < c` to declare its left operand as accepting either number OR successOrFailure(Number), with `a < b` offering to return either boolean (its preferred type) or successOrFailure(Number); the two handlers can then negotiate to use the common type, successOrFailure(Number), providing Icon-style composition where the intermediate result is either success(Number) or failure, which the second test can unwrap; another option would be for these particular handlers to return a true-like object that behaves as boolean true in boolean contexts but can coerce/unwrap as number where that is needed instead (the false-like object which signals the first test’s failure would need to be handled in the second test to return false); yet another possibility is for these operators to use a custom parser reducer that decomposes [e.g.] `a < b < c` to `a < b AND b < c`, which keeps the run-time simple albeit with some challenges when pretty-printing the resulting commands `AND{<{a,b},<{b,c}}` back to the original representation

// TO DO: guard against divide-by-zero exceptions by using `AsDouble(nonZero:true)` in interfaces

func exponent(left: Number, right: Number) -> Number { return left.pow(right) }
func positive(right: Number) -> Number { return right }
func negative(right: Number) -> Number { return -right }
func add(left: Number, right: Number) -> Number { return left + right }
func subtract(left: Number, right: Number) -> Number { return left - right }
func multiply(left: Number, right: Number) -> Number { return left * right }
func divide(left: Number, right: Number) -> Number { return left / right }
func div(left: Double, right: Double) -> Double { return (left / right).rounded(.towardZero) }
func mod(left: Double, right: Double) -> Double { return left.truncatingRemainder(dividingBy: right) }

// math comparison

// signature: isEqualTo(left: primitive(double), right: primitive(double)) returning primitive(boolean)


enum ComparisonResult: Value { // TO DO: comparison (and logical?) operators should return Boolean-like value that allows multiple comparisons to be performed Icon-style, e.g. `0 ≤ x < 10`
    
    static var nominalType: NativeCoercion = asBool.nativeCoercion
    
    var description: String { if case .success = self { return "true" } else { return "false" } }
    
    case success(Value) // use Number? scalar? generic type?
    case failure
}


func isLess(left: Double, right: Double) -> Bool { return left < right }
func isLessOrEqual(left: Double, right: Double) -> Bool { return left <= right }
func isEqual(left: Double, right: Double) -> Bool { return left == right }
func isNotEqual(left: Double, right: Double) -> Bool { return left != right }
func isGreater(left: Double, right: Double) -> Bool { return left > right }
func isGreaterOrEqual(left: Double, right: Double) -> Bool { return left >= right }

// Boolean logic
func NOT(right: Bool) -> Bool { return !right }
func AND(left: Bool, right: Bool) -> Bool { return left && right }
func  OR(left: Bool, right: Bool) -> Bool { return left || right }
func XOR(left: Bool, right: Bool) -> Bool { return left && !right || !left && right }


