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
  typealias Icon = (data: Data, name: String)
  
  private let dimensions: [(CGFloat, CGFloat, String)] = [
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
  
  private(set) var icons = [Icon]()
  
  init(image: NSImage) throws {
    icons = try dimensions.map {
      try createIcon(from: image, width: $0.0, height: $0.1, name: $0.2)
    }
  }
  
  private func createIcon(
    from image: NSImage,
    width: CGFloat,
    height: CGFloat,
    name: String
  ) throws -> Icon {
    let size = CGSize(width: width / 2, height: height / 2)
    let newImage = NSImage(size: size)
    
    newImage.lockFocus()
    image.draw(
      in: .init(origin: .zero, size: size),
      from: .init(origin: .zero, size: image.size),
      operation: .sourceOver,
      fraction: 1)
    newImage.unlockFocus()
    
    guard
      let tiffRep = newImage.tiffRepresentation,
      let bitmapRep = NSBitmapImageRep(data: tiffRep),
      let pngData = bitmapRep.representation(using: .png, properties: [:])
    else {
      throw CreationError("Could not create data for iconset.")
    }
    
    return Icon(data: pngData, name: name)
  }
  
  func write(to url: URL) throws {
    do {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    } catch {
      throw CreationError(error.localizedDescription)
    }
    for icon in icons {
      do {
        try icon.data.write(to: url.appendingPathComponent("icon_" + icon.name + ".png"))
      } catch {
        throw CreationError(error.localizedDescription)
      }
    }
  }
  
  func remove(at url: URL) {
    try? FileManager.default.removeItem(at: url)
  }
}
