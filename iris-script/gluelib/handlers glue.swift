//
//  handlers glue.swift
//  gluelib
//
//

import Foundation



struct HandlerGlue {
    // TO DO: user documentation (from annotations)
    typealias Parameter = (label: String, coercion: String)
    let name: String
    let parameters: [Parameter]
    let result: String // coercion name
    let canError: Bool
    let useScopes: [String] // commandEnv, handlerEnv // TO DO: any use-cases for per-invocation sub-env?
    let swiftFunction: (name: String, params: [String])? // if different to native names
    let operatorSyntax: (form: String, precedence: Int, isLeftAssociative: Bool, aliases: [String])?
}



func defineHandlerGlue(handler: Handler, commandEnv: Scope) throws {
    print(handler)
}


/*
let libraryName = "stdlib"

let handlerGlues = [
    HandlerGlue(name: "add", parameters: [("left", "AsNumber()"), ("right", "AsNumber()")], result: "AsNumber()", canError: true, useScopes: [], swiftFunction: nil, operatorSyntax: (form: "+", precedence: 560, isLeftAssociative: false, aliases: [])),
    HandlerGlue(name: "subtract", parameters: [("left", "AsNumber()"), ("right", "AsNumber()")], result: "AsNumber()", canError: true, useScopes: [], swiftFunction: nil, operatorSyntax: (form: "-", precedence: 560, isLeftAssociative: false, aliases: [])),]
*/
//print(template.render())



func renderGlue(libraryName: String, handlerGlues: [HandlerGlue]) -> String {
    return handlersTemplate.render((libraryName, handlerGlues))
}


//print(handlersTemplate.debugDescription)
//print(source)
