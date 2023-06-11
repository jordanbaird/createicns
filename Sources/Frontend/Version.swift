//
// Version.swift
// createicns
//

/// A type that represents a semantic versioning number.
struct Version {
    /// The major version.
    let major: Int

    /// The minor version.
    let minor: Int

    /// The path version.
    let patch: Int

    /// The full version string.
    var versionString: String {
        "\(major).\(minor).\(patch)"
    }

    /// The current version of the `createicns` tool.
    static var current: Self {
        Self(major: 0, minor: 0, patch: 4)
    }
}
