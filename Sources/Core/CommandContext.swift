//
// CommandContext.swift
// createicns
//

import Foundation
import Prism

/// A context that manages the execution and output of the command.
public final class CommandContext {
    /// An error that may be thrown during the operations of a ``CommandContext``.
    struct RunError: LocalizedError {
        /// The underlying error.
        let error: Error

        /// Creates a runner error with an underlying error.
        init(error: Error) {
            self.error = error
        }

        /// A description of the underlying error, printed in red.
        var errorDescription: String? {
            error.localizedDescription.foregroundColor(.red)
        }
    }

    /// The correct file type to use for the user's chosen output type.
    let correctFileType: UTType

    /// The url that is used to create the iconset.
    let inputURL: URL

    /// The future location of the created iconset.
    let outputURL: URL

    /// A message to print before the context begins verification.
    let actionMessage: String

    /// A message to print after a successful run of the context.
    let successMessage: String

    /// An object that writes an iconset to the context's output.
    let iconSetWriter: IconSetWriter

    /// Creates a command context with the given input path, output path, and
    /// Boolean value indicating whether the output type should be an iconset.
    public init(input: String, output: String?, isIconSet: Bool) {
        let correctFileType: UTType
        let actionMessage: String
        let successMessage: String
        let iconSetWriter: IconSetWriter

        if isIconSet {
            correctFileType = .iconSet
            actionMessage = "Creating iconset..."
            successMessage = "Iconset successfully created."
            iconSetWriter = .direct
        } else {
            correctFileType = .icns
            actionMessage = "Creating icon..."
            successMessage = "Icon successfully created."
            iconSetWriter = .iconUtil
        }

        let inputURL = URL(fileURLWithPath: input)
        let outputURL: URL = {
            guard let output else {
                let inputDeletingExtension = inputURL.deletingPathExtension()
                if let correctExtension = correctFileType.preferredFilenameExtension {
                    return inputDeletingExtension.appendingPathExtension(correctExtension)
                }
                return inputDeletingExtension
            }
            return URL(fileURLWithPath: output)
        }()

        self.correctFileType = correctFileType
        self.inputURL = inputURL
        self.outputURL = outputURL
        self.actionMessage = actionMessage
        self.successMessage = successMessage
        self.iconSetWriter = iconSetWriter
    }

    /// Ensures that the input and output urls of the context are valid, throwing
    /// the appropriate error if not.
    private func verifyInputAndOutput() throws {
        let inputVerifier = FileVerifier(url: inputURL)
        try inputVerifier.verifyFileExists()
        if inputVerifier.isDirectory {
            throw CreationError.badInput(inputVerifier)
        }

        let outputVerifier = FileVerifier(url: outputURL)
        if outputVerifier.fileExists {
            throw CreationError.alreadyExists(outputVerifier)
        }
        if outputVerifier.isDirectory {
            throw CreationError.badOutput(outputVerifier)
        }
        try outputVerifier.verifyIsFileType(correctFileType)
    }

    /// Creates an iconset from the context's input url, and writes the resulting
    /// images to the context's output url.
    private func write() throws {
        let image = try Image(url: inputURL)
        let iconSet = IconSet(image: image)
        try iconSetWriter.write(iconSet: iconSet, outputURL: outputURL)
    }

    /// Executes the given closure, intercepting any thrown error and wrapping it
    /// in a `RunError`, which will be printed to stderr in red.
    private func runInterceptingError<T>(_ body: () throws -> T) rethrows -> T {
        do {
            return try body()
        } catch {
            throw RunError(error: error)
        }
    }

    /// Prints the context's action message, then ensures the context's input and
    /// output are both valid before creating an iconset from the context's input
    /// url and writing the resulting images to the context's output url.
    public func run() throws {
        try runInterceptingError {
            print(actionMessage)
            try verifyInputAndOutput()
            try write()
            print(successMessage.foregroundColor(.green))
        }
    }
}
