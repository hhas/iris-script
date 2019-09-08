//
//  stdlib_operators.swift
//
//  Bridging code for primitive handlers. This file is auto-generated; do not edit directly.
//

import Foundation

func stdlib_loadOperators(into registry: OperatorRegistry) {
    registry.add("^", .infix, 600, .right, ["to_the_power_of"])
    registry.add("positive", .prefix, 598, .left, ["+", "＋"])
    registry.add("negative", .prefix, 598, .left, ["-", "－", "−", "﹣"])
    registry.add("*", .infix, 596, .left, ["×"])
    registry.add("/", .infix, 596, .left, ["÷"])
    registry.add("div", .infix, 596, .left, [])
    registry.add("mod", .infix, 596, .left, [])
    registry.add("+", .infix, 590, .left, ["＋"])
    registry.add("-", .infix, 590, .left, ["－", "−", "﹣"])
    registry.add("<", .infix, 540, .left, [])
    registry.add("≤", .infix, 540, .left, ["<="])
    registry.add("=", .infix, 540, .left, ["=="])
    registry.add("≠", .infix, 540, .left, ["<>"])
    registry.add(">", .infix, 540, .left, [])
    registry.add("≥", .infix, 540, .left, [">="])
    registry.add("NOT", .prefix, 400, .left, [])
    registry.add("AND", .infix, 398, .left, [])
    registry.add("OR", .infix, 396, .left, [])
    registry.add("XOR", .infix, 394, .left, [])
    registry.add("is_before", .infix, 540, .left, [])
    registry.add("is_not_after", .infix, 540, .left, ["is_before_or_same_as"])
    registry.add("is_same_as", .infix, 540, .left, [])
    registry.add("is_not_same_as", .infix, 540, .left, [])
    registry.add("is_after", .infix, 540, .left, [])
    registry.add("is_not_before", .infix, 540, .left, ["is_after_or_same_as"])
    registry.add("&", .infix, 340, .left, [])
    registry.add("is_a", .infix, 540, .left, [])
    registry.add("as", .infix, 350, .left, [])
    registry.add("to", .prefix, 180, .left, [])
    registry.add("when", .prefix, 180, .left, [])
    registry.add("if", .custom(parseIfThenOperator), 100, .left, [])
    registry.add("else", .infix, 90, .left, [])
    registry.add("while", .custom(parseWhileRepeatOperator), 100, .left, [])
    registry.add("repeat", .custom(parseRepeatWhileOperator), 100, .left, [])
    registry.add("tell", .custom(parseTellToOperator), 100, .left, [])
    registry.add("of", .infix, 306, .right, [])
    registry.add("at", .infix, 310, .left, [])
    registry.add("named", .infix, 310, .left, [])
    registry.add("id", .infix, 310, .left, [])
    registry.add("where", .infix, 310, .left, [])
    registry.add("thru", .infix, 330, .left, [])
    registry.add("first", .prefix, 320, .left, [])
    registry.add("middle", .prefix, 320, .left, [])
    registry.add("last", .prefix, 320, .left, [])
    registry.add("any", .prefix, 320, .left, ["some"])
    registry.add("every", .prefix, 320, .left, ["all"])
    registry.add("before", .infix, 320, .left, [])
    registry.add("after", .infix, 320, .left, [])
    registry.add("before", .prefix, 320, .left, [])
    registry.add("after", .prefix, 320, .left, [])
    registry.add("beginning", .atom, 320, .left, [])
    registry.add("end", .atom, 320, .left, [])
}


