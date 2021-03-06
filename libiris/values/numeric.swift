//
//  numeric.swift
//


import Darwin

// TO DO: Number should encapsulate its own errors, avoiding need for arithmetic and comparison operators to throw directly

// TO DO: how safe/practical to write ISO date and time literals without string quoting? e.g. `2019-06-01` and `12:01` can be parsed as date and time if we have whitespace-sensitivity rules for `-` and `:` (which we require anyway in order to support punctuation-less command syntax)


// TO DO: replace Number's .overflow and .notANumber cases with .error(NumericError), and capture the details in Error; this can also be used to capture errors thrown by standard arithmetic and comparison operators defined on Number extension, as `==() throws` breaks conformance required for Hashable protocol, which Number ought to support (although there are general caveats here wrt the interchangeability of String/Int/Double representations of numbers, particularly once we allow script localization of numeric literals)


// TO DO: Number supports mixed type math; how should extended Int/Double do it?

// TO DO: Unit and Quantity(Number,Unit); also UnitType (length, weight, temperature, etc)


// TO DO: .nonStandard(…) case for numbers written with atypical formatting, e.g. leading zeroes (000123); alternatively, format-preserving might be handled independently by an appropriate line line reader (typically such `numbers` are found in 24-hr times, barcode numbers, etc, so using line readers to convert them to custom string-based Values that support coercion to Number (either by converting the string each time or by capturing both original string and Int/Double/Number representations) provides a general solution that covers all use cases there, and avoids the need to implement special one-off cases here)


public protocol NumericValue: ScalarValue, HashableValue, LiteralConvertible {}


extension Int: NumericValue, KeyConvertible {
    
    public var literalDescription: String { return String(self) } // TO DO: formatter may want to override with custom representation
    public var swiftLiteralDescription: String { return String(self) }
    
    public static let nominalType: NativeCoercion = asInt.nativeCoercion
}

extension Double: NumericValue, KeyConvertible {
    
    public var literalDescription: String { return String(self) }
    
    public var swiftLiteralDescription: String {
        switch self {
        case Double.infinity:   return "(+Double.infinity)"
        case -Double.infinity:  return "(-Double.infinity)"
        case Double.nan:        return "(Double.nan)"
        // TO DO: what else?
        default:                return String(self)
        }
    }
    
    public static let nominalType: NativeCoercion = asDouble.nativeCoercion
}



public enum Number: NumericValue, KeyConvertible, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    // what about fractions? (this may require `indirect` to allow nested composition; alternatively, might be best to implement as PrecisionNumber struct/class, possibly in optional library)
    
    public var literalDescription: String { // get canonical native code representation (note: this is currently implemented as a method to allow for formatting options to be passed in future // TO DO: check these representations are always correct
        switch self {
        case .integer(let n, _):    return String(n)
        case .floatingPoint(let n): return String(n)
        }
    }
    
    public var swiftLiteralDescription: String {
        switch self {
        case .integer(let n, radix: let r): return "Number(\(n)\(r == 10 ? "" : ", radix: \(r)"))"
        case .floatingPoint(let n):         return "Number(\(n))"
        }
    }
    
    public static func ==(lhs: Number, rhs: Number) -> Bool {
        return scalarComparisonOperation(lhs, rhs, intOperator: ==, doubleOperator: ==)
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .integer(let n, radix: _): return n.hash(into: &hasher)
        case .floatingPoint(let n):     return n.hash(into: &hasher)
        }
    }
    
    public var isWholeNumber: Bool {
        switch self {
        case .integer(_, _):        return true
        case .floatingPoint(let n): return n.truncatingRemainder(dividingBy: 1) == 0
        }
    }
    
    public static let nominalType: NativeCoercion = asNumber
    
    // represents a whole or fractional number (as Swift Int or Double); numbers that are valid but too large to represent using standard Swift types are held as strings
    
    // TO DO: BigNum support (e.g. https://github.com/mkrd/Swift-Big-Integer)
    
    // Q. what about quantities? or should those be struct of {Number,Unit}?
    
    case integer(Int, radix: Int)
    case floatingPoint(Double)
    // TO DO: decimal?
    
    public init(_ n: Int, radix: Int = 10) {
        self = .integer(n, radix: radix)
    }
    public init(_ n: Double) {
        self = .floatingPoint(n)
    }
    
    public init(integerLiteral value: Int) {
        self = .integer(value, radix: 10)
    }
    public init(floatLiteral value: Double) {
        self = .floatingPoint(value)
    }

    public init(_ code: String) throws {
        // temporary (we really want to parse and format numbers ourselves, potentially with localization support [although we'll need access to an environment for that, as it'll be script-specific, relying on top-level syntax imports])
        guard let d = Double(code) else { throw TypeCoercionError(value: Text(code), coercion: Number.nominalType) }
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
    
    public func toInt() throws -> Int { // throws if out-of-range double or has a fractional part // TO DO: would it be better to return nil if not a valid Int?
        switch self {
        case .integer(let n, _): return n
        case .floatingPoint(let n) where n.truncatingRemainder(dividingBy: 1) == 0:
            if n >= Double(Int.min) && n <= Double(Int.max) { return Int(n) }
        default: ()
        }
        throw ConstraintCoercionError(value: self, coercion: Int.nominalType)
    }
    
    public func toDouble() -> Double {
        switch self {
        case .integer(let n, _):    return Double(n)
        case .floatingPoint(let n): return n
        }
    }
}



