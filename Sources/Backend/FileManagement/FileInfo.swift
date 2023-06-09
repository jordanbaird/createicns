//
// FileInfo.swift
// createicns
//

import Foundation

// MARK: - StringProtocol Extension

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

// MARK: - Sequence where Element: StringProtocol

private extension Sequence where Element: StringProtocol {
    func joinedAsPath() -> String {
        joined(separator: Element.pathSeparator)
    }
}

// MARK: - FileRepresentation

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

// MARK: FileRepresentation: Codable
extension FileRepresentation: Codable { }

// MARK: FileRepresentation: Equatable
extension FileRepresentation: Equatable { }

// MARK: FileRepresentation: Hashable
extension FileRepresentation: Hashable { }

// MARK: - FileInfo

/// A type that contains information associated with a standardized file
/// path or url.
struct FileInfo {

    // MARK: Types

    /// Constants that specify the method to use to determine whether a
    /// path or url references a directory.
    enum DirectoryHint {
        /// Specifies that the path or url does reference a directory.
        case isDirectory
        /// Specifies that the path or url does not reference a directory.
        case notDirectory
        /// Specifies that the path or url should check with the file system
        /// to determine whether it references a directory.
        case checkFileSystem
        /// Specifies that the path or url should infer whether it references
        /// a directory based on whether it has a trailing dash.
        case inferFromPath
    }

    // MARK: Properties

    /// The file information's underlying representation.
    private let representation: FileRepresentation

    /// The standardized url associated with this file information.
    var url: URL {
        representation.url
    }

    /// The standardized path associated with this file information.
    var path: String {
        representation.path
    }

    /// The last path component of the file information.
    var lastPathComponent: String {
        url.lastPathComponent
    }

    /// The path extension of the file information.
    var pathExtension: String {
        url.pathExtension
    }

    /// A Boolean value that indicates whether the path associated with the
    /// file information points to a valid file.
    var fileExists: Bool {
        path.fileExists
    }

    /// A Boolean value that indicates whether the path associated with the
    /// file information points to a valid directory.
    var isDirectory: Bool {
        path.isDirectory(directoryHint: .checkFileSystem)
    }

    // MARK: Initializers

    /// Creates a file information instance from the given url.
    init(url: URL) {
        self.representation = FileRepresentation(fileURL: url)
    }

    /// Creates a file information instance from the given path and directory
    /// hint, relative to a base file information instance.
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

    // MARK: Instance Methods

    /// Returns a new file information instance by appending the given path
    /// string to this instance using the given directory hint.
    func appending<S: StringProtocol>(
        path: S,
        directoryHint: DirectoryHint = .inferFromPath
    ) -> Self {
        Self(path: path, directoryHint: directoryHint, relativeTo: self)
    }

    /// Returns a new file information instance by appending the given path
    /// components to this instance using the given directory hint.
    func appending<S: StringProtocol>(
        components: S...,
        directoryHint: DirectoryHint = .inferFromPath
    ) -> Self {
        appending(path: components.joinedAsPath(), directoryHint: directoryHint)
    }

    /// Returns a new file information instance by appending the given path
    /// component to this instance using the given directory hint.
    func appending<S: StringProtocol>(
        component: S,
        directoryHint: DirectoryHint = .inferFromPath
    ) -> Self {
        appending(components: component, directoryHint: directoryHint)
    }

    /// Returns a new file information instance by appending the given path
    /// extension to this instance.
    func appendingPathExtension(_ pathExtension: String) -> Self {
        Self(url: url.appendingPathExtension(pathExtension))
    }

    /// Returns a new file information instance by appending the given file
    /// type's preferred path extension to this instance.
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

    /// Returns a new file information instance by deleting the path extension
    /// from this instance.
    func deletingPathExtension() -> Self {
        Self(url: url.deletingPathExtension())
    }

    /// Returns a new file information instance by replacing this instance's
    /// path extension with the given path extension.
    func withPathExtension(_ pathExtension: String) -> Self {
        deletingPathExtension().appendingPathExtension(pathExtension)
    }

    /// Returns a new file information instance by replacing this instance's
    /// path extension with the given file type's preferred path extension.
    func withPathExtension(for fileType: FileType) -> Self {
        deletingPathExtension().appendingPathExtension(for: fileType)
    }
}

// MARK: FileInfo: Codable
extension FileInfo: Codable { }

// MARK: FileInfo: Equatable
extension FileInfo: Equatable { }

// MARK: FileInfo: Hashable
extension FileInfo: Hashable { }

// MARK: FileInfo.DirectoryHint: Codable
extension FileInfo.DirectoryHint: Codable { }

// MARK: FileInfo.DirectoryHint: Equatable
extension FileInfo.DirectoryHint: Equatable { }

// MARK: FileInfo.DirectoryHint: Hashable
extension FileInfo.DirectoryHint: Hashable { }
