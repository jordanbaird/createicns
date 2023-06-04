//
// FileVerifier.swift
// createicns
//

import Foundation

struct FileVerifier {
    struct Options: OptionSet {
        let rawValue: UInt

        static let fileExists       = Options(rawValue: 1 << 0)
        static let isDirectory      = Options(rawValue: 1 << 1)
        static let isFileType       = Options(rawValue: 1 << 2)
        static let fileDoesNotExist = Options(rawValue: 1 << 3)
        static let isNotDirectory   = Options(rawValue: 1 << 4)
        static let isNotFileType    = Options(rawValue: 1 << 5)
    }

    private let path: String
    private let url: URL
    private let fileType: UTType?

    func verify(with options: Options) throws {
        lazy var _isDirectory: ObjCBool = false

        lazy var fileExists = FileManager.default.fileExists(atPath: path, isDirectory: &_isDirectory)

        lazy var isFileType = UTType(url: url) == fileType

        var isDirectory: Bool {
            _ = fileExists // make sure _isDirectory gets set
            return _isDirectory.boolValue
        }

        if options.contains(.fileExists) {
            if !fileExists {
                throw VerificationError.fileDoesNotExist(path)
            }
        }
        if options.contains(.isDirectory) {
            if !isDirectory {
                throw VerificationError.invalidPath(path, false)
            }
        }
        if options.contains(.isFileType) {
            if !isFileType {
                throw VerificationError.invalidPathExtension(url.pathExtension, fileType)
            }
        }
        if options.contains(.fileDoesNotExist) {
            if fileExists {
                throw VerificationError.fileAlreadyExists(path)
            }
        }
        if options.contains(.isNotDirectory) {
            if isDirectory {
                throw VerificationError.invalidPath(path, true)
            }
        }
        if options.contains(.isNotFileType) {
            if isFileType {
                if
                    let pathExtension = fileType?.preferredFilenameExtension,
                    let fileType = UTType(url: url)
                {
                    throw VerificationError.invalidPathExtension(pathExtension, fileType)
                } else {
                    throw VerificationError.invalidPath(path, false)
                }
            }
        }
    }

    func path(verifying options: Options) throws -> String {
        try verify(with: options)
        return path
    }

    func url(verifying options: Options) throws -> URL {
        try verify(with: options)
        return url
    }

    init(path: String, fileType: UTType? = nil) {
        self.path = path
        self.url = URL(fileURLWithPath: path)
        self.fileType = fileType
    }

    init(url: URL, fileType: UTType? = nil) {
        self.path = url.path
        self.url = url
        self.fileType = fileType
    }
}

// MARK: VerificationError
extension FileVerifier {
    private enum VerificationError: FormattedError {
        case fileAlreadyExists(String)
        case fileDoesNotExist(String)
        case invalidPath(String, Bool)
        case invalidPathExtension(String, UTType?)

        var message: FormattedText {
            switch self {
            case .fileAlreadyExists(let path):
                return "File '\(path, color: .yellow)' already exists"
            case .fileDoesNotExist(let path):
                return "Didn't find valid file at path '\(path, color: .yellow)'"
            case .invalidPath(let path, let isDirectory):
                if isDirectory {
                    return "Path '\(path, color: .yellow)' is a directory"
                }
                return "Invalid path '\(path, color: .yellow)'"
            case .invalidPathExtension(let pathExtension, let outputType):
                var result = FormattedText("Invalid path extension '\(pathExtension, color: .yellow, style: .bold)' ")
                if let type = outputType?.preferredFilenameExtension {
                    result.append("for expected output type '\(type, color: .cyan, style: .bold)'")
                } else {
                    result.append("for unknown output type")
                }
                return result
            }
        }
    }
}
