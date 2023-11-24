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
        print("error:".formatted(color: .red, style: .bold) + " " + box.errorMessage)
        if let fix = box.fix {
            print("fix:".formatted(color: .green, style: .bold) + " " + fix)
        }
        Darwin.exit(EXIT_FAILURE)
    }
}
