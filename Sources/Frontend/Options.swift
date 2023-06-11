//
// Options.swift
// createicns
//

import ArgumentParser

enum OutputType: String, CaseIterable, ExpressibleByArgument {
    case icns = "icns"
    case iconSet = "iconset"
    case infer = "infer"
}

struct SharedOptions: ParsableArguments {
    @Argument(help: .input)
    var input: String?
    @Argument(help: .output)
    var output: String?
    @Option(name: .type, help: .type)
    var type: OutputType = .infer
    @Flag(name: .listFormats, help: .listFormats)
    var listFormats = false
}

struct DeprecatedOptions: ParsableArguments {
    @Flag(name: .isIconSet, help: .isIconSet)
    var isIconSet = false
}

@dynamicMemberLookup
struct DefaultOptions: ParsableArguments {
    @OptionGroup var shared: SharedOptions
    @OptionGroup var deprecated: DeprecatedOptions

    subscript<Value>(dynamicMember keyPath: KeyPath<SharedOptions, Value>) -> Value {
        shared[keyPath: keyPath]
    }

    subscript<Value>(dynamicMember keyPath: KeyPath<DeprecatedOptions, Value>) -> Value {
        deprecated[keyPath: keyPath]
    }
}
