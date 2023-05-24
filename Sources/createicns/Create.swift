//
// Create.swift
// createicns
//

import ArgumentParser
import Foundation
import Prism

@main
struct Create: ParsableCommand {

    // MARK: Static Properties

    static var configuration: CommandConfiguration = {
        var configuration = CommandConfiguration()
        configuration.commandName = "createicns"
        configuration.version = "0.0.4"
        return configuration
    }()

    // MARK: Arguments & Flags

    @Argument(help: .input)
    var input: String

    @Argument(help: .output)
    var output: String?

    @Flag(name: .iconset, help: .isIconset)
    var isIconset = false

    // MARK: Properties

    private lazy var correctExtension = isIconset ? "iconset" : "icns"

    private lazy var inputURL = URL(fileURLWithPath: input)

    private lazy var outputURL: URL = {
        guard let output else {
            return inputURL.replacingPathExtension(with: correctExtension)
        }
        return URL(fileURLWithPath: output)
    }()

    // MARK: Run

    mutating func run() throws {
        if isIconset {
            print("Creating iconset...")
        } else {
            print("Creating icon...")
        }

        do {
            try verifyInputAndOutput()
            let image = try getImage()
            let iconSet = try IconSet(image: image)
            try write(iconSet: iconSet)
        } catch {
            throw CreationError(error)
        }

        if isIconset {
            print("Iconset successfully created.".foregroundColor(.green))
        } else {
            print("Icon successfully created.".foregroundColor(.green))
        }
    }
}

// MARK: Instance Methods
extension Create {
    mutating func getImage() throws -> Image {
        let image = try Image(url: inputURL)
        guard image.width == image.height else {
            throw CreationError.invalidDimensions
        }
        return image
    }

    mutating func verifyInputAndOutput() throws {
        let inputVerifier = FileVerifier(path: input)
        if !inputVerifier.fileExists {
            throw CreationError.doesNotExist(inputVerifier)
        }
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
        if !outputVerifier.hasPathExtension(correctExtension) {
            throw CreationError.badOutputPathExtension(outputVerifier)
        }
    }

    mutating func write(iconSet: IconSet) throws {
        if isIconset {
            try iconSet.write(to: outputURL)
        } else {
            try IconUtil(iconSet: iconSet).run(writingTo: outputURL)
        }
    }
}
