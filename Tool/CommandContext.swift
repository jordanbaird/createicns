//
// CommandContext.swift
// createicns
//

import Core
import Foundation

struct CommandContext {
    /// The runner that manages the output of the context.
    let runner: Runner

    /// The correct extension to use for the user's chosen output type.
    let correctExtension: String

    /// The url that is used to create the iconset.
    let inputURL: URL

    /// The future location of the created iconset.
    let outputURL: URL

    /// A message to print before the context begins verification.
    var actionMessage: String?

    /// A message to print after a successful run of the context.
    var successMessage: String?

    /// An object that writes an iconset to the context's output.
    var iconSetWriter = IconSetWriter.direct

    /// Creates a command context with the given input path, output path,
    /// and Boolean value indicating whether the output type should be an
    /// iconset.
    init(runner: Runner, input: String, output: String?, isIconset: Bool) {
        let correctExtension = isIconset ? "iconset" : "icns"
        let inputURL = URL(fileURLWithPath: input)
        let outputURL: URL = {
            guard let output else {
                return inputURL.deletingPathExtension().appendingPathExtension(correctExtension)
            }
            return URL(fileURLWithPath: output)
        }()
        self.runner = runner
        self.correctExtension = correctExtension
        self.inputURL = inputURL
        self.outputURL = outputURL
    }

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
        try outputVerifier.verifyHasPathExtension(correctExtension)
    }

    /// Creates an iconset from the context's input url, and writes the resulting
    /// images to the context's output url.
    private func write() throws {
        let image = try Image(url: inputURL)
        let iconSet = IconSet(image: image)
        try iconSetWriter.write(iconSet: iconSet, outputURL: outputURL)
    }

    /// Prints the context's action message, then ensures the context's input and
    /// output are both valid before creating an iconset from the context's input
    /// url and writing the resulting images to the context's output url.
    func run() throws {
        if let actionMessage {
            runner.print(actionMessage)
        }
        try verifyInputAndOutput()
        try write()
        if let successMessage {
            runner.print(successMessage, color: .green)
        }
    }
}
