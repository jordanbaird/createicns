//
// CommandContext.swift
// createicns
//

import Foundation

/// A context that manages the execution and output of the command.
public struct CommandContext {
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
    public init(input: String, output: String?, isIconSet: Bool) throws {
        let fileType: UTType
        let actionMessage: String
        let successMessage: String
        let iconSetWriter: IconSetWriter

        if isIconSet {
            fileType = .iconSet
            actionMessage = "Creating iconset..."
            successMessage = "Iconset successfully created."
            iconSetWriter = .direct
        } else {
            fileType = .icns
            actionMessage = "Creating icon..."
            successMessage = "Icon successfully created."
            iconSetWriter = .iconUtil
        }

        let inputURL = URL(fileURLWithPath: input)
        let outputURL: URL = {
            guard let output else {
                let inputDeletingExtension = inputURL.deletingPathExtension()
                if let pathExtension = fileType.preferredFilenameExtension {
                    return inputDeletingExtension.appendingPathExtension(pathExtension)
                }
                return inputDeletingExtension
            }
            return URL(fileURLWithPath: output)
        }()

        self.inputURL = try FileVerifier(options: [.fileExists, !.isDirectory])
            .verify(url: inputURL)
        self.outputURL = try FileVerifier(options: [!.fileExists, !.isDirectory, .isFileType(fileType)])
            .verify(url: outputURL)
        self.actionMessage = actionMessage
        self.successMessage = successMessage
        self.iconSetWriter = iconSetWriter
    }

    /// Ensures the context's input and output are both valid before creating an
    /// iconset from the context's input url and writing the resulting images to
    /// the context's output url.
    public func run() throws {
        print(actionMessage)
        let image = try Image(url: inputURL)
        let iconSet = IconSet(image: image)
        try iconSetWriter.write(iconSet: iconSet, outputURL: outputURL)
        print(FormattedText(successMessage, color: .green))
    }
}
