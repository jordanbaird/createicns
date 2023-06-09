//
// FileInfo.swift
// createicns
//

import Foundation

private extension StringProtocol {
    static var pathSeparator: String { "/" }

    var fileExists: Bool {
        FileManager.default.fileExists(atPath: String(self))
    }

    func isDirectory(directoryHint: FileInfo.DirectoryHint) -> Bool {
        switch directoryHint {
        case .isDirectory:
            return true
        case .notDirectory:
            return false
        case .checkFileSystem:
            var b: ObjCBool = false
            return FileManager.default.fileExists(atPath: String(self), isDirectory: &b) && b.boolValue
        case .inferFromPath:
            return hasSuffix(Self.pathSeparator)
        }
    }
}

private extension Sequence where Element: StringProtocol {
    func joinedAsPath() -> String {
        joined(separator: Element.pathSeparator)
    }
}

/// A representation of a file containing a standardized path string and url.
private struct FileRepresentation {
    /// A standardized url representing the file.
    let url: URL

    /// A standardized path string representing the file.
    var path: String {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            return components.percentEncodedPath
        }
        return url.path
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
        self.init(standardizing: URL(fileURLWithPath: filePath))
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

    var url: URL {
        representation.url
    }

    var path: String {
        representation.path
    }

    var lastPathComponent: String {
        url.lastPathComponent
    }

    var pathExtension: String {
        url.pathExtension
    }

    var fileExists: Bool {
        path.fileExists
    }

    var isDirectory: Bool {
        path.isDirectory(directoryHint: .checkFileSystem)
    }

    init(url: URL) {
        self.representation = FileRepresentation(fileURL: url)
    }

    init<S: StringProtocol>(
        path: S,
        directoryHint: DirectoryHint = .inferFromPath,
        relativeTo base: Self? = nil
    ) {
        let path = String(path)
        let isDirectory = path.isDirectory(directoryHint: directoryHint)
        let url = URL(fileURLWithPath: path, isDirectory: isDirectory, relativeTo: base?.url)
        self.init(url: url)
    }

    func appending<S: StringProtocol>(
        path: S,
        directoryHint: DirectoryHint = .inferFromPath
    ) -> Self {
        Self(path: path, directoryHint: directoryHint, relativeTo: self)
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
