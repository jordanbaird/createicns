//
// IconUtil.swift
// createicns
//

import Foundation

/// Wraps the `iconutil` command line utility.
class IconUtil {
    enum IconUtilError: LocalizedError {
        case unknownError
        case data(Data)

        var errorDescription: String? {
            switch self {
            case .unknownError:
                return "An unknown error occurred."
            case .data(let data):
                guard let string = String(data: data, encoding: .utf8) else {
                    return Self.unknownError.errorDescription
                }
                return string
            }
        }
    }

    private let env = "/usr/bin/env"
    private let command = "iconutil"

    let iconSet: IconSet

    init(iconSet: IconSet) {
        self.iconSet = iconSet
    }

    func run(writingTo output: URL) throws {
        let tempURL = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: output,
            create: true
        )
        let iconSetURL = tempURL.appendingPathComponent("icon.iconset")
        let iconURL = tempURL.appendingPathComponent("icon.icns")

        try iconSet.write(to: iconSetURL)

        let process = Process()
        let pipe = Pipe()

        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = [command, "-c", "icns", iconSetURL.lastPathComponent]

        if #available(macOS 10.13, *) {
            process.executableURL = URL(fileURLWithPath: env)
            process.currentDirectoryURL = tempURL
            try process.run()
        } else {
            process.launchPath = env
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
            throw IconUtilError.data(data)
        }

        try FileManager.default.copyItem(at: iconURL, to: output)
        try FileManager.default.removeItem(at: tempURL)
    }
}
