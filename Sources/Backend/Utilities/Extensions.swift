//
// Extensions.swift
// createicns
//

extension String {
    /// Returns a string formed by removing all characters from the end of the
    /// string that satisfy the given predicate.
    ///
    /// - Parameter predicate: A closure which determines if the element should
    ///   be omitted from the resulting string.
    ///
    /// - Returns: A string formed by removing all characters from the end of
    ///   this string for which `predicate` returns `true`.
    func trimmingSuffix(while predicate: (Character) throws -> Bool) rethrows -> Self {
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
        return try Self(self[..<suffixStart()])
    }
}
