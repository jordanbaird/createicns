//
// Extensions.swift
// createicns
//

import ArgumentParser

extension ArgumentHelp {
    static let input: Self = """
        A path to an image file from which to create an icon. Most common \
        bitmap formats are supported. The image must have an equal width \
        and height.\n
        """

    static let output: Self = """
        The output path of the created icon. If this option is present, \
        its path extension must be 'icns'. If this option is not present, \
        the icon will be saved in the same directory as the input, with \
        the 'icns' extension automatically added.\n
        """

    static let isIconSet: Self = """
        Convert the input into an iconset file instead of an ICNS file. If \
        this option is present with an output, the output path's extension \
        must be 'iconset'.\n
        """
}

extension NameSpecification {
    static let iconSet: Self = [.customShort("s"), .customLong("iconset")]
}
