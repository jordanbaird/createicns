//===----------------------------------------------------------------------===//
//
// NSImage+extension.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Cocoa

extension NSImage {
  func resized(to newSize: NSSize) -> NSImage {
    .init(size: newSize, flipped: false) { [self] dstRect in
      draw(in: dstRect, from: .init(origin: .zero, size: size), operation: .sourceOver, fraction: 1)
      return true
    }
  }
}
