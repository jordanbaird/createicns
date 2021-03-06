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
}
