//
//  stdlib_operators.swift
//  iris-script
//

import Foundation

//
//  stdlib_operators.swift
//
//  Bridging code for primitive handlers. This file is auto-generated; do not edit directly.
//

import Foundation

func stdlib_loadOperators(into registry: OperatorRegistry) {
    registry.add("positive", .prefix, 598, .left, [])
    registry.add("negative", .prefix, 598, .left, [])
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
}


