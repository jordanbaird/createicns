//
// Runner.swift
// createicns
//

import Foundation
import Prism

/// A type that manages the execution and output of a command.
public final class Runner {
    /// The runner's output file.
    public var output: Output

    /// Creates a runner with the given output file.
    private init(output: Output) {
        self.output = output
    }

    /// Performs the given closure within the context of a runner with a default
    /// output file of ``Output-swift.struct/standardOutput``.
    public static func run(body: (Runner) throws -> Void) rethrows {
        do {
            let runner = Runner(output: .standardOutput)
            try body(runner)
        } catch {
            throw RunnerError(error: error)
        }
    }

    /// Writes the given items to the runner's ``output-swift.property``, using the
    /// given color, separator and terminator.
    ///
    /// - Note: The separator and terminator are not colored.
    public func print(_ items: Any..., color: PrismColor? = nil, separator: String = " ", terminator: String = "\n") {
        var buffer = OutputBuffer()
        if let color {
            buffer.descriptionHook = { item in
                String(describing: item).foregroundColor(color)
            }
        }
        var prefix = ""
        for item in items {
            buffer.write(prefix)
            buffer.writeDescription(of: item)
            prefix = separator
        }
        buffer.write(terminator)
        buffer.flush(to: output)
    }
}

extension Runner {
    /// A text output stream representing a buffer of bytes that can be accumulated
    /// and flushed to an output file.
    public struct OutputBuffer: TextOutputStream {
        private var bytes: [UInt8]

        /// A hook used to get the description of an item, used by ``writeDescription(of:)``.
        ///
        /// The default hook passes the item into `String.init(describing:)`.
        public var descriptionHook: (Any) -> String = { item in
            String(describing: item)
        }

        /// Creates an output buffer with the given bytes.
        public init(bytes: [UInt8]) {
            self.bytes = bytes
        }

        /// Creates an empty output buffer.
        public init() {
            self.init(bytes: [])
        }

        /// Writes the contents of the given string to the buffer.
        public mutating func write(_ string: String) {
            bytes.append(contentsOf: string.utf8)
        }

        /// Writes a description of the given item to the buffer.
        public mutating func writeDescription(of item: Any) {
            write(descriptionHook(item))
        }

        /// Flushes the buffer to the given output file.
        ///
        /// This operation consumes the buffer.
        public mutating func flush(to output: Output) {
            output.write(bytes: &bytes)
        }
    }

    /// A type that represents an output file.
    public struct Output {
        /// This instance's underlying file handle.
        private let fileHandle: FileHandle

        /// The standard output file.
        public static let standardOutput = Self(fileHandle: .standardOutput)

        /// The standard error file.
        public static let standardError = Self(fileHandle: .standardError)

        /// Writes the given collection of bytes to the output.
        ///
        /// This operation consumes the collection.
        public func write<C: RangeReplaceableCollection>(bytes: inout C) where C.Element == UInt8 {
            let data = Data(bytes)
            if #available(macOS 10.15.4, *) {
                do {
                    try fileHandle.write(contentsOf: data)
                } catch {
                    fatalError("Failed to write data to output.")
                }
            } else {
                fileHandle.write(data)
            }
            bytes.removeAll()
        }
    }

    /// An error that may be thrown during the operations of a ``Runner``.
    public struct RunnerError: LocalizedError {
        /// The underlying error.
        public let error: Error

        /// Creates a runner error with an underlying error.
        public init(error: Error) {
            self.error = error
        }

        /// A description of the underlying error, printed in red.
        public var errorDescription: String? {
            error.localizedDescription.foregroundColor(.red)
        }
    }
}
