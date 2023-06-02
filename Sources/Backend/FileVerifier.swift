//
// FileVerifier.swift
// createicns
//

import Foundation

struct FileVerifier {
    private enum FileBase {
        case path(String)
        case url(URL)
    }

    struct VerifiedResult {
        let fileExists: Bool
        let isDirectory: Bool

        fileprivate init(path: String) {
            var isDirectory: ObjCBool = false
            self.fileExists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            self.isDirectory = isDirectory.boolValue
        }
    }

    private let base: FileBase

    var path: String {
        switch base {
        case .path(let path):
            return path
        case .url(let url):
            guard #available(macOS 13.0, *) else {
                return url.path
            }
            return url.path(percentEncoded: true)
        }
    }

    var url: URL {
        switch base {
        case .path(let path):
            guard #available(macOS 13.0, *) else {
                return URL(fileURLWithPath: path)
            }
            return URL(filePath: path)
        case .url(let url):
            return url
        }
    }

    var result: VerifiedResult {
        return VerifiedResult(path: path)
    }

    var fileExists: Bool {
        result.fileExists
    }

    var isDirectory: Bool {
        result.isDirectory
    }

    private init(base: FileBase) {
        self.base = base
    }

    init(path: String) {
        self.init(base: .path(path))
    }

    init(url: URL) {
        self.init(base: .url(url))
    }

    func isFileType(_ fileType: UTType) -> Bool {
        UTType(url: url) == fileType
    }

    // MARK: Errors

    func fileAlreadyExistsError() -> some Error {
        VerificationError.fileAlreadyExists(path)
    }

    func fileDoesNotExistError() -> some Error {
        VerificationError.fileDoesNotExist(path)
    }

    func directoryDoesNotExistError() -> some Error {
        VerificationError.directoryDoesNotExist(path)
    }

    func invalidInputPathError() -> some Error {
        VerificationError.invalidInputPath(path, isDirectory)
    }

    func invalidOutputPathError() -> some Error {
        VerificationError.invalidOutputPath(path, isDirectory)
    }

    func invalidPathExtensionError(for fileType: UTType) -> some Error {
        VerificationError.invalidPathExtension(url.pathExtension, fileType)
    }
}

// MARK: VerificationError
extension FileVerifier {
    enum VerificationError: LocalizedError {
        case fileAlreadyExists(String)
        case fileDoesNotExist(String)
        case directoryDoesNotExist(String)
        case invalidInputPath(String, Bool)
        case invalidOutputPath(String, Bool)
        case invalidPathExtension(String, UTType)

        var errorDescription: String? {
            switch self {
            case .fileAlreadyExists(let path):
                return "File '\(path, color: .yellow)' already exists"
            case .fileDoesNotExist(let path):
                return "Didn't find valid file at path '\(path, color: .yellow)'"
            case .directoryDoesNotExist(let path):
                return "Didn't find valid directory at path '\(path, color: .yellow)'"
            case .invalidInputPath(let path, let isDirectory):
                if isDirectory {
                    return "Input path '\(path, color: .yellow)' is a directory"
                }
                return "Invalid input path '\(path, color: .yellow)'"
            case .invalidOutputPath(let path, let isDirectory):
                if isDirectory {
                    return "Output path '\(path, color: .yellow)' is a directory"
                }
                return "Invalid output path '\(path, color: .yellow)'"
            case .invalidPathExtension(let pathExtension, let outputType):
                var result = "Invalid path extension '\(pathExtension, color: .yellow, style: .bold)' "
                if let type = outputType.preferredFilenameExtension {
                    result.append("for expected output type '\(type, color: .cyan, style: .bold)'")
                } else {
                    result.append("for unknown output type")
                }
                return result
            }
        }
    }
}
