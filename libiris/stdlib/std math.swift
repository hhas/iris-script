//
//  math funcs.swift
//  libiris
//

import Foundation
import Darwin

// TO DO: guard against divide-by-zero exceptions by using `AsDouble(nonZero:true)` in interfaces

func exponent(left: Number, right: Number) throws -> Number { return try left.pow(right) }
func positive(right: Number) throws -> Number { return right }
func negative(right: Number) throws -> Number { return try -right }
func add(left: Number, right: Number) throws -> Number { return try left + right }
func subtract(left: Number, right: Number) throws -> Number { return try left - right }
func multiply(left: Number, right: Number) throws -> Number { return try left * right }
func divide(left: Number, right: Number) throws -> Number { return try left / right }
func div(left: Double, right: Double) throws -> Double { return (left / right).rounded(.towardZero) }
func mod(left: Double, right: Double) throws -> Double { return left.truncatingRemainder(dividingBy: right) }

// math comparison

// signature: isEqualTo(left: primitive(double), right: primitive(double)) returning primitive(boolean)

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


