//
// Formatting.swift
// createicns
//

private func shouldFormat(formattingHint: FormattedText.FormattingHint) -> Bool {
    switch formattingHint {
    case .formatted:
        return true
    case .unformatted:
        return false
    case .inferFromStandardOutput:
        return OutputHandle.standardOutput.isTerminal
    case .inferFromStandardError:
        return OutputHandle.standardError.isTerminal
    case .inferFromStandardOutputAndStandardError:
        return OutputHandle.standardOutput.isTerminal && OutputHandle.standardError.isTerminal
    }
}

// MARK: - TextOutputColor

/// Colors to use to format text when displayed in a terminal.
public enum TextOutputColor {
    /// Formats the text in red.
    case red
    /// Formats the text in green.
    case green
    /// Formats the text in yellow.
    case yellow
    /// Formats the text in cyan.
    case cyan
    /// Formats the text in the default color.
    case `default`

    fileprivate var onCode: String {
        switch self {
        case .red:
            return "\u{001B}[31m"
        case .green:
            return "\u{001B}[32m"
        case .yellow:
            return "\u{001B}[33m"
        case .cyan:
            return "\u{001B}[36m"
        case .default:
            return "\u{001B}[39m"
        }
    }

    fileprivate var offCode: String {
        switch self {
        case .red, .green, .yellow, .cyan:
            return "\u{001B}[0m"
        case .default:
            return ""
        }
    }
}

// MARK: TextOutputColor: Codable
extension TextOutputColor: Codable { }

// MARK: TextOutputColor: Equatable
extension TextOutputColor: Equatable { }

// MARK: TextOutputColor: Hashable
extension TextOutputColor: Hashable { }

// MARK: - TextOutputStyle

/// Styles to use to format text when displayed in a terminal.
public enum TextOutputStyle {
    /// Formats the text in bold.
    case bold
    /// Formats the text in the default style.
    case `default`

    fileprivate var onCode: String {
        switch self {
        case .bold:
            return "\u{001B}[1m"
        case .default:
            return ""
        }
    }

    fileprivate var offCode: String {
        switch self {
        case .bold:
            return "\u{001B}[22m"
        case .default:
            return ""
        }
    }
}

// MARK: TextOutputStyle: Codable
extension TextOutputStyle: Codable { }

// MARK: TextOutputStyle: Equatable
extension TextOutputStyle: Equatable { }

// MARK: TextOutputStyle: Hashable
extension TextOutputStyle: Hashable { }

// MARK: - FormattedTextComponent

/// A component in a formatted text instance.
///
/// A formatted text component is capable of producing both a formatted and
/// unformatted string representation of itself. When an instance of ``FormattedText``
/// needs to display its components, it uses the value of a provided formatting
/// hint to decide which representation to use.
public enum FormattedTextComponent {
    /// A component that contains unformatted text.
    case unformatted(String)

    /// A component that contains text that is formatted with a specified color.
    case color(String, TextOutputColor)

    /// A component that contains text that is formatted with a specified style.
    case style(String, TextOutputStyle)

    /// A component that contains text that is formatted with a specified format
    /// and style.
    case colorAndStyle(String, TextOutputColor, TextOutputStyle)

    /// The formatted representation of this component.
    public var formattedRepresentation: String {
        switch self {
        case .unformatted(let string):
            return string
        case .color(let string, let color):
            return [
                color.onCode,
                string,
                color.offCode,
            ].joined()
        case .style(let string, let style):
            return [
                style.onCode,
                string,
                style.offCode,
            ].joined()
        case .colorAndStyle(let string, let color, let style):
            return [
                style.onCode,
                color.onCode,
                string,
                color.offCode,
                style.offCode,
            ].joined()
        }
    }

    /// The unformatted representation of this component.
    var unformattedRepresentation: String {
        switch self {
        case .unformatted(let string),
             .color(let string, _),
             .style(let string, _),
             .colorAndStyle(let string, _, _):
            return string
        }
    }
}

// MARK: FormattedTextComponent: Codable
extension FormattedTextComponent: Codable { }

// MARK: FormattedTextComponent: Equatable
extension FormattedTextComponent: Equatable { }

// MARK: FormattedTextComponent: Hashable
extension FormattedTextComponent: Hashable { }

// MARK: - FormattedText

/// Text that is displayed in a formatted representation when printed to a terminal.
public struct FormattedText {

    // MARK: Types

    /// Constants that specify how to determine what representation of a formatted
    /// text instance to display.
    public enum FormattingHint {
        /// Specifies that a formatted text instance should display itself with a
        /// formatted representation.
        case formatted

        /// Specifies that a formatted text instance should display itself with an
        /// unformatted representation.
        case unformatted

        /// Specifies that the formatted text instance should infer which
        /// representation to display based on whether the standard output handle is
        /// a terminal.
        case inferFromStandardOutput