//**********************************************************************
// generic helper functions for basic arithmetic and numerical comparisons


@inline(__always) func scalarArithmeticOperation(_ lhs: Number, _ rhs: Number, intOperator: ((Int,Int)->(Int,Bool))?, doubleOperator: (Double,Double)->Double) -> Number {
    switch (lhs, rhs) {
    case (.integer(let leftOp, _), .integer(let rightOp, _)):
        if let op = intOperator {
            let (result, isOverflow) = op(leftOp, rightOp)
            // TO DO: how best to deal with integer overflows? switch to Double automatically? (i.e. loses precision, but allows operation to continue)
            if !isOverflow { return Number(result) }
        }
    default: () // TO DO: this should be improved so that if one number is Int and the other is a Double that can be accurately represented as Int then Int-based operation is tried first; if that overflows then fall back to using Doubles; note that best way to do this may be to implement Number.toBestRepresentation() that returns .integer/.floatingPoint after first checking if the latter can be accurately represented as an Integer instead
    }
    return Number(doubleOperator(lhs.toDouble(), rhs.toDouble()))
}

@inline(__always) func scalarComparisonOperation(_ lhs: Number, _ rhs: Number, intOperator: (Int,Int)->Bool, doubleOperator: (Double,Double)->Bool) -> Bool {
    switch (lhs, rhs) {
    case (.integer(let leftOp, _), .integer(let rightOp, _)):
        return intOperator(leftOp, rightOp)
    default:
        return doubleOperator(lhs.toDouble(), rhs.toDouble()) // TO DO: as above, use Int-based comparison where possible (casting an Int to Double is lossy in 64-bit, which may affect correctness of result when comparing a high-value Int against an almost equivalent Double)
        // TO DO: when comparing Doubles for equality, use almost-equivalence as standard? (e.g. 0.7*0.7=0.49 will normally return false due to rounding errors in FP math, which is likely to be more confusing to users than if the test is fudged)
    }
}


//**********************************************************************
// Arithmetic and comparison operators are defined on Number so that primitive procs can perform basic
// numerical operations without having to check or care about underlying representations (Int or Double).

// TO DO: once BigNum support is implemented, only other reason for throwing is if scalar is .notANumber, in which case might be as well just to concatenate both scalar string representations with operator symbol and return as 'unevaluated expression string' instead of throwing (since throwing creates work of its own)

// TO DO: think all these operators need to be non-throwing, instead capturing deferred .failed(Error) and have that throw when next evaled

public extension Number {
    
    static prefix func -(lhs: Number) -> Number {
        return scalarArithmeticOperation(Number(0), lhs, intOperator: {(l:Int,r:Int) in l.subtractingReportingOverflow(r)}, doubleOperator: -) // TO DO
    }

    static func +(lhs: Number, rhs: Number) -> Number {
        return scalarArithmeticOperation(lhs, rhs, intOperator: {(l:Int,r:Int) in l.addingReportingOverflow(r)}, doubleOperator: +)
    }
    static func -(lhs: Number, rhs: Number) -> Number {
        return scalarArithmeticOperation(lhs, rhs, intOperator: {(l:Int,r:Int) in l.subtractingReportingOverflow(r)}, doubleOperator: -)
    }
    static func *(lhs: Number, rhs: Number) -> Number {
        return scalarArithmeticOperation(lhs, rhs, intOperator: {(l:Int,r:Int) in l.multipliedReportingOverflow(by: r)}, doubleOperator: *)
    }
    static func /(lhs: Number, rhs: Number) -> Number {
        return scalarArithmeticOperation(lhs, rhs, intOperator: nil, doubleOperator: /)
    }
    func pow(_ rhs: Number) -> Number { // exponent
        return Number(Darwin.pow(self.toDouble(), rhs.toDouble()))
    }
    func div(_ rhs: Number) -> Number { // integer division
        switch (self, rhs) {
        case (.integer(let leftOp, _), .integer(let rightOp, _)):
            return Number(leftOp / rightOp)
        default:
            let n = (self / rhs).toDouble()
            return Number((n >= Double(Int.min) && n <= Double(Int.max)) ? Int(n) : lround(n)) // TO DO: use rounded(…)?
        }
    }
    func mod(_ rhs: Number) -> Number { // remainder
        switch (self, rhs) {
        case (.integer(let leftOp, _), .integer(let rightOp, _)):
            return Number(leftOp % rightOp)
        default:
            return Number(self.toDouble().truncatingRemainder(dividingBy: rhs.toDouble()))
        }
    }

    static func <(lhs: Number, rhs: Number) -> Bool {
        return scalarComparisonOperation(lhs, rhs, intOperator: <, doubleOperator: <)
    }
    static func <=(lhs: Number, rhs: Number) -> Bool {
        return scalarComparisonOperation(lhs, rhs, intOperator: <=, doubleOperator: <=)
    }
    // `==` is already implemented above as part of Hashable conformance
    static func !=(lhs: Number, rhs: Number) -> Bool {
        return scalarComparisonOperation(lhs, rhs, intOperator: !=, doubleOperator: !=)
    }
    static func >(lhs: Number, rhs: Number) -> Bool {
        return scalarComparisonOperation(lhs, rhs, intOperator: >, doubleOperator: >)
    }
    static func >=(lhs: Number, rhs: Number) -> Bool {
        return scalarComparisonOperation(lhs, rhs, intOperator: >=, doubleOperator: >=)
    }
}
