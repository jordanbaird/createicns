//
// OutputHandle.swift
// createicns
//

import Darwin

/// A type that represents a location for output.
public struct OutputHandle {
    /// The file descriptor representing this output handle.
    public let fileDescriptor: Int32

    /// Returns a Boolean value that indicates whether this output handle
    /// is a terminal.
    public var isTerminal: Bool {
        isatty(fileDescriptor) == 1
    }

    /// Creates an output handle with the given file descriptor.
    private init(fileDescriptor: Int32) {
        self.fileDescriptor = fileDescriptor
    }

    /// The standard output handle.
    public static let standardOutput = Self(fileDescriptor: STDOUT_FILENO)

    /// The standard error handle.
    public static let standardError = Self(fileDescriptor: STDERR_FILENO)
}
