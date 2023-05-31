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

    var fileType: UTType? {
        UTType(url: url)
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
        self.fileType == fileType
    }

    func verifyFileExists() throws {
        if !fileExists {
            throw VerificationError.fileDoesNotExist(path)
        }
    }

    func verifyIsFileType(_ fileType: UTType) throws {
        if !isFileType(fileType) {
            throw VerificationError.incorrectPathExtension(url.pathExtension, fileType)
        }
    }
}

extension FileVerifier {
    enum VerificationError: LocalizedError {
        case fileDoesNotExist(String)
        case incorrectPathExtension(String, UTType)

        var errorDescription: String? {
            switch self {
            case .fileDoesNotExist(let path):
                return "File does not exist at path '\(path)'."
            case .incorrectPathExtension(let pathExtension, let outputType):
                let start = "Incorrect path extension '\(pathExtension)' "
                if let type = outputType.preferredFilenameExtension {
                    return start + "for expected output type '\(type)'."
                }
                return start + "for unknown output type."
            }
        }
    }
}