        /// Specifies that the formatted text instance should infer which
        /// representation to display based on whether the standard error handle is
        /// a terminal.
        case inferFromStandardError

        /// Specifies that the formatted text instance should infer which representation
        /// to display based on whether both the standard output and standard error
        /// handles are terminals.
        case inferFromStandardOutputAndStandardError
    }

    /// The components that make up this formatted text instance.
    private var components: ContiguousArray<FormattedTextComponent>

    /// Creates a formatted text instance with the given components.
    public init<S: Sequence>(components: S) where S.Element == FormattedTextComponent {
        self.components = ContiguousArray(components)
    }

    /// Creates a formatted text instance with the given component.
    public init(component: FormattedTextComponent) {
        self.init(components: CollectionOfOne(component))
    }

    /// Creates an empty formatted text instance.
    public init() {
        self.init(components: EmptyCollection())
    }

    /// Creates a formatted text instance that is equivalent to the given instance.
    public init(_ formattedText: Self) {
        self = formattedText
    }

    /// Creates a formatted text instance with the contents of the given string.
    public init<S: StringProtocol>(contentsOf string: S) {
        self.init(component: .unformatted(String(string)))
    }

    /// Creates a formatted text instance with the given value, color, and style.
    public init<Value: CustomStringConvertible>(
        _ value: Value,
        color: TextOutputColor,
        style: TextOutputStyle
    ) {
        self.init(component: .colorAndStyle(String(describing: value), color, style))
    }

    /// Creates a formatted text instance with the given value and color.
    public init<Value: CustomStringConvertible>(_ value: Value, color: TextOutputColor) {
        self.init(component: .color(String(describing: value), color))
    }

    /// Creates a formatted text instance with the given value and style.
    public init<Value: CustomStringConvertible>(_ value: Value, style: TextOutputStyle) {
        self.init(component: .style(String(describing: value), style))
    }

    /// Returns a string representation from the components in this instance.
    ///
    /// If a value is provided for the `formattingHint` parameter, it will be used to
    /// determine whether the string will be returned in a formatted or unformatted
    /// representation. If no value is provided, the representation will be inferred
    /// based on whether the standard output and standard error handles are terminals.
    ///
    /// - Parameter formattingHint: A formatting hint to use to determine whether to
    ///   return the string in a formatted or unformatted representation.
    ///
    /// - Returns: A string representation of this instance's components.
    public func string(formattingHint: FormattingHint? = nil) -> String {
        if shouldFormat(formattingHint: formattingHint ?? .inferFromStandardOutputAndStandardError) {
            return lazy.map { $0.formattedRepresentation }.joined()
        }
        return lazy.map { $0.unformattedRepresentation }.joined()
    }

    /// Appends the given formatted text instance to this instance.
    public mutating func append(_ formattedText: Self) {
        components.append(contentsOf: formattedText.components)
    }

    /// Appends the contents of the given string to this instance.
    public mutating func append<S: StringProtocol>(contentsOf string: S) {
        append(Self(contentsOf: string))
    }

    /// Appends a formatted text instance created using the given value, color, and style.
    public mutating func append<Value: CustomStringConvertible>(
        _ value: Value,
        color: TextOutputColor,
        style: TextOutputStyle
    ) {
        append(Self(value, color: color, style: style))
    }

    /// Appends a formatted text instance created using the given value and color.
    public mutating func append<Value: CustomStringConvertible>(_ value: Value, color: TextOutputColor) {
        append(Self(value, color: color))
    }

    /// Appends a formatted text instance created using the given value and style.
    public mutating func append<Value: CustomStringConvertible>(_ value: Value, style: TextOutputStyle) {
        append(Self(value, style: style))
    }

    /// Returns a new formatted text instance by appending the given formatted text
    /// instance to this instance.
    public func appending(_ formattedText: Self) -> Self {
        var copy = self
        copy.append(formattedText)
        return copy
    }

    /// Returns a new formatted text instance by appending the contents of the given
    /// string to this instance.
    public func appending<S: StringProtocol>(contentsOf string: S) -> Self {
        var copy = self
        copy.append(contentsOf: string)
        return copy
    }

    /// Returns a new formatted text instance by appending a formatted text instance
    /// created using the given value, color, and style.
    public func appending<Value: CustomStringConvertible>(
        _ value: Value,
        color: TextOutputColor,
        style: TextOutputStyle
    ) -> Self {
        var copy = self
        copy.append(value, color: color, style: style)
        return copy
    }

    /// Returns a new formatted text instance by appending a formatted text instance
    /// created using the given value and color.
    public func appending<Value: CustomStringConvertible>(_ value: Value, color: TextOutputColor) -> Self {
        var copy = self
        copy.append(value, color: color)
        return copy
    }

    /// Returns a new formatted text instance by appending a formatted text instance
    /// created using the given value and style.
    public func appending<Value: CustomStringConvertible>(_ value: Value, style: TextOutputStyle) -> Self {
        var copy = self
        copy.append(value, style: style)
        return copy
    }
}

