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
    enum VerificationError: FormattedError {
        case fileAlreadyExists(String)
        case fileDoesNotExist(String)
        case directoryDoesNotExist(String)
        case invalidInputPath(String, Bool)
        case invalidOutputPath(String, Bool)
        case invalidPathExtension(String, UTType)

        var components: [any FormattingComponent] {
            switch self {
            case .fileAlreadyExists(let path):
                return [
                    StripFormatting(components: [
                        Passthrough("File at path '"),
                        Red(path),
                        Passthrough("' already exists"),
                    ]),
                ]
            case .fileDoesNotExist(let path):
                return [
                    StripFormatting(components: [
                        Passthrough("File does not exist at path '"),
                        Red(path),
                        Passthrough("'"),
                    ]),
                ]
            case .directoryDoesNotExist(let path):
                return [
                    StripFormatting(components: [
                        Passthrough("Directory does not exist at path '"),
                        Red(path),
                        Passthrough("'"),
                    ])
                ]
            case .invalidInputPath(let path, let isDirectory):
                if isDirectory {
                    return [
                        Passthrough("Input path"),
                        StripFormatting([" '", path, "' "]),
                        Passthrough("cannot be a directory."),
                    ]
                }
                return [
                    Passthrough("Invalid input path "),
                    StripFormatting(["'", path, "'"]),
                ]
            case .invalidOutputPath(let path, let isDirectory):
                if isDirectory {
                    return [
                        Passthrough("Output path"),
                        StripFormatting([" '", path, "' "]),
                        Passthrough("cannot be a directory."),
                    ]
                }
                return [
                    Passthrough("Invalid output path "),
                    StripFormatting(["'", path, "'"]),
                ]
            case .invalidPathExtension(let pathExtension, let outputType):
                var components: [any FormattingComponent] = [
                    StripFormatting(components: [
                        Passthrough("Invalid path extension '"),
                        Red(Bold(pathExtension)),
                        Passthrough("' "),
                    ]),
                ]
                if let type = outputType.preferredFilenameExtension {
                    components.append(StripFormatting(components: [
                        Passthrough("for expected output type '"),
                        Cyan(Bold(type)),
                        Passthrough("'"),
                    ]))
                } else {
                    components.append(StripFormatting("for unknown output type."))
                }
                return components
            }
        }
    }
}
