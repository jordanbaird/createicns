//
// IconSetWriter.swift
// createicns
//

import Foundation

/// A type that writes an iconset to an output url.
public enum IconSetWriter {
    /// The iconset is written directly to the output url in the form of an ICNS file.
    case direct

    /// The iconset is written to the output url in the form of an iconset directory,
    /// using the `iconutil` command line utility.
    case iconUtil

    /// Writes the given iconset to the given output url using the method specified
    /// by this writer.
    public func write(iconSet: IconSet, outputURL: URL) throws {
        switch self {
        case .direct:
            try iconSet.write(to: outputURL)
        case .iconUtil:
            try IconUtil(iconSet: iconSet).run(writingTo: outputURL)
        }
    }
}
