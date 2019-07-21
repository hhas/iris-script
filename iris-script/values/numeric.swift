//
//  numeric.swift
//


import Darwin

// TO DO: how safe/practical to write ISO date and time literals without string quoting? e.g. `2019-06-01` and `12:01` can be parsed as date and time if we have whitespace-sensitivity rules for `-` and `:` (which we require anyway in order to support punctuation-less command syntax)


// TO DO: replace Number's .overflow and .invalid cases with .error(NumericError), and capture the details in Error; this can also be used to capture errors thrown by standard arithmetic and comparison operators defined on Number extension, as `==() throws` breaks conformance required for Hashable protocol, which Number ought to support (although there are general caveats here wrt the interchangeability of String/Int/Double representations of numbers, particularly once we allow script localization of numeric literals)


// TO DO: Number supports mixed type math; how should extended Int/Double do it?

// TO DO: Unit and Quantity(Number,Unit); also UnitType (length, weight, temperature, etc)


protocol NumericValue: ScalarValue, KeyConvertible {}


extension Int: NumericValue {
    
    var nominalType: Coercion { return asInt }
    
    func toInt(in scope: Scope, as coercion: Coercion) throws -> Int {
        return self
    }
    func toDouble(in scope: Scope, as coercion: Coercion) throws -> Double {
        return Double(self)
    }
    func toString(in scope: Scope, as coercion: Coercion) throws -> String { // TO DO: coercion param's type?
        return String(self)
    }
    
    func toNumber(in scope: Scope, as coercion: Coercion) throws -> Number {
        return Number(self)
    }
}

extension Double: NumericValue {
    
    var nominalType: Coercion { return asDouble }
    
    func toInt(in scope: Scope, as coercion: Coercion) throws -> Int {
        guard let result = Int(exactly: self) else { throw ConstraintError(value: self, coercion: coercion) }
        return result
    }
    func toDouble(in scope: Scope, as coercion: Coercion) throws -> Double {
        return self
    }
    func toString(in scope: Scope, as coercion: Coercion) throws -> String { // TO DO: coercion param's type?
        return String(self)
    }
    
    func toNumber(in scope: Scope, as coercion: Coercion) throws -> Number {
        return Number(self)
    }
}



enum Number: NumericValue {
    
    static func ==(lhs: Number, rhs: Number) -> Bool {
        do {
            return try scalarComparisonOperation(lhs, rhs, intOperator: ==, doubleOperator: ==)
        } catch {
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .integer(let n, radix: _): return n.hash(into: &hasher)
        case .floatingPoint(let n):     return n.hash(into: &hasher)
        case .overflow(let s, _):       return s.hash(into: &hasher)
        case .invalid(let s):           return s.hash(into: &hasher)
        }
    }
    
    var description: String { return self.literalRepresentation() }
    
    var nominalType: Coercion { return asNumber }
    
    // represents a whole or fractional number (as Swift Int or Double); numbers that are valid but too large to represent using standard Swift types are held as strings
    
    // TO DO: BigNum support (e.g. https://github.com/mkrd/Swift-Big-Integer)
    
    // Q. what about quantities? or should those be struct of {Number,Unit}?
    
    case integer(Int, radix: Int)
    case floatingPoint(Double)
    // TO DO: decimal?
    case overflow(String, Any.Type)
    case invalid(String) // not a number
    
    init(_ n: Int, radix: Int = 10) {
        self = .integer(n, radix: radix)
    }
    init(_ n: Double) {
        self = (n == Double.infinity) ? .overflow(String(n), Double.self) : .floatingPoint(n)
    }
    init(_ code: String) throws {
        // temporary (we really want to parse and format numbers ourselves, potentially with localization support [although we'll need access to an environment for that, as it'll be script-specific, relying on top-level syntax imports])
        guard let d = Double(code) else { throw UnsupportedCoercionError(value: Text(code), coercion: asNumber) }
        if Int(exactly: d) != nil, let n = Int(code) {
            self = .integer(n, radix: 10)
        } else {
            self = .floatingPoint(d)
        }
        /*
        let lexer = Lexer(code: code)
        switch lexer.readNumber() { // TO DO: how to support localization?
        case .number(value: _, scalar: let scalar):
            self = scalar
        default:
            throw CoercionError(value: Text(code), coercion: asScalar)
        }
         */
    }
    
