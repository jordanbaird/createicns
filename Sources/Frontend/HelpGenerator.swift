//
// HelpGenerator.swift
// createicns
//

import ArgumentParser

/// A type that generates a succinct version of the command's help message.
///
/// The only difference between the help message produced by this type, and
/// the default help message is the lack of a one-line description in the help
/// message produced by this type.
enum HelpGenerator {
    /// A private command with the same configuration and arguments as the main
    /// command, the only difference being the lack of an abstract message for
    /// a more succinct version of the generated help message.
    private struct Command: ParsableCommand {
        static let configuration: CommandConfiguration = {
            var configuration = CreateICNS.configuration
            configuration.abstract = ""
            return configuration
        }()

        @OptionGroup var options: Options
    }

    /// Produces a string containing a succinct version of the command's help
    /// message.
    static func generate() -> String {
        Command.helpMessage()
    }
}
