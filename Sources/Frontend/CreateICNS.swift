//
// CreateICNS.swift
// createicns
//

import ArgumentParser
import Backend

@main
struct CreateICNS: ParsableCommand {
    static let commandName = "createicns"

    static let configuration = CommandConfiguration(
        commandName: commandName,
        abstract: "Create 'icns' and 'iconset' files from standard images.",
        usage: "\(commandName) [<options>] <input> [<output>]",
        version: Version.current.versionString
    )

    @OptionGroup var options: Options

    func run() throws {
        try MainRunner(
            input: options.input,
            output: options.output,
            type: options.type,
            listFormats: options.listFormats,
            helpMessage: HelpGenerator<Self>.generate
        ).run()
    }
}
