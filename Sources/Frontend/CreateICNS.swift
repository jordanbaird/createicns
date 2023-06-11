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
        abstract: "Create an icns or iconset file from an image.",
        usage: "\(commandName) [<options>] <input> [<output>]",
        version: "0.0.4"
    )

    @OptionGroup var options: DefaultOptions

    func run() throws {
        do {
            try MainRunner(
                input: options.input,
                output: options.output,
                isIconSet: options.isIconSet,
                listFormats: options.listFormats,
                helpMessage: HelpGenerator<Self>.generate
            ).run()
        } catch {
            throw error.formatted
        }
    }
}