    // initializers primarily intended for use by scalar parsefuncs below // TO DO: should these *only* be used by numeric parsefuncs?
    // note: these constructors use Swift's own Int(String)/Double(String) constructors, thus underscores may be used as thousands separators, leading/trailing whitespace is not allowed, int constructor doesn't accept decimals, double constructor only accepts period (`.`) as decimal separator, fractional exponents aren't allowed, etc.
    
    // TO DO: init(number code: String,...) that chooses best internal representation? this basically means calling readDecimalNumber() parsefunc, so not sure how useful that is really, given that these inits only exist for parsefuncs' use in the first palce
    
    // unwrap Swift primitives
    
    
    
    func toInt(in scope: Scope, as coercion: Coercion) throws -> Int {
        return try self.toInt()
    }
    func toDouble(in scope: Scope, as coercion: Coercion) throws -> Double {
        return try self.toDouble()
    }
    func toString(in scope: Scope, as coercion: Coercion) throws -> String { // TO DO: coercion param's type?
        return self.literalRepresentation()
    }
    
    func toNumber(in scope: Scope, as coercion: Coercion) throws -> Number {
        return self
    }
    
    func toInt() throws -> Int {
        switch self {
        case .integer(let n, _): return n
        case .floatingPoint(let n) where n.truncatingRemainder(dividingBy: 1) == 0:
            if n >= Double(Int.min) && n <= Double(Int.max) { return Int(n) }
        default: ()
        }
        throw ConstraintError(value: self, coercion: asInt)
    }
    
    func toDouble() throws -> Double {
        switch self {
        case .integer(let n, _): return Double(n)
        case .floatingPoint(let n): return n
        default: throw ConstraintError(value: self, coercion: asDouble)
        }
    }
    
    
    // overloaded generic-friendly version of toInt/toDouble; used by numeric coercions' generic base class
    /*
    private func _toInt(_ min: Int, _ max: Int) throws -> Int {
        let n = try self.toInt()
        if n < min || n > max { throw ConstraintError(value: self, message: "Number is not in allowed range: \(self.literalRepresentation())") }
        return n
    }
    private func _toUInt(_ max: UInt) throws -> UInt {
        let n = try self.toInt()
        if n < 0 || UInt(n) > max { throw ConstraintError(value: self, message: "Number is not in allowed range: \(self.literalRepresentation())") }
        return UInt(n)
    }
    */
    //
    
    func literalRepresentation() -> String { // get canonical code representation (note: this is currently implemented as a method to allow for formatting options to be passed in future) // TO DO: check these representations are always correct
        switch self {
        case .integer(let n, _):
            return String(n)
        case .floatingPoint(let n):
            return String(n)
        case .overflow(let s, _):
            return s
        case .invalid(let s):
            return s
        }
    }
    
    // TO DO: implement formattedRepresentation (custom/locale-specific) here? or does that logic belong solely in formatting command? (i.e. all Values should implement API for outputting pretty-printed code representation, but not sure if that API should support all formatting operations)
}



//**********************************************************************
// generic helper functions for basic arithmetic and numerical comparisons


@inline(__always) func scalarArithmeticOperation(_ lhs: Number, _ rhs: Number, intOperator: ((Int,Int)->(Int,Bool))?, doubleOperator: (Double,Double)->Double) throws -> Number {
    switch (lhs, rhs) {
    case (.integer(let leftOp, _), .integer(let rightOp, _)):
        if let op = intOperator {
            let (result, isOverflow) = op(leftOp, rightOp)
            // TO DO: how best to deal with integer overflows? switch to Double automatically? (i.e. loses precision, but allows operation to continue)
            return isOverflow ? .overflow(String(doubleOperator(try lhs.toDouble(), try rhs.toDouble())), Int.self) : Number(result)
        } else {
            return try Number(doubleOperator(lhs.toDouble(), rhs.toDouble()))
        }
    default: // TO DO: this should be improved so that if one number is Int and the other is a Double that can be accurately represented as Int then Int-based operation is tried first; if that overflows then fall back to using Doubles; note that best way to do this may be to implement Number.toBestRepresentation() that returns .Integer/.FloatingPoint after first checking if the latter can be accurately represented as an Integer instead
        return try Number(doubleOperator(lhs.toDouble(), rhs.toDouble()))
    }
}

