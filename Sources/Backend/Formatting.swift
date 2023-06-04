//
// Formatting.swift
// createicns
//

import Darwin

// MARK: TextOutputColor

/// Colors to use to format text when displayed in a command line interface.
enum TextOutputColor {
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
enum TextOutputStyle {
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

// MARK: FormattingComponents

/// Components used to build a `FormattedText` instance.
struct FormattingComponents {
    private enum Component {
        case unformatted(String)
        case formatted(String, TextOutputColor?, TextOutputStyle?)

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

    private var components: [Component]

    var formatted: String {
        components.map { $0.formattedDescription }.joined()
    }

    var unformatted: String {
        components.map { $0.unformattedDescription }.joined()
    }

    private init(components: [Component]) {
        self.components = components
    }

    init() {
        self.init(components: [])
    }

    init<Value: CustomStringConvertible>(value: Value, color: TextOutputColor? = nil, style: TextOutputStyle? = nil) {
        let string = String(describing: value)
        if string.isEmpty {
            self.init(components: [])
        } else if color != nil || style != nil {
            self.init(components: [.formatted(string, color, style)])
        } else {
            self.init(components: [.unformatted(string)])
        }
    }

    mutating func append(_ other: Self) {
        components.append(contentsOf: other.components)
    }
}

// MARK: FormattedText

/// Text that is displayed in a formatted representation when printed to a
/// command line interface.
struct FormattedText {
    /// The components that make up this text instance.
    var components: FormattingComponents

    /// Creates a text instance with the given components.
    init(components: FormattingComponents) {
        self.components = components
    }

    /// Creates an empty text instance.
    init() {
        self.init(components: FormattingComponents())
    }

    /// Creates a text instance with a textual representation of the given value,
    /// displayed with the given color and style.
    init<Value: CustomStringConvertible>(_ value: Value, color: TextOutputColor? = nil, style: TextOutputStyle? = nil) {
        self.init(components: FormattingComponents(value: value, color: color, style: style))
    }

    /// Creates a text instance with the same components as the given instance.
    init(_ formattedText: Self) {
        self.init(components: formattedText.components)
    }

    /// Appends the components in the given text instance to this instance's components.
    mutating func append(_ other: Self) {
        components.append(other.components)
    }
}

// MARK: FormattedText: TextOutputStreamable
extension FormattedText: TextOutputStreamable {
    func write<Target: TextOutputStream>(to target: inout Target) {
        if isatty(STDOUT_FILENO) == 1 && isatty(STDERR_FILENO) == 1 {
            target.write(components.formatted)
        } else {
            target.write(components.unformatted)
        }
    }
}

// MARK: FormattedText: ExpressibleByStringLiteral
extension FormattedText: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(components: FormattingComponents(value: value))
    }
}

// MARK: FormattedText: ExpressibleByStringInterpolation
extension FormattedText: ExpressibleByStringInterpolation {
    struct StringInterpolation: StringInterpolationProtocol {
        fileprivate var components = FormattingComponents()

        init(literalCapacity: Int, interpolationCount: Int) { }

        mutating func appendLiteral(_ literal: String) {
            components.append(FormattingComponents(value: literal))
        }

        mutating func appendInterpolation<Value: CustomStringConvertible>(
            _ value: Value,
            color: TextOutputColor? = nil,
            style: TextOutputStyle? = nil
        ) {
            components.append(FormattingComponents(value: value, color: color, style: style))
        }
    }

    init(stringInterpolation interpolation: StringInterpolation) {
        self.init(components: interpolation.components)
    }
}

// MARK: FormattedError

/// An error type that is displayed in a formatted representation when printed
/// to a command line interface.
protocol FormattedError: Error, CustomStringConvertible {
    /// The formatted message to display.
    ///
    /// If one of either standard output or standard error does not point to a
    /// terminal, the message is displayed without formatting.
    var message: FormattedText { get }
}

// MARK: FormattedError: CustomStringConvertible
extension FormattedError {
    var description: String {
        String(describing: message)
    }
}
