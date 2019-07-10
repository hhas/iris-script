//
//  lexer.swift
//  iris-script
//

import Foundation


// needs to distinguish:

// reserved punctuation

// contiguous alphanumeric (digits, Latin, Cyrillic, Arabic, Han, etc) with interstitial underscores

// linebreaks

// contiguous whitespace

// any other contiguous chars


// Q. how best to match combinations of alnum and symbol chars, e.g. `-180°C`, `($12.20)`?
