//
// IconUtil.swift
// createicns
//

import Foundation

/// Wraps the `iconutil` command line utility.
enum IconUtil {
    private struct IconUtilError: Error, CustomStringConvertible {
        let data: Data

        init(_ data: Data) {
            self.data = data
        }

        var description: String {
            guard let string = String(data: data, encoding: .utf8) else {
                return "An unknown error occurred."
            }
            return string
        }
    }

    /// Writes the given iconset to the given output url.
    static func write(_ iconSet: IconSet, to outputURL: URL) throws {
        let tempURL = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: outputURL,
            create: true
        )

        let iconSetURL = tempURL.appendingPathComponent("icon.iconset")
        let iconURL = tempURL.appendingPathComponent("icon.icns")

        // ** Workaround for not being able to throw out of a defer block: **
        // To ensure the temp directory is removed, we do most of the heavy lifting in the
        // initializer of a Result value, catching and storing any thrown errors. Then, we
        // remove the temp url and access the result to either rethrow the caught error or
        // return successfully.
        let result = Result {
            try iconSet.write(to: iconSetURL)
            
            let process = Process()
            let pipe = Pipe()
            
            process.standardOutput = pipe
            process.standardError = pipe
            process.arguments = ["iconutil", "-c", "icns", iconSetURL.lastPathComponent]
            
            let envPath = "/usr/bin/env"
            
            if #available(macOS 10.13, *) {
                process.executableURL = URL(fileURLWithPath: envPath)
                process.currentDirectoryURL = tempURL
                try process.run()
            } else {
                process.launchPath = envPath
                process.currentDirectoryPath = tempURL.path
                process.launch()
            }
            process.waitUntilExit()
            
            let data: Data? = {
                let fileHandle = pipe.fileHandleForReading
                if #available(macOS 10.15.4, *) {
                    return try? fileHandle.readToEnd()
                } else {
                    let data = fileHandle.readDataToEndOfFile()
                    return data.isEmpty ? nil : data
                }
            }()
            
            // iconutil only returns data if something went wrong.
            if let data {
                throw IconUtilError(data)
            }

            try FileManager.default.copyItem(at: iconURL, to: outputURL)
        }

        try FileManager.default.removeItem(at: tempURL)
        try result.get()
    }
}
