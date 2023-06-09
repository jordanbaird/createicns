//
// FileInfo.swift
// createicns
//

import Foundation

private let pathSeparator = "/"

private extension Sequence where Element: StringProtocol {
    func joinedAsPath() -> String {
        joined(separator: pathSeparator)
    }
}

@available(macOS 13.0, *)
private extension URL.DirectoryHint {
    static func fileInfoDirectoryHint(_ directoryHint: FileInfo.DirectoryHint) -> Self {
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
}

/// A representation of a file containing a standardized path string and url.
private struct FileRepresentation {
    /// A standardized url representing the file.
    let url: URL

    /// A standardized path string representing the file.
    var path: String {
        guard #available(macOS 13.0, *) else {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                return components.percentEncodedPath
            }
            return url.path
        }
        return url.path(percentEncoded: true)
    }

    /// Creates a representation by standardizing the given file url.
    private init(standardizing fileURL: URL) {
        self.url = fileURL.standardizedFileURL
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

    func isDirectory(directoryHint: FileInfo.DirectoryHint) -> Bool {
        switch directoryHint {
        case .isDirectory:
            return true
        case .notDirectory:
            return false
        case .checkFileSystem:
            var b: ObjCBool = false
            return FileManager.default.fileExists(atPath: path, isDirectory: &b) && b.boolValue
        case .inferFromPath:
            return path.hasSuffix(pathSeparator)
        }
    }
}

struct FileInfo {
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

    private let representation: FileRepresentation

    var url: URL { representation.url }

    var path: String { representation.path }

    var lastPathComponent: String { url.lastPathComponent }

    var pathExtension: String { url.pathExtension }

    var fileExists: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    var isDirectory: Bool {
        representation.isDirectory(directoryHint: .checkFileSystem)
    }

    init(url: URL) {
        self.representation = FileRepresentation(fileURL: url)
    }

    init(
        path: String,
        directoryHint: DirectoryHint = .inferFromPath,
        relativeTo base: Self? = nil
    ) {
        if #available(macOS 13.0, *) {
            self.init(
                url: URL(
                    filePath: path,
                    directoryHint: .fileInfoDirectoryHint(directoryHint),
                    relativeTo: base?.url
                )
            )
        } else {
            self.init(
                url: URL(
                    fileURLWithPath: path,
                    isDirectory: FileRepresentation(filePath: path).isDirectory(directoryHint: directoryHint),
                    relativeTo: base?.url
                )
            )
        }
    }

    func appending<S: StringProtocol>(
        path: S,
        directoryHint: DirectoryHint = .inferFromPath
    ) -> Self {
        Self(path: String(path), directoryHint: directoryHint, relativeTo: self)
    }

    func appending<S: StringProtocol>(
        components: S...,
        directoryHint: DirectoryHint = .inferFromPath
    ) -> Self {
        appending(path: components.joinedAsPath(), directoryHint: directoryHint)
    }

    func appending<S: StringProtocol>(
        component: S,
        directoryHint: DirectoryHint = .inferFromPath
    ) -> Self {
        appending(components: component, directoryHint: directoryHint)
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
