//
// FileVerifier.swift
// createicns
//

import Foundation

/// A type that verifies files according to the conditions specified by a group of options.
struct FileVerifier {
    /// A type that specifies a verification to perform using information supplied by a
    /// file verifier.
    struct Option {
        /// An enumeration representing an option's underlying kind.
        fileprivate enum Kind {
            case fileExists
            case isDirectory
            case isFileType(FileType)
        }

        /// The underlying kind of the option.
        fileprivate let kind: Kind

        /// Whether to invert the verification specified by the option.
        fileprivate let isInverted: Bool

        /// Returns the inverse of this option.
        ///
        /// For an option that verifies that a given condition is `true`, its inverse is
        /// an option that verifies that the condition is `false`.
        ///
        /// For example, an option that verifies that a file exists inverts to an option
        /// that verifies that the file does _not_ exist. Likewise, an option that verifies
        /// that a file does not exist inverts to an option that verifies that the file
        /// _does_ exist.
        var inverted: Self {
            Self(kind: kind, isInverted: !isInverted)
        }

        /// Creates an option using the given underlying kind, and a Boolean value that
        /// indicates whether to invert the verification specified by the option.
        private init(kind: Kind, isInverted: Bool = false) {
            self.kind = kind
            self.isInverted = isInverted
        }

        /// An option that verifies that the file exists.
        static let fileExists = Self(kind: .fileExists)

        /// An option that verifies that the file is a directory.
        static let isDirectory = Self(kind: .isDirectory)

        /// An option that verifies that the file is of the given file type.
        static func isFileType(_ fileType: FileType) -> Self {
            Self(kind: .isFileType(fileType))
        }

        /// Returns the inverse of the given option.
        static prefix func ! (option: Self) -> Self {
            option.inverted
        }
    }

    /// An error that can be thrown during file verification.
    private enum VerificationError: FormattedError {
        case alreadyExists(String)
        case doesNotExist(String)
        case isDirectory(String)
        case isNotDirectory(String)
        case invalidPathExtension(String, FileType?)

        var message: FormattedText {
            switch self {
            case .alreadyExists(let path):
                return "'\(path, color: .yellow)' already exists"
            case .doesNotExist(let path):
                return "No such file or directory '\(path, color: .yellow)'"
            case .isDirectory(let path):
                return "'\(path, color: .yellow)' is a directory"
            case .isNotDirectory(let path):
                return "'\(path, color: .yellow)' is not a directory"
            case .invalidPathExtension(let pathExtension, let outputType):
                var result = FormattedText("Invalid path extension '\(pathExtension, color: .yellow, style: .bold)'")
                guard let outputType else {
                    return result
                }
                if let type = outputType.preferredFilenameExtension {
                    result.append(" for expected output type '\(type, color: .cyan, style: .bold)'")
                } else {
                    result.append(" for unknown output type")
                }
                return result
            }
        }
    }

    /// The options that specify the verifications to perform.
    let options: [Option]

    /// Verifies the given file information using the verifier's options.
    @discardableResult
    func verify(info: FileInfo) throws -> FileInfo {
        for option in options {
            switch option.kind {
            case .fileExists:
                if option.isInverted {
                    guard !info.fileExists else {
                        throw VerificationError.alreadyExists(info.path)
                    }
                } else {
                    guard info.fileExists else {
                        throw VerificationError.doesNotExist(info.path)
                    }
                }
            case .isDirectory:
                if option.isInverted {
                    guard !info.isDirectory else {
                        throw VerificationError.isDirectory(info.path)
                    }
                } else {
                    guard info.isDirectory else {
                        throw VerificationError.isNotDirectory(info.path)
                    }
                }
            case .isFileType(let fileType):
                let isFileType = FileType(url: info.url) == fileType
                if option.isInverted {
                    guard !isFileType else {
                        throw VerificationError.invalidPathExtension(info.pathExtension, nil)
                    }
                } else {
                    guard isFileType else {
                        throw VerificationError.invalidPathExtension(info.pathExtension, fileType)
                    }
                }
            }
        }
        return info
    }

    /// Creates a verifier that verifies files using the given options.
    init(options: [Option]) {
        self.options = options
    }
}
