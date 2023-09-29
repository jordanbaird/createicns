//
//  FileInfo.swift
//  createicns
//

import Foundation

private let pathSeparator = "/"

private func pathIsDirectory(_ path: String, hint: FileInfo.DirectoryHint) -> Bool {
    switch hint {
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

private func joinPathComponents<S: Sequence>(_ components: S) -> String where S.Element: StringProtocol {
    components.joined(separator: pathSeparator)
}

// MARK: - FileInfo

/// A type that contains information associated with a standardized file path or url.
struct FileInfo: Hashable {

    // MARK: Types

    /// Constants that specify how to determine whether file information references
    /// a directory.
    enum DirectoryHint {
        /// Specifies that the file information references a directory.
        case isDirectory

        /// Specifies that the file information does not reference a directory.
        case notDirectory

        /// Specifies that the file system should be checked to determine whether
        /// the file information references a directory.
        case checkFileSystem

        /// Specifies that the file information should infer whether it references
        /// a directory based on whether its path has a trailing slash.
        case inferFromPath
    }

    // MARK: Properties

    /// The standardized url associated with this file information.
    let url: URL

    /// The standardized path associated with this file information.
    var path: String {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            return components.path
        }
        return url.path
    }

    /// The last path component of the file information.
    var lastPathComponent: String {
        url.lastPathComponent
    }

    /// The path extension of the file information.
    var pathExtension: String {
        url.pathExtension
    }

    /// A Boolean value that indicates whether the path associated with the file
    /// information points to a valid file.
    var fileExists: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    /// A Boolean value that indicates whether the path associated with the file
    /// information points to a valid directory.
    var isDirectory: Bool {
        pathIsDirectory(path, hint: .checkFileSystem)
    }

    /// The file type associated with the file information's path extension.
    var fileType: FileType? {
        FileType(pathExtension: pathExtension)
    }

    // MARK: Initializers

    /// Creates a file information instance from the given url.
    init(url: URL) {
        self.url = url.standardizedFileURL
    }

    /// Creates a file information instance from the given path and directory hint,
    /// relative to a base instance.
    init<S: StringProtocol>(
        path: S,
        directoryHint: DirectoryHint = .inferFromPath,
        relativeTo base: Self? = nil
    ) {
        let path = String(path)
        let isDirectory = pathIsDirectory(path, hint: directoryHint)
        let url = URL(fileURLWithPath: path, isDirectory: isDirectory, relativeTo: base?.url)
        self.init(url: url)
    }

    // MARK: Instance Methods

    /// Returns a new file information instance by appending the given path string
    /// to this instance using the given directory hint.
    func appending<S: StringProtocol>(
        path: S,
        directoryHint: DirectoryHint = .inferFromPath
    ) -> Self {
        Self(path: path, directoryHint: directoryHint, relativeTo: self)
    }

    /// Returns a new file information instance by appending the given path components
    /// to this instance using the given directory hint.
    func appending<S: StringProtocol>(
        components: S...,
        directoryHint: DirectoryHint = .inferFromPath
    ) -> Self {
        appending(path: joinPathComponents(components), directoryHint: directoryHint)
    }

    /// Returns a new file information instance by appending the given path component
    /// to this instance using the given directory hint.
    func appending<S: StringProtocol>(
        component: S,
        directoryHint: DirectoryHint = .inferFromPath
    ) -> Self {
        appending(components: component, directoryHint: directoryHint)
    }

    /// Returns a new file information instance by appending the given path extension
    /// to this instance.
    func appendingPathExtension(_ pathExtension: String) -> Self {
        Self(url: url.appendingPathExtension(pathExtension))
    }

    /// Returns a new file information instance by appending the given file type's
    /// preferred path extension to this instance.
    func appendingPathExtension(for fileType: FileType) -> Self {
        if let current = self.fileType {
            guard current != fileType else {
                return self
            }
        }
        if let pathExtension = fileType.preferredFilenameExtension {
            return appendingPathExtension(pathExtension)
        }
        return self
    }

    /// Returns a new file information instance by deleting the path extension from
    /// this instance.
    func deletingPathExtension() -> Self {
        Self(url: url.deletingPathExtension())
    }

    /// Returns a new file information instance by replacing this instance's path
    /// extension with the given path extension.
    func withPathExtension(_ pathExtension: String) -> Self {
        deletingPathExtension().appendingPathExtension(pathExtension)
    }

    /// Returns a new file information instance by replacing this instance's path
    /// extension with the given file type's preferred path extension.
    func withPathExtension(for fileType: FileType) -> Self {
        deletingPathExtension().appendingPathExtension(for: fileType)
    }
}
