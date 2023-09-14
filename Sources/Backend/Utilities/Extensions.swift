//
//  Extensions.swift
//  createicns
//

// MARK: - CustomStringConvertible

extension CustomStringConvertible {
    /// Returns a formatted text instance that formats a textual representation of
    /// this value using the given color and style.
    ///
    /// - Parameters:
    ///   - color: The color to use in the resulting formatted text instance.
    ///   - style: The style to use in the resulting formatted text instance.
    ///
    /// - Returns: A formatted text instance that formats a textual representation 
    ///   of this value using the given color and style.
    func formatted(color: TextOutputColor, style: TextOutputStyle) -> FormattedText {
        FormattedText(self, color: color, style: style)
    }

    /// Returns a formatted text instance that formats a textual representation of
    /// this value using the given color.
    ///
    /// - Parameter color: The color to use in the resulting formatted text instance.
    ///
    /// - Returns: A formatted text instance that formats a textual representation 
    ///   of this value using the given color.
    func formatted(color: TextOutputColor) -> FormattedText {
        FormattedText(self, color: color)
    }

    /// Returns a formatted text instance that formats a textual representation of
    /// this value using the given style.
    ///
    /// - Parameter style: The style to use in the resulting formatted text instance.
    ///
    /// - Returns: A formatted text instance that formats a textual representation 
    ///   of this value using the given style.
    func formatted(style: TextOutputStyle) -> FormattedText {
        FormattedText(self, style: style)
    }
}

// MARK: - StringProtocol

extension StringProtocol {
    /// Returns a string formed by removing all characters from the end of this
    /// string that satisfy the given predicate.
    ///
    /// - Parameter predicate: A closure which determines if the character should 
    ///   be omitted from the resulting string.
    ///
    /// - Returns: A string formed by removing all characters from the end of 
    ///   this string for which `predicate` returns `true`.
    func trimmingSuffix(while predicate: (Character) throws -> Bool) rethrows -> String {
        func suffixStart() throws -> Index {
            var current = endIndex
            while current > startIndex {
                let nextBack = index(before: current)
                if try !predicate(self[nextBack]) {
                    return current
                }
                current = nextBack
            }
            return current
        }
        return try String(self[..<suffixStart()])
    }
}
