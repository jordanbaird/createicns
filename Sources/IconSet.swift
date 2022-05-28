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
  struct Dimension {
    let width: CGFloat
    let height: CGFloat
    let suffix: String
    
    func createIcon(from image: NSImage) throws -> Icon {
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
      
      return Icon(data: pngData, suffix: suffix)
    }
  }
  
  struct Icon {
    let data: Data
    let suffix: String
    
    func write(to url: URL) throws {
      do {
        try data.write(to: url.appendingPathComponent("icon_" + suffix + ".png"))
      } catch {
        throw CreationError(error.localizedDescription)
      }
    }
  }
  
  private static let dimensions: [Dimension] = [
    .init(width: 16, height: 16, suffix: "16x16"),
    .init(width: 32, height: 32, suffix: "16x16@2x"),
    .init(width: 32, height: 32, suffix: "32x32"),
    .init(width: 64, height: 64, suffix: "32x32@2x"),
    .init(width: 128, height: 128, suffix: "128x128"),
    .init(width: 256, height: 256, suffix: "128x128@2x"),
    .init(width: 256, height: 256, suffix: "256x256"),
    .init(width: 512, height: 512, suffix: "256x256@2x"),
    .init(width: 512, height: 512, suffix: "512x512"),
    .init(width: 1024, height: 1024, suffix: "512x512@2x")
  ]
  
  let icons: [Icon]
  
  init(image: NSImage) throws {
    icons = try Self.dimensions.map {
      try $0.createIcon(from: image)
    }
  }
  
  func write(to url: URL) throws {
    do {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    } catch {
      throw CreationError(error.localizedDescription)
    }
    for icon in icons {
      try icon.write(to: url)
    }
  }
  
  func remove(at url: URL) {
    try? FileManager.default.removeItem(at: url)
  }
}
