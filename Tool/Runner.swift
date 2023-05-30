//
// Runner.swift
// createicns
//

import Foundation
import Prism

final class Runner {
    var output: Output

    private init(output: Output) {
        self.output = output
    }

    static func run(body: (Runner) throws -> Void) rethrows {
        do {
            let runner = Runner(output: .standardOutput)
            try body(runner)
        } catch {
            throw RunError(error: error)
        }
    }

    func print(_ items: Any..., color: PrismColor? = nil, separator: String = " ", terminator: String = "\n") {
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
    struct OutputBuffer: TextOutputStream {
        private var bytes: [UInt8]

        var descriptionHook: (Any) -> String = { item in
            String(describing: item)
        }

        init(bytes: [UInt8]) {
            self.bytes = bytes
        }

        init() {
            self.init(bytes: [])
        }

        mutating func write(_ string: String) {
            bytes.append(contentsOf: string.utf8)
        }

        mutating func writeDescription(of item: Any) {
            write(descriptionHook(item))
        }

        mutating func flush(to output: Output) {
            output.write(bytes: &bytes)
        }
    }

    struct Output {
        private let fileHandle: FileHandle

        static let standardError = Self(fileHandle: .standardError)

        static let standardOutput = Self(fileHandle: .standardOutput)

        func write(bytes: inout [UInt8]) {
            let data = Data(bytes)
            if #available(macOS 10.15.4, *) {
                do {
                    try fileHandle.write(contentsOf: data)
                } catch {
                    fatalError("Failed to write text to output.")
                }
            } else {
                fileHandle.write(data)
            }
            bytes.removeAll()
        }
    }

    struct RunError: LocalizedError {
        let error: Error

        var errorDescription: String? {
            error.localizedDescription.foregroundColor(.red)
        }
    }
}
