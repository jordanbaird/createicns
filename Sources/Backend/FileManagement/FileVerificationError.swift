//
//  FileVerificationError.swift
//  createicns
//

/// An error that can be thrown during file verification.
enum FileVerificationError: FormattedError {
    case alreadyExists(String)
    case doesNotExist(String)
    case isDirectory(String)
    case isNotDirectory(String)
    case invalidPathExtension(String, FileType?)

    var errorMessage: FormattedText {
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
            let start: FormattedText = "Invalid path extension '\(pathExtension, color: .yellow, style: .bold)'"
            guard let outputType else {
                return start
            }
            if let type = outputType.preferredFilenameExtension {
                return start + " for expected output type '\(type, color: .cyan, style: .bold)'"
            }
            return start + " for unknown output type"
        }
    }

    var fix: FormattedText? {
        if case .invalidPathExtension(_, let outputType) = self {
            if let type = outputType?.preferredFilenameExtension {
                return "Use path extension '\(type, color: .green, style: .bold)'"
            }
        }
        return nil
    }
}