// MARK: FormattedText Operators
extension FormattedText {
    public static func + (lhs: Self, rhs: Self) -> Self {
        lhs.appending(rhs)
    }

    public static func + <S: StringProtocol>(lhs: Self, rhs: S) -> Self {
        lhs.appending(contentsOf: rhs)
    }

    public static func + <S: StringProtocol>(lhs: S, rhs: Self) -> Self {
        Self(contentsOf: lhs).appending(rhs)
    }

    public static func += (lhs: inout Self, rhs: Self) {
        lhs.append(rhs)
    }

    public static func += <S: StringProtocol>(lhs: inout Self, rhs: S) {
        lhs.append(contentsOf: rhs)
    }
}

// MARK: FormattedText: ExpressibleByStringLiteral
extension FormattedText: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(component: .unformatted(value))
    }
}

// MARK: FormattedText: ExpressibleByStringInterpolation
extension FormattedText: ExpressibleByStringInterpolation {
    public struct StringInterpolation: StringInterpolationProtocol {
        private var components = ContiguousArray<FormattedTextComponent>()

        /// Returns a formatted text instance from the components in this interpolation.
        var formattedText: FormattedText {
            FormattedText(components: components)
        }

        public init(literalCapacity: Int, interpolationCount: Int) { }

        private mutating func appendComponents<S: Sequence>(_ components: S) where S.Element == FormattedTextComponent {
            self.components.append(contentsOf: components)
        }

        private mutating func appendComponent(_ component: FormattedTextComponent) {
            appendComponents(CollectionOfOne(component))
        }

        public mutating func appendLiteral(_ literal: String) {
            appendComponent(.unformatted(literal))
        }

        public mutating func appendInterpolation(_ formattedText: FormattedText) {
            appendComponents(formattedText.components)
        }

        public mutating func appendInterpolation<Value: CustomStringConvertible>(
            _ value: Value,
            color: TextOutputColor,
            style: TextOutputStyle
        ) {
            appendComponent(.colorAndStyle(String(describing: value), color, style))
        }

        public mutating func appendInterpolation<Value: CustomStringConvertible>(
            _ value: Value,
            color: TextOutputColor
        ) {
            appendComponent(.color(String(describing: value), color))
        }

        public mutating func appendInterpolation<Value: CustomStringConvertible>(
            _ value: Value,
            style: TextOutputStyle
        ) {
            appendComponent(.style(String(describing: value), style))
        }

        public mutating func appendInterpolation<Value: CustomStringConvertible>(_ value: Value) {
            appendComponent(.unformatted(String(describing: value)))
        }
    }

    public init(stringInterpolation interpolation: StringInterpolation) {
        self = interpolation.formattedText
    }
}

// MARK: FormattedText: CustomStringConvertible
extension FormattedText: CustomStringConvertible {
    public var description: String {
        string(formattingHint: nil)
    }
}

// MARK: FormattedText: TextOutputStreamable
extension FormattedText: TextOutputStreamable {
    public func write<Target: TextOutputStream>(to target: inout Target) {
        target.write(string(formattingHint: nil))
    }
}

// MARK: FormattedText: Sequence
extension FormattedText: Sequence {
    public typealias Element = FormattedTextComponent

    public struct Iterator: IteratorProtocol {
        private var base: IndexingIterator<ContiguousArray<Element>>

        fileprivate init(_ formattedText: FormattedText) {
            self.base = formattedText.components.makeIterator()
        }

        public mutating func next() -> Element? {
            base.next()
        }
    }

    public func makeIterator() -> Iterator {
        Iterator(self)
    }
}

// MARK: FormattedText: Collection
extension FormattedText: Collection {
    public var startIndex: Int {
        components.startIndex
    }

    public var endIndex: Int {
        components.endIndex
    }

    public func index(after i: Int) -> Int {
        components.index(after: i)
    }
}

// MARK: FormattedText: RangeReplaceableCollection
extension FormattedText: RangeReplaceableCollection {
    public mutating func replaceSubrange<C: Collection>(
        _ subrange: Range<Int>,
        with newElements: C
    ) where C.Element == Element {
        components.replaceSubrange(subrange, with: newElements)
    }
}

// MARK: FormattedText: MutableCollection
extension FormattedText: MutableCollection {
    public subscript(position: Int) -> FormattedTextComponent {
        get { components[position] }
        set { components[position] = newValue }
    }
}

// MARK: FormattedText: Codable
extension FormattedText: Codable { }

// MARK: FormattedText: Equatable
extension FormattedText: Equatable { }

// MARK: FormattedText: Hashable
extension FormattedText: Hashable { }

// MARK: FormattedText: BidirectionalCollection
extension FormattedText: BidirectionalCollection { }

// MARK: FormattedText: RandomAccessCollection
extension FormattedText: RandomAccessCollection { }
