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

private extension TextOutputColor {
    var onCode: String {
        switch self {
        case .red:
            return "\u{001B}[31m"
        case .green:
            return "\u{001B}[32m"
        case .yellow:
            return "\u{001B}[33m"
        case .cyan:
            return "\u{001B}[36m"
        case .`default`:
            return "\u{001B}[39m"
        }
    }

    var offCode: String {
        switch self {
        case .red, .green, .yellow, .cyan:
            return "\u{001B}[0m"
        case .`default`:
            return ""
        }
    }
}

private extension TextOutputStyle {
    var onCode: String {
        switch self {
        case .bold:
            return "\u{001B}[1m"
        case .default:
            return ""
        }
    }

    var offCode: String {
        switch self {
        case .bold:
            return "\u{001B}[22m"
        case .default:
            return ""
        }
    }
}

extension String {
    private init(string: String, color: TextOutputColor, style: TextOutputStyle) {
        self = [
            style.onCode,
            color.onCode,
            string,
            color.offCode,
            style.offCode,
        ].joined()
    }

    init<Value: CustomStringConvertible>(
        formatting value: Value,
        color: TextOutputColor = .default,
        style: TextOutputStyle = .default
    ) {
        self.init(string: String(describing: value), color: color, style: style)
    }

    init<Value>(
        formatting value: Value,
        color: TextOutputColor = .default,
        style: TextOutputStyle = .default
    ) {
        self.init(string: String(describing: value), color: color, style: style)
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
