//
// CommandContext.swift
// createicns
//

import Foundation

/// A context that manages the execution and output of the command.
public final class CommandContext {
    /// An error that may be thrown during the operations of a ``CommandContext``.
    struct RunError: FormattedError {
        /// The underlying error.
        let error: Error

        /// Creates a runner error with an underlying error.
        init(error: Error) {
            self.error = error
        }

        var components: [any FormattingComponent] {
            if let error = error as? FormattedError {
                return [Red(components: error.components)]
            }
            return [Red(error.localizedDescription)]
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
        let outputVerifier = FileVerifier(url: outputURL)

        if !inputVerifier.fileExists {
            throw inputVerifier.fileDoesNotExistError()
        }
        if outputVerifier.fileExists {
            throw outputVerifier.fileAlreadyExistsError()
        }
        if inputVerifier.isDirectory {
            throw inputVerifier.invalidInputPathError()
        }
        if outputVerifier.isDirectory {
            throw outputVerifier.invalidOutputPathError()
        }

        if !outputVerifier.isFileType(correctFileType) {
            throw outputVerifier.invalidPathExtensionError(for: correctFileType)
        }
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
            print(Green(successMessage).format())
        }
    }
}
