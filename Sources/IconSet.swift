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
  typealias IconDimensions = (width: CGFloat, height: CGFloat, stringRepresentation: String)
  
  typealias Icon = (data: Data, name: String)
  
  private let dimensions: [IconDimensions] = [
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
  
  var icons: [Icon] { _icons }
  
  private var _icons = [Icon]()
  
  let image: NSImage
  
  init(image: NSImage) throws {
    self.image = image
    _icons = try dimensions.map {
      try createImageFile(
        from: image,
        size: .init(width: $0.width, height: $0.height),
        name: $0.stringRepresentation)
    }
  }
  
  private func createImageFile(
    from image: NSImage,
    size: NSSize,
    name: String
  ) throws -> Icon {
    let size = NSSize(
      width: size.width / 2,
      height: size.height / 2)
    
    let newImage = NSImage(size: size)
    
    newImage.lockFocus()
    image.draw(
      in: .init(origin: .zero, size: size),
      from: .init(origin: .zero, size: image.size),
      operation: .sourceOver,
      fraction: 1)
    newImage.unlockFocus()
    
    let rep = NSBitmapImageRep(data: newImage.tiffRepresentation!)
    guard let pngData = rep?.representation(
      using: .png,
      properties: [:])
    else {
      throw CreationError("Could not create png data for iconset.")
    }
    return Icon(data: pngData, name: name)
  }
  
  func write(to url: URL) throws {
    do {
      try FileManager.default.createDirectory(
        at: url,
        withIntermediateDirectories: true)
    } catch {
      throw CreationError(error.localizedDescription)
    }
    for icon in icons {
      do {
        try icon.data.write(
          to: url.appendingPathComponent(
            "icon_" + icon.name + ".png"))
      } catch {
        throw CreationError(error.localizedDescription)
      }
    }
  }
  
  func remove(at url: URL) {
    try? FileManager.default.removeItem(at: url)
  }
}
