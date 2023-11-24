//
//  Formatting.swift
//  createicns
//

// MARK: - TextOutputColor

/// Colors to use to format text when displayed in a terminal.
public enum TextOutputColor: Hashable {
    case red
    case green
    case yellow
    case cyan
    case `default`

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
        case .default:
            return "\u{001B}[39m"
        }
    }

    var offCode: String {
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
public enum TextOutputStyle: Hashable {
    case bold
    case `default`

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
