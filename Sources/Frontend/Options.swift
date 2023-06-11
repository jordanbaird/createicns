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

    @Flag(name: .isIconSet, help: .isIconSet) // deprecated
    var isIconSet = false

    @Flag(name: .listFormats, help: .listFormats)
    var listFormats = false

    mutating func validate() throws {
        if isIconSet {
            isIconSet = false
            type = .iconSet // Set the type explicitly to simulate the behavior of --iconset.
            var warningMessage: FormattedText = "\("warning:", color: .yellow, style: .bold) "
            warningMessage.append("'\("-s, --iconset", color: .yellow)' is deprecated: ")
            warningMessage.append("use '\("--type", color: .cyan)' instead.")
            print(warningMessage)
        }
    }
}
