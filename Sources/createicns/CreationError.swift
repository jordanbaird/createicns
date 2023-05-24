//
// CreationError.swift
// createicns
//

import Foundation
import Prism

// FIXME: Really, this entire thing just needs to be redone.
struct CreationError: LocalizedError {
    private enum Base {
        case message(String)
        case error(Error)
    }

    private let base: Base

    var message: String {
        switch base {
        case .message(let message):
            return message
        case .error(let error):
            return error.localizedDescription
        }
    }

    var errorDescription: String? {
        message.foregroundColor(.red)
    }

    private init(base: Base) {
        self.base = base
    }

    init(_ message: String) {
        self.init(base: .message(message))
    }

    init<E: Error>(_ error: E) {
        if let error = error as? Self {
            self = error
        } else {
            self.init(base: .error(error))
        }
    }

    init(_ data: Data) {
        guard let message = String(data: data, encoding: .utf8) else {
            self = .unknownError
            return
        }
        self.init(message)
    }
}

extension CreationError {
    static let unknownError = Self("An unknown error occurred.")

    static let invalidImageFormat = Self("File is not a valid image format.")

    static let invalidDimensions = Self("Image width and height must be equal.")

    static let invalidData = Self("Could not create data for iconset.")

    static let invalidDestination = Self("Invalid image destination.")

    static let resizeFailure = Self("Couldn't resize image.")
}

extension CreationError {
    static func alreadyExists(_ verifier: FileVerifier) -> Self {
        Self("File at path '\(verifier.path)' already exists.")
    }

    static func doesNotExist(_ verifier: FileVerifier) -> Self {
        Self("File does not exist at path '\(verifier.path)'.")
    }

    static func directoryDoesNotExist(_ verifier: FileVerifier) -> Self {
        Self("Directory does not exist at path '\(verifier.path)'.")
    }

    static func badInput(_ verifier: FileVerifier) -> Self {
        if verifier.isDirectory {
            return Self("Input path cannot be a directory: '\(verifier.path)'")
        }
        return Self("Invalid input path '\(verifier.path)'.")
    }

    static func badOutput(_ verifier: FileVerifier) -> Self {
        if verifier.isDirectory {
            return Self("Output path cannot be a directory: '\(verifier.path)'.")
        }
        return Self("Invalid output path '\(verifier.path)'.")
    }

    static func badOutputPathExtension(_ verifier: FileVerifier) -> Self {
        Self("Output path extension must be '.\(verifier.url.pathExtension)'.")
    }
}
