//
// Options.swift
// createicns
//

import ArgumentParser
import Backend

// MARK: OutputType: ExpressibleByArgument
extension OutputType: ExpressibleByArgument { }

// MARK: - Options

struct Options: ParsableArguments {
    @Argument(help: .input)
    var input: String?

    @Argument(help: .output)
    var output: String?

    @Option(name: .type, help: .type)
    var type: OutputType = .infer

    @Flag(name: .isIconSet, help: .isIconSet)
    private var isIconSet = false // deprecated

    @Flag(name: .listFormats, help: .listFormats)
    var listFormats = false

    mutating func validate() throws {
        if isIconSet {
            type = .iconSet // Set the type to simulate the behavior of --iconset
            print(
                FormattedText("warning:", color: .yellow, style: .bold)
                    .appending(" '")
                    .appending("-s", color: .yellow)
                    .appending(", ")
                    .appending("--iconset", color: .yellow)
                    .appending("' is deprecated: use '")
                    .appending("--type", color: .cyan)
                    .appending("' instead.")
            )
        }
    }
}
