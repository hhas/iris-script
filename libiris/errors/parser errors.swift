//
//  parser errors.swift
//  libiris
//

import Foundation



public enum BadSyntax: NativeError { // while tokens containing invalid code are marked as bad syntax, they do not constitute syntax errors if they appear within a string or annotation literal; however, this can only be determined when the script is parsed in full - all a single-line lexer can do is mark it as a potential issue and move on to the next token
    
    public var description: String {
        switch self {
        case .unterminatedAnnotation:   return "unterminated annotation"
        case .unterminatedList:         return "unterminated list"
        case .unterminatedRecord:       return "unterminated record"
        case .unterminatedGroup:        return "unterminated group"
        case .unterminatedQuotedName:   return "unterminated quotedname"
        case .unterminatedQuotedString: return "unterminated quoted string"
        case .missingExpression:        return "missing expression"
        case .missingName:              return "missing name"
        case .unterminatedExpression:   return "unterminated expression"
        case .illegalCharacters:        return "illegal character[s]"
        case .malformedWhitespace:     return "malformed whitespace"
        }
    }
    
    // TBC: case names and human-readable descriptions
    
    case unterminatedAnnotation
    case unterminatedList
    case unterminatedRecord
    case unterminatedGroup
    case unterminatedQuotedName
    case unterminatedQuotedString
    case unterminatedExpression
    case missingExpression // TO DO: parameterize with expected expression type?
    case missingName // e.g. handler name or pair label; TO DO: how should missing colon be reported?
    // TO DO: what else?
    case illegalCharacters
    case malformedWhitespace
}


public class SyntaxErrorDescription: NativeError {
    
    public var description: String {
        return "«Syntax Error: \(self.error)»"
    }
    
    public let error: NativeError
    
    public init(error: NativeError) {
        self.error = error
    }
    public convenience init(_ message: String) {
        self.init(error: InternalError(description: message))
    }
}

