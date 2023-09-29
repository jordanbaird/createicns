//
//  MainRunner.swift
//  createicns
//

import Darwin

/// The main runner that encapsulates the behavior of the tool, delegating
/// parts of its execution to additional sub-runners.
public struct MainRunner: Runner {
    private let runners: [Runner]

    /// Creates a runner that encapsulates the behavior of the tool, delegating
    /// to additional sub-runners depending on the arguments passed in.
    public init(
        input: String?,
        output: String?,
        type: OutputType,
        listFormats: Bool,
        helpMessage: @escaping () -> String
    ) {
        var runners = [Runner]()

        if let input {
            runners.append(Create(input: input, output: output, type: type))
        }

        if listFormats {
            runners.append(ListFormats())
        }

        if runners.isEmpty {
            runners.append(PrintHelpMessage(helpMessage))
        }

        self.runners = runners
    }

    public func validate() throws {
        for runner in runners {
            try runner.validate()
        }
    }

    public func run() {
        do {
            try validate()
            for runner in runners {
                try runner.run()
            }
        } catch {
            exit(with: error)
        }
    }

    func exit(with error: Error) -> Never {
        let box = FormattedErrorBox(error: error)
        let errorText = FormattedText("error:", color: .red, style: .bold)
            .appending(" ")
            .appending(box.errorMessage)
        print(errorText)
        if let fix = box.fix {
            let fixText = FormattedText("fix:", color: .green, style: .bold)
                .appending(" ")
                .appending(fix)
            print(fixText)
        }
        Darwin.exit(EXIT_FAILURE)
    }
}
