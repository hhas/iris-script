//
//  stdlib/handlers.swift
//

/******************************************************************************/
// text manipulation

// comparison // TO DO: text comparisons are case-insensitive by default; how to cache lowercased strings on repeated use? (would require extending backing store); alternative is to use Foundation string comparison API, which can normalize


// comparison
func isBefore(left: String, right: String) throws -> Bool { return left.lowercased() <  right.lowercased() }
func isNotAfter(left: String, right: String) throws -> Bool { return left.lowercased() <= right.lowercased() }
func isSameAs(left: String, right: String) throws -> Bool { return left.lowercased() == right.lowercased() }
func isNotSameAs(left: String, right: String) throws -> Bool { return left.lowercased() != right.lowercased() }
func isAfter(left: String, right: String) throws -> Bool { return left.lowercased() >  right.lowercased() }
func isNotBefore(left: String, right: String) throws -> Bool { return left.lowercased() >= right.lowercased() }



func uppercase(text: String) -> String { return text.uppercased() }
func lowercase(text: String) -> String { return text.lowercased() }



func formatCode(value: Value) -> String {
    return value.description
}

