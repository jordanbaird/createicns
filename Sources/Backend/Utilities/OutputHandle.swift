//
// OutputHandle.swift
// createicns
//

import Foundation

/// A type that represents a location for output.
public struct OutputHandle {

    // MARK: Types

    /// A type that represents the underlying kind of an output handle.
    private enum Kind {
        case fileDescriptor(Int32)
        case outputPipe(Pipe)
    }

    // MARK: Properties

    private let kind: Kind

    private let recursiveLock = NSRecursiveLock()

    /// The file descriptor representing this output handle.
    public var fileDescriptor: Int32 {
        switch kind {
        case .fileDescriptor(let fd):
            return fd
        case .outputPipe(let pipe):
            return pipe.fileHandleForWriting.fileDescriptor
        }
    }

    /// Returns a Boolean value that indicates whether this output handle is a terminal.
    public var isTerminal: Bool {
        isatty(fileDescriptor) == 1
    }

    // MARK: Initializers

    private init(kind: Kind) {
        self.kind = kind
    }

    /// Creates an output handle for writing to a unique file descriptor.
    public init() {
        let pipe = Pipe()
        self.kind = .outputPipe(pipe)
    }

    // MARK: Standard Handles

    /// The standard output handle.
    public static let standardOutput = OutputHandle(kind: .fileDescriptor(STDOUT_FILENO))
    /// The standard error handle.
    public static let standardError  = OutputHandle(kind: .fileDescriptor(STDERR_FILENO))

    // MARK: Instance Methods

    /// Performs the given closure while redirecting the output of this handle
    /// into another handle.
    ///
    /// - Parameters:
    ///   - handle: An output handle to redirect the output of this handle into.
    ///     Pass `nil` to use an empty handle.
    ///   - body: A closure to perform while the output of this handle is being
    ///     redirected.
    ///
    /// - Returns: Whatever is returned from `body`.
    public func redirect<T>(into handle: Self? = nil, body: () throws -> T) rethrows -> T {
        recursiveLock.lock()
        defer {
            recursiveLock.unlock()
        }

        let handle = handle ?? Self()

        // Create a temporary file descriptor to maintain a reference to the original
        // file, then point this handle's descriptor at the replacement handle's file.
        let tempfd = dup(fileDescriptor)
        dup2(handle.fileDescriptor, fileDescriptor)

        defer {
            // Point this handle back to the original file and close the temp.
            dup2(tempfd, fileDescriptor)
            close(tempfd)
        }

        return try body()
    }
}

// MARK: OutputHandle: Equatable
extension OutputHandle: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.fileDescriptor == rhs.fileDescriptor
    }
}

// MARK: OutputHandle: Hashable
extension OutputHandle: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fileDescriptor)
    }
}

// MARK: OutputHandle: TextOutputStream
extension OutputHandle: TextOutputStream {
    private func write<S: Sequence>(_ elements: S, to fileHandle: FileHandle) where S.Element == UInt8 {
        if #available(macOS 10.15.4, *) {
            // We want to be alerted of a failure here, so a force try is acceptable.
            // swiftlint:disable:next force_try
            try! fileHandle.write(contentsOf: Data(elements))
        } else {
            fileHandle.write(Data(elements))
        }
    }

    public func write(_ string: String) {
        switch kind {
        case .fileDescriptor(let fd):
            write(string.utf8, to: FileHandle(fileDescriptor: fd, closeOnDealloc: false))
        case .outputPipe(let pipe):
            write(string.utf8, to: pipe.fileHandleForWriting)
        }
    }
}
