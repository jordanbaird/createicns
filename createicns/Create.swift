//===----------------------------------------------------------------------===//
//
// Create.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import Cocoa
import Prism

@main
struct Create: ParsableCommand {
  @Argument(
    help: """
      An image file from which to create an icon. \
      This must be a square image.
      """)
  var input: String
  
  @Argument(
    help: """
      The output path of the icon. The path must have the icns extension. If \
      no output is provided, the icon will be saved in the same directory as \
      the input.
      """)
  var output: String?
  
  func run() throws {
    // If no output was provided, use the input.
    let output: String = {
      if let output = self.output {
        return output
      }
      
      // Replace the input extension with the 'icns' extension.
      return URL(fileURLWithPath: input)
        .deletingPathExtension()
        .appendingPathExtension("icns")
        .path
    }()
    
    guard URL(fileURLWithPath: output).pathExtension == "icns" else {
      throw CreationError("Output path must have icns extension.")
    }
    
    guard !FileManager.default.fileExists(atPath: output) else {
      throw CreationError("File '\(output)' already exists.")
    }
    
    print("Creating icon...")
    
    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("icon.iconset")
    
    let image = try getImage(from: input)
    
    let iconSet = IconSet(image: image, url: tempURL)
    try iconSet.write()
    
    let iconUtil = IconUtil(iconSet: tempURL)
    try iconUtil.run()
    
    // Copying the item seems to be faster than moving it, so use that.
    // Force-unwraps are safe here, as 'run()' has been called.
    try FileManager.default.copyItem(
      at: iconUtil.iconURL!,
      to: .init(fileURLWithPath: output))
    try FileManager.default.removeItem(at: iconUtil.iconURL!)
    try iconSet.remove()
    
    print("Icon successfully created.".ansiGreen)
  }
}

extension Create {
  func isDirectory(_ url: URL) -> Bool {
    guard
      let resourceValues = try? url.resourceValues(
        forKeys: [.isDirectoryKey]),
      let isDirectory = resourceValues.isDirectory
    else {
      return false
    }
    return isDirectory
  }
  
  func getImage(from path: String) throws -> NSImage {
    let url = URL(fileURLWithPath: path)
    do {
      let imageData = try Data(contentsOf: url)
      
      guard let image = NSImage(data: imageData) else {
        throw CreationError("File is not a valid image format.")
      }
      
      guard image.size.width == image.size.height else {
        throw CreationError("Image must be square.")
      }
      
      return image
    } catch let error as CreationError {
      throw error
    } catch {
      throw CreationError("Invalid image.")
    }
  }
}
