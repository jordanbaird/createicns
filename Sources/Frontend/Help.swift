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
        to same as input, with a path extension specified by '--type'.
        """

    static let type = Self(
        "Output type:",
        discussion: """
            icns              - An icns icon file.
            iconset           - An iconset folder.
            infer             - Infer the type from the output path extension.
            """
    )

    static let isIconSet: Self = """
        Convert the input into an iconset file instead of inferring the type from \
        the output path extension.
        """

    static let listFormats: Self = "List valid input formats."
}

// MARK: - NameSpecification

extension NameSpecification {
    static let type: Self = .customLong("type")
    static let isIconSet: Self = [.customShort("s"), .customLong("iconset")]
    static let listFormats: Self = .customLong("formats")
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
