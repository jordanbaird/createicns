//
// Extensions.swift
// createicns
//

import ArgumentParser
import Foundation

// MARK: - ArgumentHelp

extension ArgumentHelp {
    static let input: Self = """
        A valid image file from which to create an icon. Most common bitmap \
        and vector file formats are supported. The image's width and height \
        must be equal.\n
        """

    static let output: Self = """
        The output path of the icon. If provided, the path must have the 'icns' \
        file extension. If no output is provided, the icon will be saved in the \
        same parent directory as the input.\n
        """

    static let isIconset: Self = """
        Convert the input into an iconset file instead of icns. If this option \
        is provided, the output path must have the 'iconset' extension instead \
        of 'icns'.\n
        """
}

// MARK: - NameSpecification

extension NameSpecification {
    static let iconset: Self = [.customShort("s"), .customLong("iconset")]
}

// MARK: - URL

extension URL {
    func replacingPathExtension(with newPathExtension: String) -> Self {
        deletingPathExtension().appendingPathExtension(newPathExtension)
    }
}
