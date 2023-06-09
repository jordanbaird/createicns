//
// FileInfo.swift
// createicns
//

import Foundation

private let pathSeparator = "/"

private func _joinPathComponents<S: StringProtocol>(_ components: [S]) -> String {
    components.joined(separator: pathSeparator)
}

@available(macOS 13.0, *)
private func _foundationHint(for directoryHint: FileInfo.DirectoryHint) -> URL.DirectoryHint {
    switch directoryHint {
    case .isDirectory:
        return .isDirectory
    case .notDirectory:
        return .notDirectory
    case .checkFileSystem:
        return .checkFileSystem
    case .inferFromPath:
        return .inferFromPath
    }
}

private func _pathIsDirectory<S: StringProtocol>(_ path: S, directoryHint: FileInfo.DirectoryHint) -> Bool {
    switch directoryHint {
    case .isDirectory:
        return true
    case .notDirectory:
        return false
    case .checkFileSystem:
        return FileInfo(path: String(path)).isDirectory
    case .inferFromPath:
        return FileInfo(path: String(path)).path.hasSuffix(pathSeparator)
    }
}

struct FileInfo {
    /// A representation of a file containing a standardized path string and url.
    private struct Representation {
        /// A url representing the file.
        let url: URL
        /// A standardized path string representing the file.
        let path: String

        /// Creates a representation by standardizing the given file url.
        private init(standardizing fileURL: URL) {
            let url = fileURL.standardizedFileURL
            self.url = url
            if #available(macOS 13.0, *) {
                self.path = url.path(percentEncoded: true)
            } else if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                self.path = components.percentEncodedPath
            } else {
                self.path = url.path
            }
        }

        /// Creates a representation from the given url.
        init(fileURL: URL) {
            self.init(standardizing: fileURL)
        }

        /// Creates a representation from a standardized version of the given path string.
        init(filePath: String) {
            if #available(macOS 13.0, *) {
                self.init(standardizing: URL(filePath: filePath))
            } else {
                self.init(standardizing: URL(fileURLWithPath: filePath))
            }
        }
    }

    enum DirectoryHint {
        /// Specifies that the file information does reference a directory.
        case isDirectory
        /// Specifies that the file information does not reference a directory.
        case notDirectory
        /// Specifies that the file information should check with the file system
        /// to determine whether it references a directory.
        case checkFileSystem
        /// Specifies that the file information should infer whether it references
        /// a directory based on whether it has a trailing dash.
        case inferFromPath
    }

    private let representation: Representation

    var url: URL { representation.url }

    var path: String { representation.path }

    var lastPathComponent: String { url.lastPathComponent }

    var pathExtension: String { url.pathExtension }

    var fileExists: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    var isDirectory: Bool {
        var b: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &b) && b.boolValue
    }

    init(url: URL) {
        self.representation = Representation(fileURL: url)
    }

    init(path: String) {
        self.representation = Representation(filePath: path)
    }

    func appending<S: StringProtocol>(component: S, directoryHint: DirectoryHint = .inferFromPath) -> Self {
        appending(components: component, directoryHint: directoryHint)
    }

    func appending<S: StringProtocol>(components: S..., directoryHint: DirectoryHint = .inferFromPath) -> Self {
        appending(path: _joinPathComponents(components), directoryHint: directoryHint)
    }

    func appending<S: StringProtocol>(path: S, directoryHint: DirectoryHint = .inferFromPath) -> Self {
        if #available(macOS 13.0, *) {
            return Self(url: url.appending(path: path, directoryHint: _foundationHint(for: directoryHint)))
        } else {
            let isDirectory = _pathIsDirectory(path, directoryHint: directoryHint)
            return Self(url: URL(fileURLWithPath: String(path), isDirectory: isDirectory, relativeTo: url))
        }
    }

    func appendingPathExtension(_ pathExtension: String) -> Self {
        Self(url: url.appendingPathExtension(pathExtension))
    }

    func appendingPathExtension(for fileType: FileType) -> Self {
        if let current = FileType(pathExtension: url.pathExtension) {
            guard current != fileType else {
                return self
            }
        }
        if let pathExtension = fileType.preferredFilenameExtension {
            return appendingPathExtension(pathExtension)
        }
        return self
    }

    func deletingPathExtension() -> Self {
        Self(url: url.deletingPathExtension())
    }

    func withPathExtension(_ pathExtension: String) -> Self {
        deletingPathExtension().appendingPathExtension(pathExtension)
    }

    func withPathExtension(for fileType: FileType) -> Self {
        deletingPathExtension().appendingPathExtension(for: fileType)
    }
}
