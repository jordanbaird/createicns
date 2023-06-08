//
// Create.swift
// createicns
//

import Foundation

/// A runner that manages the creation and output of icns and iconset files.
struct Create: Runner {
    /// The url that is used to create the iconset.
    let inputURL: URL

    /// The future location of the created iconset.
    let outputURL: URL

    /// A message to print before the runner begins verification.
    let actionMessage: String

    /// A message to print after a successful run.
    let successMessage: String

    /// An object that writes an iconset to the runner's output.
    let writer: IconSetWriter

    /// Creates a runner with the given input path, output path, and a Boolean
    /// value indicating whether the output type should be an iconset.
    init(input: String, output: String?, isIconSet: Bool) throws {
        let fileType: FileType
        let actionMessage: String
        let successMessage: String
        let writer: IconSetWriter

        if isIconSet {
            fileType = .iconSet
            actionMessage = "Creating iconset..."
            successMessage = "Iconset successfully created."
            writer = .direct
        } else {
            fileType = .icns
            actionMessage = "Creating icon..."
            successMessage = "Icon successfully created."
            writer = .iconUtil
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
        self.writer = writer
    }

    func run() throws {
        print(actionMessage)
        let image = try Image(url: inputURL)
        let iconSet = IconSet(image: image)
        try writer.write(iconSet, to: outputURL)
        print(FormattedText(successMessage, color: .green))
    }
}
