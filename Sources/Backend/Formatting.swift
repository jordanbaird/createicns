//
// Formatting.swift
// createicns
//

import Darwin

// MARK: TextOutputColor

/// Colors to use to format text when displayed in a command line interface.
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

// MARK: TextOutputStyle

/// Styles to use to format text when displayed in a command line interface.
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

// MARK: FormattedText

/// Text that is displayed in a formatted representation when printed to a
/// command line interface.
public struct FormattedText {
    /// The components that make up this text instance.
    private var components: [FormattingComponent]

    /// Creates a text instance with the given components.
    private init(components: [FormattingComponent]) {
        self.components = components
    }

    /// Creates an empty text instance.
    public init() {
        self.init(components: [])
    }

    /// Creates a text instance with a textual representation of the given value,
    /// displayed with the given color and style.
    public init<Value: CustomStringConvertible>(
        _ value: Value,
        color: TextOutputColor? = nil,
        style: TextOutputStyle? = nil
    ) {
        self.init(components: [
            .component(value: value, color: color, style: style),
        ])
    }

    /// Creates a text instance with the same components as the given instance.
    public init(_ formattedText: Self) {
        self.init(components: formattedText.components)
    }

    /// Creates a text instance with the contents of the given string.
    public init(contentsOf string: String) {
        self.init(components: [.unformatted(string)])
    }

    /// Appends the components in the given text instance to this instance's components.
    public mutating func append(_ other: Self) {
        components.append(contentsOf: other.components)
    }

    /// Appends the contents of the given string to this text instance.
    public mutating func append(contentsOf string: String) {
        append(Self(contentsOf: string))
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
        self.init(contentsOf: value)
    }
}

// MARK: FormattedText: ExpressibleByStringInterpolation
extension FormattedText: ExpressibleByStringInterpolation {
    public struct StringInterpolation: StringInterpolationProtocol {
        fileprivate var components = [FormattingComponent]()

        public init(literalCapacity: Int, interpolationCount: Int) { }

        public mutating func appendLiteral(_ literal: String) {
            components.append(.unformatted(literal))
        }

        public mutating func appendInterpolation<Value: CustomStringConvertible>(
            _ value: Value,
            color: TextOutputColor? = nil,
            style: TextOutputStyle? = nil
        ) {
            components.append(
                .component(value: value, color: color, style: style)
            )
        }
    }

    public init(stringInterpolation interpolation: StringInterpolation) {
        self.init(components: interpolation.components)
    }
}
