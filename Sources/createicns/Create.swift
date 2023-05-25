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
        let write: (inout Self, IconSet) throws -> Void

        if isIconset {
            print("Creating iconset...")
            write = { cmd, iconSet in
                try iconSet.write(to: cmd.outputURL)
                print("Iconset successfully created.".foregroundColor(.green))
            }
        } else {
            print("Creating icon...")
            write = { cmd, iconSet in
                try IconUtil(iconSet: iconSet).run(writingTo: cmd.outputURL)
                print("Icon successfully created.".foregroundColor(.green))
            }
        }

        do {
            try verifyInputAndOutput()
            let iconSet = try IconSet(image: Image(url: inputURL))
            try write(&self, iconSet)
        } catch {
            throw CreationError(error)
        }
    }
}

// MARK: Instance Methods
extension Create {
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
}
