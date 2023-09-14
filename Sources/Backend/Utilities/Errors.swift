//
//  Errors.swift
//  createicns
//

import Foundation

// MARK: FormattedError

/// An error type that is displayed in a formatted representation when printed
/// to a command line interface.
public protocol FormattedError: Error, TextOutputStreamable {
    /// The formatted message to display.
    ///
    /// If one of either standard output or standard error does not point to a
    /// terminal, the message is displayed without formatting.
    var message: FormattedText { get }
}

extension FormattedError {
    public func write<Target: TextOutputStream>(to target: inout Target) {
        message.write(to: &target)
    }
}

// MARK: ContextualDataError

/// An error that contains its information in the form of a data object, along
/// with the context in which the error occurred.
struct ContextualDataError: FormattedError {
    /// A data object containing the information in the error.
    let data: Data

    /// A string describing the context in which this error occurred.
    let context: String

    var message: FormattedText {
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
