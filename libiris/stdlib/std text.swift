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


func beginsWith(left: String, right: String) throws -> Bool {
    return left.lowercased().hasPrefix(right.lowercased())
}

func endsWith(left: String, right: String) throws -> Bool {
    return left.lowercased().hasSuffix(right.lowercased())
}

func contains(left: String, right: String) throws -> Bool {
    return left.lowercased().contains(right.lowercased())
}

func isIn(left: String, right: String) throws -> Bool {
    return right.lowercased().contains(left.lowercased())
}


/******************************************************************************/
// concatenation (currently text only but should support collections too)

// TO DO: what if mixed types (e.g. text+list) are given?

func joinValues(left: String, right: String) throws -> String { return left + right }


/******************************************************************************/

func uppercase(text: String) -> String { return text.uppercased() }
func lowercase(text: String) -> String { return text.lowercased() }



func formatCode(value: Value) -> String {
    return value.description // TO DO: use literalDescription/PP (needs [command?] env)
}
