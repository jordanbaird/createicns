//
// MainRunner.swift
// createicns
//

/// The main runner that encapsulates the behavior of the command, delegating
/// parts of its execution to additional sub-runners.
public struct MainRunner: Runner {
    private let runners: [Runner]

    /// Creates a runner that encapsulates the behavior of the command, delegating
    /// to additional sub-runners depending on the arguments passed in.
    public init(
        input: String?,
        output: String?,
        type: OutputType,
        listFormats: Bool,
        helpMessage: @escaping () -> String
    ) throws {
        var runners = [Runner]()

        if listFormats {
            runners.append(ListFormats())
        }

        if let input {
            try runners.insert(Create(input: input, output: output, type: type), at: 0)
        }

        if runners.isEmpty {
            runners.append(PrintHelpMessage(helpMessage))
        }

        self.runners = runners
    }

    public func run() throws {
        for runner in runners {
            try runner.run()
        }
    }
}
