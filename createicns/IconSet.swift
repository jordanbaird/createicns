//===----------------------------------------------------------------------===//
//
// IconSet.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Cocoa

/// Represents an 'iconset' file.
struct IconSet {
  typealias ImageDimensions = (width: CGFloat, height: CGFloat, name: String)
  
  private let dimensions: [ImageDimensions] = [
    (16,   16,   "16x16"),
    (32,   32,   "16x16@2x"),
    (32,   32,   "32x32"),
    (64,   64,   "32x32@2x"),
    (128,  128,  "128x128"),
    (256,  256,  "128x128@2x"),
    (256,  256,  "256x256"),
    (512,  512,  "256x256@2x"),
    (512,  512,  "512x512"),
    (1024, 1024, "512x512@2x")
  ]
  
  let image: NSImage
  
  let url: URL
  
  init(image: NSImage, url: URL) {
    self.image = image
    self.url = url
  }
  
  func write() throws {
    try _write(url)
  }
  
  func write(to url: URL) throws {
    try _write(url)
  }
  
  private func _write(_ url: URL) throws {
    try FileManager.default.createDirectory(
      at: url,
      withIntermediateDirectories: true)
    
    for dimension in dimensions {
      try createImageFile(
        from: image,
        size: .init(width: dimension.width, height: dimension.height),
        output: url.appendingPathComponent("icon" + dimension.name + ".png"))
    }
    
    func createImageFile(from image: NSImage, size: NSSize, output: URL) throws {
      let size = NSSize(width: size.width / 2, height: size.height / 2)
      let newImage = NSImage(size: size)
      
      newImage.lockFocus()
      image.draw(
        in: .init(origin: .zero, size: size),
        from: .init(origin: .zero, size: image.size),
        operation: .sourceOver,
        fraction: 1)
      newImage.unlockFocus()
      
      let rep = NSBitmapImageRep(data: newImage.tiffRepresentation!)
      guard let pngData = rep?.representation(using: .png, properties: [:]) else {
        throw CreationError("Could not create png data for iconset.")
      }
      try pngData.write(to: output)
    }
  }
  
  func remove() throws {
    try _remove(url)
  }
  
  func remove(at url: URL) throws {
    try _remove(url)
  }
  
  private func _remove(_ url: URL) throws {
    try FileManager.default.removeItem(at: url)
  }
}
