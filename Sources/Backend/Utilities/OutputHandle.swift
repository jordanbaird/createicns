//
// OutputHandle.swift
// createicns
//

import Foundation

/// A type that represents a location for output.
public struct OutputHandle {
    /// A type that represents the underlying kind of an output handle.
    private enum Kind {
        case fileDescriptor(Int32)
        case outputPipe(Pipe)
        case writeHandle(FileHandle)
    }

    private let kind: Kind

    private let recursiveLock = NSRecursiveLock()

    private var writeHandle: FileHandle {
        switch kind {
        case .fileDescriptor(let fd):
            return FileHandle(fileDescriptor: fd, closeOnDealloc: false)
        case .outputPipe(let pipe):
            return pipe.fileHandleForWriting
        case .writeHandle(let handle):
            return handle
        }
    }

    private var fileDescriptor: Int32 {
        switch kind {
        case .fileDescriptor(let fd):
            return fd
        case .outputPipe(let pipe):
            return pipe.fileHandleForWriting.fileDescriptor
        case .writeHandle(let handle):
            return handle.fileDescriptor
        }
    }

    /// Returns a Boolean value that indicates whether this output handle is a terminal.
    public var isTerminal: Bool {
        isatty(fileDescriptor) == 1
    }

    private init(kind: Kind) {
        self.kind = kind
    }

    /// Creates an output handle for writing to a unique file descriptor.
    public init() {
        let pipe = Pipe()
        self.kind = .outputPipe(pipe)
    }

    /// The standard output handle.
    public static let standardOutput = Self(kind: .fileDescriptor(STDOUT_FILENO))

    /// The standard error handle.
    public static let standardError = Self(kind: .fileDescriptor(STDERR_FILENO))

    /// The output handle associated with a null device.
    public static let nullDevice = Self(kind: .writeHandle(FileHandle(forWritingAtPath: "/dev/null")!))

    /// Performs the given closure, redirecting this handle's output to the given handle.
    ///
    /// - Parameters:
    ///   - handle: An output handle to redirect this handle's output to. Pass `nil` to
    ///     use the ``nullDevice`` handle.
    ///   - body: A closure to perform while this handle's output is being redirected.
    ///
    /// - Returns: Whatever is returned from `body`.
    public func redirect<T>(into handle: Self? = nil, body: () throws -> T) rethrows -> T {
        recursiveLock.lock()
        defer {
            recursiveLock.unlock()
        }

        let handle = handle ?? .nullDevice

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
    public func write(_ string: String) {
        if #available(macOS 10.15.4, *) {
            try! writeHandle.write(contentsOf: string.data(using: .utf8)!)
        } else {
            writeHandle.write(string.data(using: .utf8)!)
        }
    }
}
