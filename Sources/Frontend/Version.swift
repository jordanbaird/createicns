//
//  Version.swift
//  createicns
//

/// A type that represents a semantic versioning number.
struct Version {
    /// The major version.
    let major: Int

    /// The minor version.
    let minor: Int

    /// The patch version.
    let patch: Int

    /// The full version string.
    var versionString: String {
        "\(major).\(minor).\(patch)"
    }

    /// The current version of the `createicns` tool.
    static var current: Version {
        Version(major: 0, minor: 1, patch: 1)
    }
}
