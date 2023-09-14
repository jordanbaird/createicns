//
//  PrintHelpMessage.swift
//  createicns
//

/// A runner that prints the command's help message.
struct PrintHelpMessage: Runner {
    private let helpMessage: () -> String

    init(_ helpMessage: @escaping () -> String) {
        self.helpMessage = helpMessage
    }

    func run() {
        print(helpMessage())
    }
}
