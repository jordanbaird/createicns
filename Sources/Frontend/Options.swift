//
// Options.swift
// createicns
//

import ArgumentParser

// MARK: - OutputType

enum OutputType: String, CaseIterable, ExpressibleByArgument {
    case icns = "icns"
    case iconSet = "iconset"
    case infer = "infer"
}

// MARK: - MainOptions

struct MainOptions: ParsableArguments {
    @Argument(help: .input)
    var input: String?
    @Argument(help: .output)
    var output: String?
    @Option(name: .type, help: .type)
    var type: OutputType = .infer
    @Flag(name: .listFormats, help: .listFormats)
    var listFormats = false
}

// MARK: - DeprecatedOptions

struct DeprecatedOptions: ParsableArguments {
    @Flag(name: .isIconSet, help: .isIconSet)
    var isIconSet = false
}

// MARK: - AllOptions

@dynamicMemberLookup
struct AllOptions: ParsableArguments {
    @OptionGroup var main: MainOptions
    @OptionGroup var deprecated: DeprecatedOptions

    subscript<Value>(dynamicMember keyPath: KeyPath<MainOptions, Value>) -> Value {
        main[keyPath: keyPath]
    }

    subscript<Value>(dynamicMember keyPath: KeyPath<DeprecatedOptions, Value>) -> Value {
        deprecated[keyPath: keyPath]
    }
}