@inline(__always) func scalarComparisonOperation(_ lhs: Number, _ rhs: Number, intOperator: (Int,Int)->Bool, doubleOperator: (Double,Double)->Bool) throws -> Bool {
    switch (lhs, rhs) {
    case (.integer(let leftOp, _), .integer(let rightOp, _)):
        return intOperator(leftOp, rightOp)
    default:
        return try doubleOperator(lhs.toDouble(), rhs.toDouble()) // TO DO: as above, use Int-based comparison where possible (casting an Int to Double is lossy in 64-bit, which may affect correctness of result when comparing a high-value Int against an almost equivalent Double)
        // TO DO: when comparing Doubles for equality, use almost-equivalence as standard? (e.g. 0.7*0.7=0.49 will normally return false due to rounding errors in FP math, which is likely to be more confusing to users than if the test is fudged)
    }
}


//**********************************************************************
// Arithmetic and comparison operators are defined on Number so that primitive procs can perform basic
// numerical operations without having to check or care about underlying representations (Int or Double).

// TO DO: once BigNum support is implemented, only other reason for throwing is if scalar is .invalid, in which case might be as well just to concatenate both scalar string representations with operator symbol and return as 'unevaluated expression string' instead of throwing (since throwing creates work of its own)

// TO DO: think all these operators need to be non-throwing, instead capturing deferred .failed(Error) and have that throw when next evaled

extension Number {
    
    static prefix func -(lhs: Number) throws -> Number {
        return try scalarArithmeticOperation(Number(0), lhs, intOperator: {(l:Int,r:Int) in l.subtractingReportingOverflow(r)}, doubleOperator: -) // TO DO
    }

    static func +(lhs: Number, rhs: Number) throws -> Number {
        return try scalarArithmeticOperation(lhs, rhs, intOperator: {(l:Int,r:Int) in l.addingReportingOverflow(r)}, doubleOperator: +)
    }
    static func -(lhs: Number, rhs: Number) throws -> Number {
        return try scalarArithmeticOperation(lhs, rhs, intOperator: {(l:Int,r:Int) in l.subtractingReportingOverflow(r)}, doubleOperator: -)
    }
    static func *(lhs: Number, rhs: Number) throws -> Number {
        return try scalarArithmeticOperation(lhs, rhs, intOperator: {(l:Int,r:Int) in l.multipliedReportingOverflow(by: r)}, doubleOperator: *)
    }
    static func /(lhs: Number, rhs: Number) throws -> Number {
        return try scalarArithmeticOperation(lhs, rhs, intOperator: nil, doubleOperator: /)
    }
    func pow(_ rhs: Number) throws -> Number { // exponent
        return Number(try Darwin.pow(self.toDouble(), rhs.toDouble()))
    }
    func div(_ rhs: Number) throws -> Number { // integer division
        switch (self, rhs) {
        case (.integer(let leftOp, _), .integer(let rightOp, _)):
            return Number(leftOp / rightOp)
        default:
            let n = try (self / rhs).toDouble()
            return Number((n >= Double(Int.min) && n <= Double(Int.max)) ? Int(n) : lround(n))
        }
    }
    func mod(_ rhs: Number) throws -> Number { // remainder
        switch (self, rhs) {
        case (.integer(let leftOp, _), .integer(let rightOp, _)):
            return Number(leftOp % rightOp)
        default:
            return try Number(self.toDouble().truncatingRemainder(dividingBy: rhs.toDouble()))
        }
    }

    static func <(lhs: Number, rhs: Number) throws -> Bool {
        return try scalarComparisonOperation(lhs, rhs, intOperator: <, doubleOperator: <)
    }
    static func <=(lhs: Number, rhs: Number) throws -> Bool {
        return try scalarComparisonOperation(lhs, rhs, intOperator: <=, doubleOperator: <=)
    }
    //static func ==(lhs: Number, rhs: Number) throws -> Bool {
    //    return try scalarComparisonOperation(lhs, rhs, intOperator: ==, doubleOperator: ==)
    //}
    static func !=(lhs: Number, rhs: Number) throws -> Bool {
        return try scalarComparisonOperation(lhs, rhs, intOperator: !=, doubleOperator: !=)
    }
    static func >(lhs: Number, rhs: Number) throws -> Bool {
        return try scalarComparisonOperation(lhs, rhs, intOperator: >, doubleOperator: >)
    }
    static func >=(lhs: Number, rhs: Number) throws -> Bool {
        return try scalarComparisonOperation(lhs, rhs, intOperator: >=, doubleOperator: >=)
    }
}