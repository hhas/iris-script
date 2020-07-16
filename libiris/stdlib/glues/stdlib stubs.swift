//
//  stdlib HANDLER STUBS.swift
//
//  Swift functions that implement primitive handlers.
//

import Foundation

func exponent(left: Number,right: Number) throws -> Number {
    fatalError("exponent of stdlib is not yet implemented.")
}

func positive(right: Number) throws -> Number {
    fatalError("positive of stdlib is not yet implemented.")
}

func negative(right: Number) throws -> Number {
    fatalError("negative of stdlib is not yet implemented.")
}

func multiply(left: Number,right: Number) throws -> Number {
    fatalError("multiply of stdlib is not yet implemented.")
}

func divide(left: Number,right: Number) throws -> Number {
    fatalError("divide of stdlib is not yet implemented.")
}

func div(left: Double,right: Double) throws -> Double {
    fatalError("div of stdlib is not yet implemented.")
}

func mod(left: Double,right: Double) throws -> Double {
    fatalError("mod of stdlib is not yet implemented.")
}

func add(left: Number,right: Number) throws -> Number {
    fatalError("add of stdlib is not yet implemented.")
}

func subtract(left: Number,right: Number) throws -> Number {
    fatalError("subtract of stdlib is not yet implemented.")
}

func isLess(left: Double,right: Double) -> Bool {
    fatalError("isLess of stdlib is not yet implemented.")
}

func isLessOrEqual(left: Double,right: Double) -> Bool {
    fatalError("isLessOrEqual of stdlib is not yet implemented.")
}

func isEqual(left: Double,right: Double) -> Bool {
    fatalError("isEqual of stdlib is not yet implemented.")
}

func isNotEqual(left: Double,right: Double) -> Bool {
    fatalError("isNotEqual of stdlib is not yet implemented.")
}

func isGreater(left: Double,right: Double) -> Bool {
    fatalError("isGreater of stdlib is not yet implemented.")
}

func isGreaterOrEqual(left: Double,right: Double) -> Bool {
    fatalError("isGreaterOrEqual of stdlib is not yet implemented.")
}

func NOT(right: Bool) -> Bool {
    fatalError("NOT of stdlib is not yet implemented.")
}

func AND(left: Bool,right: Bool) -> Bool {
    fatalError("AND of stdlib is not yet implemented.")
}

func OR(left: Bool,right: Bool) -> Bool {
    fatalError("OR of stdlib is not yet implemented.")
}

func XOR(left: Bool,right: Bool) -> Bool {
    fatalError("XOR of stdlib is not yet implemented.")
}

func isBefore(left: String,right: String) throws -> Bool {
    fatalError("isBefore of stdlib is not yet implemented.")
}

func isNotAfter(left: String,right: String) throws -> Bool {
    fatalError("isNotAfter of stdlib is not yet implemented.")
}

func isSameAs(left: String,right: String) throws -> Bool {
    fatalError("isSameAs of stdlib is not yet implemented.")
}

func isNotSameAs(left: String,right: String) throws -> Bool {
    fatalError("isNotSameAs of stdlib is not yet implemented.")
}

func isAfter(left: String,right: String) throws -> Bool {
    fatalError("isAfter of stdlib is not yet implemented.")
}

func isNotBefore(left: String,right: String) throws -> Bool {
    fatalError("isNotBefore of stdlib is not yet implemented.")
}

func beginsWith(left: String,right: String) throws -> Bool {
    fatalError("beginsWith of stdlib is not yet implemented.")
}

func endsWith(left: String,right: String) throws -> Bool {
    fatalError("endsWith of stdlib is not yet implemented.")
}

func contains(left: String,right: String) throws -> Bool {
    fatalError("contains of stdlib is not yet implemented.")
}

func isIn(left: String,right: String) throws -> Bool {
    fatalError("isIn of stdlib is not yet implemented.")
}

func joinValues(left: String,right: String) throws -> String {
    fatalError("joinValues of stdlib is not yet implemented.")
}

func uppercase(text: String) -> String {
    fatalError("uppercase of stdlib is not yet implemented.")
}

func lowercase(text: String) -> String {
    fatalError("lowercase of stdlib is not yet implemented.")
}

func formatCode(value: Value) -> String {
    fatalError("formatCode of stdlib is not yet implemented.")
}

