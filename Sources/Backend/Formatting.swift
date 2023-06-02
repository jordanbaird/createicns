//
// Formatting.swift
// createicns
//

enum TextOutputColor {
    case red
    case green
    case yellow
    case cyan
    case `default`
}

enum TextOutputStyle {
    case bold
    case `default`
}

struct TextOutputFormatter {
    private let onCodes: [String]
    private let offCodes: [String]

    init(color: TextOutputColor, style: TextOutputStyle) {
        let colorCodes: (on: String, off: String) = {
            switch color {
            case .red:
                return ("\u{001B}[31m", "\u{001B}[0m")
            case .green:
                return ("\u{001B}[32m", "\u{001B}[0m")
            case .yellow:
                return ("\u{001B}[33m", "\u{001B}[0m")
            case .cyan:
                return ("\u{001B}[36m", "\u{001B}[0m")
            case .`default`:
                return ("\u{001B}[39m", "")
            }
        }()
        let styleCodes: (on: String, off: String) = {
            switch style {
            case .bold:
                return ("\u{001B}[1m", "\u{001B}[22m")
            case .default:
                return ("", "")
            }
        }()
        self.onCodes = [styleCodes.on, colorCodes.on]
        self.offCodes = [colorCodes.off, styleCodes.off]
    }

    func format(_ string: String) -> String {
        "\(onCodes.joined())\(string)\(offCodes.joined())"
    }

    func format<Value: CustomStringConvertible>(describing value: Value) -> String {
        format(String(describing: value))
    }

    func format<Value>(describing value: Value) -> String {
        format(String(describing: value))
    }
}

extension String {
    init<Value: CustomStringConvertible>(
        formatting value: Value,
        color: TextOutputColor = .default,
        style: TextOutputStyle = .default
    ) {
        self = TextOutputFormatter(
            color: color,
            style: style
        )
        .format(describing: value)
    }

    init<Value>(
        formatting value: Value,
        color: TextOutputColor = .default,
        style: TextOutputStyle = .default
    ) {
        self = TextOutputFormatter(
            color: color,
            style: style
        )
        .format(describing: value)
    }
}

extension DefaultStringInterpolation {
    /// Interpolates the textual representation of the given value with the given
    /// color and style into the string literal being created.
    mutating func appendInterpolation<Value: CustomStringConvertible>(
        _ value: Value,
        color: TextOutputColor,
        style: TextOutputStyle
    ) {
        appendInterpolation(
            String(formatting: value, color: color, style: style)
        )
    }

    /// Interpolates the textual representation of the given value with the given
    /// color into the string literal being created.
    mutating func appendInterpolation<Value: CustomStringConvertible>(
        _ value: Value,
        color: TextOutputColor
    ) {
        appendInterpolation(value, color: color, style: .default)
    }

    /// Interpolates the textual representation of the given value with the given
    /// style into the string literal being created.
    mutating func appendInterpolation<Value: CustomStringConvertible>(
        _ value: Value,
        style: TextOutputStyle
    ) {
        appendInterpolation(value, color: .default, style: style)
    }

    /// Interpolates the textual representation of the given value with the given
    /// color and style into the string literal being created.
    mutating func appendInterpolation<Value>(
        _ value: Value,
        color: TextOutputColor,
        style: TextOutputStyle
    ) {
        appendInterpolation(
            String(formatting: value, color: color, style: style)
        )
    }

    /// Interpolates the textual representation of the given value with the given
    /// color into the string literal being created.
    mutating func appendInterpolation<Value>(
        _ value: Value,
        color: TextOutputColor
    ) {
        appendInterpolation(value, color: color, style: .default)
    }

    /// Interpolates the textual representation of the given value with the given
    /// style into the string literal being created.
    mutating func appendInterpolation<Value>(
        _ value: Value,
        style: TextOutputStyle
    ) {
        appendInterpolation(value, color: .default, style: style)
    }
}
