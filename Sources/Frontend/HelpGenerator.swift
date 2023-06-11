//
// HelpGenerator.swift
// createicns
//

import ArgumentParser

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
