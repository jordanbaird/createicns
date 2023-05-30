//
// CreateICNS.swift
// createicns
//

import ArgumentParser
import Core

@main
struct CreateICNS: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "createicns",
        abstract: "Create an ICNS icon file from an image.",
        version: "0.0.4"
    )

    @Argument(help: .input)
    var input: String
    @Argument(help: .output)
    var output: String?
    @Flag(name: .iconSet, help: .isIconSet)
    var isIconSet = false

    func run() throws {
        try Runner.run { runner in
            var context = CommandContext(
                runner: runner,
                input: input,
                output: output,
                isIconSet: isIconSet
            )

            if isIconSet {
                context.actionMessage = "Creating iconset..."
                context.successMessage = "Iconset successfully created."
            } else {
                context.actionMessage = "Creating icon..."
                context.successMessage = "Icon successfully created."
                context.iconSetWriter = .iconUtil
            }

            try context.run()
        }
    }
}
