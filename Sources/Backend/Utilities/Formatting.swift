//
// Formatting.swift
// createicns
//

import Darwin

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

// MARK: - FormattingComponent

private enum FormattingComponent {
    case unformatted(String)
    case formatted(String, TextOutputColor?, TextOutputStyle?)

    static func component<Value: CustomStringConvertible>(
        value: Value,
        color: TextOutputColor? = nil,
        style: TextOutputStyle? = nil
    ) -> Self {
        let string = String(describing: value)
        if color != nil || style != nil {
            return .formatted(string, color, style)
        }
        return .unformatted(string)
    }

    var formattedDescription: String {
        switch self {
        case .unformatted(let string):
            return string
        case .formatted(let string, let color, let style):
            return [
                style?.onCode ?? "",
                color?.onCode ?? "",
                string,
                color?.offCode ?? "",
                style?.offCode ?? "",
            ].joined()
        }
    }

    var unformattedDescription: String {
        switch self {
        case .unformatted(let string), .formatted(let string, _, _):
            return string
        }
    }
}

// MARK: - FormattedText

/// Text that is displayed in a formatted representation when printed to a terminal.
public struct FormattedText {
    /// The components that make up this text instance.
    private let components: [FormattingComponent]

    /// Creates a text instance with the given components.
    private init(components: [FormattingComponent]) {
        self.components = components
    }

    /// Creates an empty text instance.
    public init() {
        self.init(components: [])
    }

    /// Creates a text instance with a formatted representation of the given value.
    public init<Value: CustomStringConvertible>(
        _ value: Value,
        color: TextOutputColor,
        style: TextOutputStyle
    ) {
        self.init(components: [
            .component(value: value, color: color, style: style),
        ])
    }

    /// Creates a text instance with a formatted representation of the given value.
    public init<Value: CustomStringConvertible>(_ value: Value, color: TextOutputColor) {
        self.init(components: [
            .component(value: value, color: color, style: nil),
        ])
    }

    /// Creates a text instance with a formatted representation of the given value.
    public init<Value: CustomStringConvertible>(_ value: Value, style: TextOutputStyle) {
        self.init(components: [
            .component(value: value, color: nil, style: style),
        ])
    }

    /// Creates a text instance with the same components as the given instance.
    public init(_ text: Self) {
        self.init(components: text.components)
    }

    /// Returns a new text instance by appending the components in the given text
    /// instance to this instance's components.
    public func appending(_ text: Self) -> Self {
        Self(components: components + text.components)
    }

    /// Returns a new text instance by appending a formatted representation of the
    /// given value.
    public func appending<Value: CustomStringConvertible>(
        _ value: Value,
        color: TextOutputColor,
        style: TextOutputStyle
    ) -> Self {
        appending(Self(value, color: color, style: style))
    }

    /// Returns a new text instance by appending a formatted representation of the
    /// given value.
    public func appending<Value: CustomStringConvertible>(_ value: Value, color: TextOutputColor) -> Self {
        appending(Self(value, color: color))
    }

    /// Returns a new text instance by appending a formatted representation of the
    /// given value.
    public func appending<Value: CustomStringConvertible>(_ value: Value, style: TextOutputStyle) -> Self {
        appending(Self(value, style: style))
    }

    /// Appends the components in the given text instance to this instance's components.
    public mutating func append(_ text: Self) {
        self = appending(text)
    }

    /// Appends a formatted representation of the given value.
    public mutating func append<Value: CustomStringConvertible>(
        _ value: Value,
        color: TextOutputColor,
        style: TextOutputStyle
    ) {
        self = appending(value, color: color, style: style)
    }

    /// Appends a formatted representation of the given value.
    public mutating func append<Value: CustomStringConvertible>(_ value: Value, color: TextOutputColor) {
        self = appending(value, color: color)
    }

    /// Appends a formatted representation of the given value.
    public mutating func append<Value: CustomStringConvertible>(_ value: Value, style: TextOutputStyle) {
        self = appending(value, style: style)
    }
}

// MARK: FormattedText: TextOutputStreamable
extension FormattedText: TextOutputStreamable {
    public func write<Target: TextOutputStream>(to target: inout Target) {
        if isatty(STDOUT_FILENO) == 1 && isatty(STDERR_FILENO) == 1 {
            for component in components {
                target.write(component.formattedDescription)
            }
        } else {
            for component in components {
                target.write(component.unformattedDescription)
            }
        }
    }
}

// MARK: FormattedText: ExpressibleByStringLiteral
extension FormattedText: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(components: [.unformatted(value)])
    }
}

// MARK: FormattedText: ExpressibleByStringInterpolation
extension FormattedText: ExpressibleByStringInterpolation {
    public struct StringInterpolation: StringInterpolationProtocol {
        fileprivate var components = [FormattingComponent]()

        public init(literalCapacity: Int, interpolationCount: Int) { }

        private mutating func appendComponents(_ components: [FormattingComponent]) {
            self.components.append(contentsOf: components)
        }

        private mutating func appendComponent(_ component: FormattingComponent) {
            appendComponents([component])
        }

        public mutating func appendLiteral(_ literal: String) {
            appendComponent(.unformatted(literal))
        }

        public mutating func appendInterpolation<Value: CustomStringConvertible>(
            _ value: Value,
            color: TextOutputColor,
            style: TextOutputStyle
        ) {
            appendComponent(.component(value: value, color: color, style: style))
        }

        public mutating func appendInterpolation<Value: CustomStringConvertible>(
            _ value: Value,
            color: TextOutputColor
        ) {
            appendComponent(.component(value: value, color: color, style: nil))
        }

        public mutating func appendInterpolation<Value: CustomStringConvertible>(
            _ value: Value,
            style: TextOutputStyle
        ) {
            appendComponent(.component(value: value, color: nil, style: style))
        }

        public mutating func appendInterpolation<Value: CustomStringConvertible>(_ value: Value) {
            appendComponent(.component(value: value, color: nil, style: nil))
        }

        public mutating func appendInterpolation(_ text: FormattedText) {
            appendComponents(text.components)
        }
    }

    public init(stringInterpolation interpolation: StringInterpolation) {
        self.init(components: interpolation.components)
    }
}