func write(value: Value) {
    fatalError("write of stdlib is not yet implemented.")
}

func isA(left value: Value,right coercion: Coercion,commandEnv: Scope) -> Bool {
    fatalError("isA of stdlib is not yet implemented.")
}

func coerce(left value: Value,right coercion: Coercion,commandEnv: Scope) throws -> Value {
    fatalError("coerce of stdlib is not yet implemented.")
}

func defineCommandHandler(interface: HandlerInterface,action body: Value,commandEnv: Scope) throws -> Handler {
    fatalError("defineCommandHandler of stdlib is not yet implemented.")
}

func defineEventHandler(interface: HandlerInterface,action body: Value,commandEnv: Scope) throws -> Handler {
    fatalError("defineEventHandler of stdlib is not yet implemented.")
}

func set(name: Symbol,to value: Value,commandEnv: Scope) throws -> Value {
    fatalError("set of stdlib is not yet implemented.")
}

func ifTest(condition: Bool,action: Value,alternativeAction: Value,commandEnv: Scope) throws -> Value {
    fatalError("ifTest of stdlib is not yet implemented.")
}

func whileRepeat(condition: Bool,action: Value,commandEnv: Scope) throws -> Value {
    fatalError("whileRepeat of stdlib is not yet implemented.")
}

func repeatWhile(action: Value,condition: Bool,commandEnv: Scope) throws -> Value {
    fatalError("repeatWhile of stdlib is not yet implemented.")
}

func tell(target: Value,action: Value,commandEnv: Scope) throws -> Value {
    fatalError("tell of stdlib is not yet implemented.")
}

func ofClause(attribute: Value,target value: Value,commandEnv: Scope,handlerEnv: Scope) throws -> Value {
    fatalError("ofClause of stdlib is not yet implemented.")
}

func Application(bundleIdentifier: String) throws -> Value {
    fatalError("Application of stdlib is not yet implemented.")
}

func atSelector(elementType: Symbol,selectorData: Value,commandEnv: Scope,handlerEnv: Scope) throws -> Value {
    fatalError("atSelector of stdlib is not yet implemented.")
}

func nameSelector(elementType: Symbol,selectorData: Value,commandEnv: Scope) throws -> Value {
    fatalError("nameSelector of stdlib is not yet implemented.")
}

func idSelector(elementType: Symbol,selectorData: Value,commandEnv: Scope) throws -> Value {
    fatalError("idSelector of stdlib is not yet implemented.")
}

func rangeSelector(elementType: Symbol,selectorData: Value,commandEnv: Scope,handlerEnv: Scope) throws -> Value {
    fatalError("rangeSelector of stdlib is not yet implemented.")
}

func testSelector(elementType: Symbol,selectorData: Value,commandEnv: Scope,handlerEnv: Scope) throws -> Value {
    fatalError("testSelector of stdlib is not yet implemented.")
}

func ElementRange(from startSelector: Value,to endSelector: Value) -> Value {
    fatalError("ElementRange of stdlib is not yet implemented.")
}

func firstElement(right elementType: Symbol) -> Value {
    fatalError("firstElement of stdlib is not yet implemented.")
}

func middleElement(right elementType: Symbol) -> Value {
    fatalError("middleElement of stdlib is not yet implemented.")
}

func lastElement(right elementType: Symbol) -> Value {
    fatalError("lastElement of stdlib is not yet implemented.")
}

func randomElement(right elementType: Symbol) -> Value {
    fatalError("randomElement of stdlib is not yet implemented.")
}

func allElements(right elementType: Symbol) -> Value {
    fatalError("allElements of stdlib is not yet implemented.")
}

func beforeElement(left elementType: Symbol,right expression: Value) -> Value {
    fatalError("beforeElement of stdlib is not yet implemented.")
}

func afterElement(left elementType: Symbol,right expression: Value) -> Value {
    fatalError("afterElement of stdlib is not yet implemented.")
}

func insertBefore(right expression: Value) -> Value {
    fatalError("insertBefore of stdlib is not yet implemented.")
}

func insertAfter(right expression: Value) -> Value {
    fatalError("insertAfter of stdlib is not yet implemented.")
}

func insertAtBeginning() -> Value {
    fatalError("insertAtBeginning of stdlib is not yet implemented.")
}

func insertAtEnd() -> Value {
    fatalError("insertAtEnd of stdlib is not yet implemented.")
}