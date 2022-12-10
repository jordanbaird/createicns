//===----------------------------------------------------------------------===//
//
// CreationError.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Foundation
import Prism

struct CreationError: LocalizedError {
  let message: String

  var errorDescription: String? {
    message.foregroundColor(.red)
  }

  init(_ message: String) {
    self.message = message
  }

  init<E: Error>(_ error: E) {
    if let error = error as? Self {
      self = error
    } else {
      self.init(error.localizedDescription)
    }
  }

  init(_ data: Data) {
    guard let message = String(data: data, encoding: .utf8) else {
      self = .unknownError
      return
    }
    self.init(message)
  }
}

extension CreationError {
  static func alreadyExists(_ url: URL) -> Self {
    .init("'\(url.path)' already exists.")
  }

  static func doesNotExist(_ url: URL) -> Self {
    .init("'\(url.path)' does not exist.")
  }

  static func notADirectory(_ url: URL) -> Self {
    .init("'\(url.path)' is not a directory.")
  }

  static func missingOutputPathExtension(_ pathExtension: String) -> Self {
    let pathExtension = pathExtension.trimmingCharacters(in: ["."])
    return .init("Output path must have '.\(pathExtension)' extension.")
  }

  static var unknownError: Self {
    .init("An unknown error occurred.")
  }

  static var invalidImageFormat: Self {
    .init("File is not a valid image format.")
  }

  static var invalidDimensions: Self {
    .init("Image width and height must be equal.")
  }

  static var invalidData: Self {
    .init("Could not create data for iconset.")
  }
}
