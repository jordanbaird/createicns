//
//  IconUtil.swift
//  createicns
//

import Foundation

/// Wraps the `iconutil` command line utility.
enum IconUtil {
    /// Writes the given iconset to the given output url.
    static func write(_ iconset: Iconset, to outputURL: URL) throws {
        let tempURL = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: outputURL,
            create: true
        )

        let iconsetURL = tempURL.appendingPathComponent("icon.iconset")
        let iconURL = tempURL.appendingPathComponent("icon.icns")

        // ** Workaround for not being able to throw out of a defer block: **
        // To ensure the temp directory is removed, we do most of the heavy lifting in the
        // initializer of a Result value, catching and storing any thrown errors. Then, we
        // remove the temp url and access the result to either rethrow the caught error or
        // return successfully.
        let result = Result {
            try iconset.write(to: iconsetURL)

            let process = Process()
            let pipe = Pipe()

            process.standardOutput = pipe
            process.standardError = pipe
            process.arguments = ["iconutil", "-c", "icns", iconsetURL.lastPathComponent]
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.currentDirectoryURL = tempURL

            try process.run()
            process.waitUntilExit()

            // iconutil only returns data if something went wrong
            let fileHandle = pipe.fileHandleForReading
            if #available(macOS 10.15.4, *) {
                if let data = try fileHandle.readToEnd() {
                    throw ContextualDataError(data, context: self)
                }
            } else {
                let data = fileHandle.readDataToEndOfFile()
                if !data.isEmpty {
                    throw ContextualDataError(data, context: self)
                }
            }

            try FileManager.default.copyItem(at: iconURL, to: outputURL)
        }

        try FileManager.default.removeItem(at: tempURL)
        try result.get()
    }
}
