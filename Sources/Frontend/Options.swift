//
// Options.swift
// createicns
//

import ArgumentParser

/// Options to share between the main command, and various helpers.
struct Options: ParsableArguments {
    @Argument(help: .input)
    var input: String?
    @Argument(help: .output)
    var output: String?
    @Flag(name: .isIconSet, help: .isIconSet)
    var isIconSet = false
    @Flag(name: .listFormats, help: .listFormats)
    var listFormats = false
}
