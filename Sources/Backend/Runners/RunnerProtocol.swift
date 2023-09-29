//
//  RunnerProtocol.swift
//  createicns
//

/// A type that encapsulates the behavior of a specific part of the `createicns` tool.
protocol Runner {
    /// Performs validation on the runner's data and state.
    func validate() throws
    /// Performs the action designated by the runner.
    func run() throws
}

extension Runner {
    func validate() { }
}
