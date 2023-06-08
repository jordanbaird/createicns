//
// RunnerProtocol.swift
// createicns
//

/// A type that encapsulates the behavior of a specific part of the command.
protocol Runner {
    /// Performs the action designated by the runner.
    func run() throws
}
