//
//  IconsetWriter.swift
//  createicns
//

import Foundation

/// A type that writes an iconset to an output url.
enum IconsetWriter {
    /// The iconset is written directly to the output url in the form of an ICNS file.
    case direct

    /// The iconset is written to the output url in the form of an iconset directory,
    /// using the `iconutil` command line utility.
    case iconUtil

    /// Writes the given iconset to the given output url using the method specified
    /// by this writer.
    func write(_ iconset: Iconset, to outputURL: URL) throws {
        switch self {
        case .direct:
            try iconset.write(to: outputURL)
        case .iconUtil:
            try IconUtil.write(iconset, to: outputURL)
        }
    }
}
