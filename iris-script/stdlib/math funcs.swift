//
//  math funcs.swift
//  iris-lang
//

import Foundation
import Darwin


func exponent(left: Number, right: Number) throws -> Number { return try pow(left, right) }
func positive(left: Number) throws -> Number { return left }
func negative(left: Number) throws -> Number { return try -left }
func add(left: Number, right: Number) throws -> Number { return try left + right }
func subtract(left: Number, right: Number) throws -> Number { return try left - right }
func multiply(left: Number, right: Number) throws -> Number { return try left * right }
func divide(left: Number, right: Number) throws -> Number { return try left / right }
func div(left: Double, right: Double) throws -> Double { return Double(left / right) }
func mod(left: Double, right: Double) throws -> Double { return left.truncatingRemainder(dividingBy: right) }

// math comparison

// signature: isEqualTo(left: primitive(double), right: primitive(double)) returning primitive(boolean)

func isLessThan(left: Double, right: Double) -> Bool { return left < right }
func isLessThanOrEqualTo(left: Double, right: Double) -> Bool { return left <= right }
func isEqualTo(left: Double, right: Double) -> Bool { return left == right }
func isNotEqualTo(left: Double, right: Double) -> Bool { return left != right }
func isGreaterThan(left: Double, right: Double) -> Bool { return left > right }
func isGreaterThanOrEqualTo(left: Double, right: Double) -> Bool { return left >= right }

// Boolean logic
func NOT(right: Bool) -> Bool { return !right }
func AND(left: Bool, right: Bool) -> Bool { return left && right }
func  OR(left: Bool, right: Bool) -> Bool { return left || right }
func XOR(left: Bool, right: Bool) -> Bool { return left && !right || !left && right }


