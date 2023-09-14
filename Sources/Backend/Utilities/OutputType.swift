//
//  OutputType.swift
//  createicns
//

/// The output type of the `createicns` command.
public enum OutputType: String, CaseIterable {
    /// An `icns` icon file.
    case icns
    /// An `iconset` folder.
    case iconset
    /// Infer the type from the output path extension.
    case infer
}
