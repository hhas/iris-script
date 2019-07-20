//
//  operator reader.swift
//  iris-script
//

import Foundation


// TO DO: given undifferentiated .symbols token, decompose into one or more .symbols and/or .operator(OperatorDefinition) tokens and unpop back onto token stream


// - word-based operators (e.g. `mod`) are whole-token match against .word, caveat where word has contiguous `:` suffix indicating it's a record field/argument label


// - symbol-based operators (e.g. `≠`) require both whole-token matching and longest-substring-match of .symbol content (note that: whole-token matching of .symbol is just an opportunistic shortcut for a longest match that consumes all chars; it may or may not be worth the effort in practice, though seeing as it's one quick Dictionary lookup it hardly increases implementation complexity or performance overhead)


// Q. should we disallow digits within operator names? (probably: it'll keep operator matching much simpler; contiguous sequences of digits [and words] after a non-operator word can then unambiguously be reduced to single Name lexeme)

// note: 'longest match' cannot resolve ambiguous combinations where a .symbols content can be matched as either a long operator + unknown symbol or a shorter operator + longer operator; however, inclined to keep it that way as it makes grammar rules simple for user to memorize ("for alternate interpretation, stick a space in")


// Q. what about currency and measurement prefixes/suffixes? should they have their own single-task reader, or be provided as part of operator reader? (given that units attach directly to literal numbers and aren't meant to be parameterizable with arbitrary exprs [cf prefix/postfix operators], it's probably best to make them their own reader that adjoins the numeric reader)

