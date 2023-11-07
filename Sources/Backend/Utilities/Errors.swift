//
//  Errors.swift
//  createicns
//

import Foundation

// MARK: - FormattedError

/// An error type that is displayed in a formatted representation when printed
/// to a command line interface.
public protocol FormattedError: Error, TextOutputStreamable {
    /// The formatted error message to display.
    ///
    /// If one of either standard output or standard error does not point to 
    /// a terminal, the message is displayed without formatting.
    var errorMessage: FormattedText { get }

    /// An optional formatted message to display that describes how the user
    /// can remedy this error.
    ///
    /// If one of either standard output or standard error does not point to
    /// a terminal, the message is displayed without formatting.
    var fix: FormattedText? { get }
}

extension FormattedError {
    public var fix: FormattedText? { nil }
}

extension FormattedError {
    public func write<Target: TextOutputStream>(to target: inout Target) {
        errorMessage.write(to: &target)
    }
}

// MARK: - FormattedErrorBox

/// A formatted error type that wraps another error.
struct FormattedErrorBox: FormattedError {
    let error: any Error

    var errorMessage: FormattedText {
        if let error = error as? FormattedError {
            return error.errorMessage
        }
        return FormattedText(contentsOf: error.localizedDescription)
    }

    var fix: FormattedText? {
        if let error = error as? FormattedError {
            return error.fix
        }
        return nil
    }
}

// MARK: - ContextualDataError

/// An error that contains its information in the form of a data object, along
/// with the context in which the error occurred.
struct ContextualDataError: FormattedError {
    /// A data object containing the information in the error.
    let data: Data

    /// A string describing the context in which this error occurred.
    let context: String

    var errorMessage: FormattedText {
        var message = FormattedText(context + ":", color: .yellow, style: .bold)
        if let string = String(data: data, encoding: .utf8) {
            message.append(" \("An error occurred with the following data:", color: .red) \(string)")
        } else {
            message.append(" An unknown error occurred")
        }
        return message
    }

    /// Creates an error with the given data and context.
    init(_ data: Data, context: String) {
        self.data = data
        self.context = context
    }

    /// Creates an error with the given data and context.
    init<Context>(_ data: Data, context: Context.Type) {
        self.init(data, context: String(describing: context))
    }
}

// MARK: - FileVerificationError

/// An error that can be thrown during file verification.
enum FileVerificationError: FormattedError {
    case alreadyExists(String)
    case doesNotExist(String)
    case isDirectory(String)
    case isNotDirectory(String)
    case invalidPathExtension(String, FileType?)

    var errorMessage: FormattedText {
        switch self {
        case .alreadyExists(let path):
            return "'\(path, color: .yellow)' already exists"
        case .doesNotExist(let path):
            return "No such file or directory '\(path, color: .yellow)'"
        case .isDirectory(let path):
            return "'\(path, color: .yellow)' is a directory"
        case .isNotDirectory(let path):
            return "'\(path, color: .yellow)' is not a directory"
        case .invalidPathExtension(let pathExtension, let outputType):
            let start: FormattedText = "Invalid path extension '\(pathExtension, color: .yellow, style: .bold)'"
            guard let outputType else {
                return start
            }
            if let type = outputType.preferredFilenameExtension {
                return start + " for expected output type '\(type, color: .cyan, style: .bold)'"
            }
            return start + " for unknown output type"
        }
    }

    var fix: FormattedText? {
        if case .invalidPathExtension(_, let outputType) = self {
            if let type = outputType?.preferredFilenameExtension {
                return "Use path extension '\(type, color: .green, style: .bold)'"
            }
        }
        return nil
    }
}
