//
//  Extensions.swift
//  createicns
//

// MARK: - CustomStringConvertible

extension CustomStringConvertible {
    /// Returns a textual representation of this value, formatted using
    /// the given color and style.
    ///
    /// - Parameters:
    ///   - color: The color to use in the resulting formatted text.
    ///   - style: The style to use in the resulting formatted text.
    ///
    /// - Returns: A textual representation of this value, formatted using
    ///   the given color and style.
    public func formatted(color: TextOutputColor, style: TextOutputStyle) -> String {
        if OutputHandle.standardOutput.isTerminal && OutputHandle.standardError.isTerminal {
            return style.onCode + color.onCode + String(describing: self) + color.offCode + style.offCode
        } else {
            return String(describing: self)
        }
    }

    /// Returns a textual representation of this value, formatted using
    /// the given color.
    ///
    /// - Parameter color: The color to use in the resulting formatted text.
    ///
    /// - Returns: A textual representation of this value, formatted using
    ///   the given color.
    public func formatted(color: TextOutputColor) -> String {
        if OutputHandle.standardOutput.isTerminal && OutputHandle.standardError.isTerminal {
            return color.onCode + String(describing: self) + color.offCode
        } else {
            return String(describing: self)
        }
    }

    /// Returns a textual representation of this value, formatted using
    /// the given style.
    ///
    /// - Parameter style: The style to use in the resulting formatted text.
    ///
    /// - Returns: A textual representation of this value, formatted using
    ///   the given style.
    public func formatted(style: TextOutputStyle) -> String {
        if OutputHandle.standardOutput.isTerminal && OutputHandle.standardError.isTerminal {
            return style.onCode + String(describing: self) + style.offCode
        } else {
            return String(describing: self)
        }
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
