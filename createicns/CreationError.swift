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
  static let standard = Self("An error occurred.")
  
  let message: String
  
  var errorDescription: String? { message.ansiRed }
  
  init(_ message: String) {
    self.message = message
  }
}
