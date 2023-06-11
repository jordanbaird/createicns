//
// Help.swift
// createicns
//

import ArgumentParser

// MARK: - ArgumentHelp

extension ArgumentHelp {
    static let input: Self = """
        Path to an input image. Most common bitmap formats are supported. Image \
        width and height must be equal.
        """

    static let output: Self = """
        Output path of the created icon. If this option is not present, defaults \
        to the same directory as input, with a file extension specified by '--type'.
        """

    static let type = Self(
        "Output type:",
        discussion: """
            icns              - An icns icon file.
            iconset           - A bundled iconset folder.
            infer             - Infer the type based on the output file extension.
            """
    )

    static let isIconSet: Self = """
        *** DEPRECATED *** use '--type' instead.
        Convert the input into an iconset file instead of inferring the type from \
        the output path extension.
        """

    static let listFormats: Self = "List valid input formats."
}

// MARK: - NameSpecification

extension NameSpecification {
    static let type: Self = .customLong("type")
    static let isIconSet: Self = [.customShort("s"), .customLong("iconset")]
    static let listFormats: Self = [.customShort("l"), .customLong("list")]
}

// MARK: - HelpGenerator

/// A type that generates a shortened version of a base command's help message.
enum HelpGenerator<Base: ParsableCommand> {
    private struct Command: ParsableCommand {
        static var configuration: CommandConfiguration {
            var configuration = Base.configuration
            configuration.abstract = ""
            return configuration
        }

        @OptionGroup var base: Base
    }

    /// Generates a shortened version of the base command's help message.
    static func generate() -> String {
        Command.helpMessage()
    }
}
