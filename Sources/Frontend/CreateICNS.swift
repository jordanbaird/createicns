//
// CreateICNS.swift
// createicns
//

import ArgumentParser
import Backend

@main
struct CreateICNS: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "createicns",
        abstract: "Create an icns icon file from an image.",
        version: "0.0.4"
    )

    @OptionGroup var options: Options

    func run() throws {
        do {
            try MainRunner(
                input: options.input,
                output: options.output,
                isIconSet: options.isIconSet,
                listFormats: options.listFormats,
                helpMessage: HelpGenerator.generate
            ).run()
        } catch {
            throw error.formatted
        }
    }
}
