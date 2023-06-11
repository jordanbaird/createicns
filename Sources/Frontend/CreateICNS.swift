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
        abstract: "Create an icns or iconset file from an image.",
        version: "0.0.4"
    )

    @Argument(help: .input)
    var input: String?
    @Argument(help: .output)
    var output: String?
    @Flag(name: .isIconSet, help: .isIconSet)
    var isIconSet = false
    @Flag(name: .listFormats, help: .listFormats)
    var listFormats = false

    func run() throws {
        do {
            try MainRunner(
                input: input,
                output: output,
                isIconSet: isIconSet,
                listFormats: listFormats,
                helpMessage: HelpGenerator<Self>.generate
            ).run()
        } catch {
            throw error.formatted
        }
    }
}
