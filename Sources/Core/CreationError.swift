//
// CreationError.swift
// createicns
//

import Foundation
import Prism

// FIXME: Really, this entire thing just needs to be redone.
public struct CreationError: LocalizedError {
    private enum Base {
        case message(String)
        case error(Error)
    }

    private let base: Base

    public var message: String {
        switch base {
        case .message(let message):
            return message
        case .error(let error):
            return error.localizedDescription
        }
    }

    public var errorDescription: String? {
        message
    }

    private init(base: Base) {
        self.base = base
    }

    public init(_ message: String) {
        self.init(base: .message(message))
    }

    public init<E: Error>(_ error: E) {
        if let error = error as? Self {
            self = error
        } else {
            self.init(base: .error(error))
        }
    }

    public init(_ data: Data) {
        guard let message = String(data: data, encoding: .utf8) else {
            self = .unknownError
            return
        }
        self.init(message)
    }
}

extension CreationError {
    public static let unknownError = Self("An unknown error occurred.")

    public static let invalidImageFormat = Self("File is not a valid image format.")

    public static let invalidDimensions = Self("Image width and height must be equal.")

    public static let invalidData = Self("Could not create data for iconset.")

    public static let invalidDestination = Self("Invalid image destination.")

    public static let resizeFailure = Self("Couldn't resize image.")
}

extension CreationError {
    public static func alreadyExists(_ verifier: FileVerifier) -> Self {
        Self("File at path '\(verifier.path)' already exists.")
    }

    public static func doesNotExist(_ verifier: FileVerifier) -> Self {
        Self("File does not exist at path '\(verifier.path)'.")
    }

    public static func directoryDoesNotExist(_ verifier: FileVerifier) -> Self {
        Self("Directory does not exist at path '\(verifier.path)'.")
    }

    public static func badInput(_ verifier: FileVerifier) -> Self {
        if verifier.isDirectory {
            return Self("Input path cannot be a directory: '\(verifier.path)'")
        }
        return Self("Invalid input path '\(verifier.path)'.")
    }

    public static func badOutput(_ verifier: FileVerifier) -> Self {
        if verifier.isDirectory {
            return Self("Output path cannot be a directory: '\(verifier.path)'.")
        }
        return Self("Invalid output path '\(verifier.path)'.")
    }

    public static func badOutputPathExtension(_ verifier: FileVerifier) -> Self {
        Self("Output path extension must be '.\(verifier.url.pathExtension)'.")
    }
}
