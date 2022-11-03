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
  static var configuration: CommandConfiguration = {
    var configuration = CommandConfiguration()
    configuration.commandName = "createicns"
    configuration.version = "0.0.3"
    return configuration
  }()
  
  @Argument(help: .input)
  var input: String
  @Argument(help: .output)
  var output: String?
  @Flag(name: [.customShort("s"), .customLong("iconset")], help: .isIconset)
  var isIconset = false
  
  func run() throws {
    let output = getCorrectOutput()
    
    guard !FileManager.default.fileExists(atPath: output.path) else {
      throw CreationError("File '\(output.path)' already exists.")
    }
    
    let iconSet = {
      try IconSet(image: getImage(from: input))
    }
    
    if isIconset {
      print("Creating iconset...")
      guard output.pathExtension == "iconset" else {
        throw CreationError("Output path must have '.iconset' extension.")
      }
      try iconSet().write(to: output)
      print("Iconset successfully created.".foregroundColor(.green))
    } else {
      print("Creating icon...")
      guard output.pathExtension == "icns" else {
        throw CreationError("Output path must have '.icns' extension.")
      }
      try IconUtil(iconSet: iconSet()).run(writingTo: output)
      print("Icon successfully created.".foregroundColor(.green))
    }
  }
}

extension Create {
  func getCorrectOutput() -> URL {
    if let output {
      return .init(fileURLWithPath: output)
    } else if isIconset {
      // Replace the input extension with the 'iconset' extension.
      return .init(fileURLWithPath: input)
        .deletingPathExtension()
        .appendingPathExtension("iconset")
    } else {
      // Replace the input extension with the 'icns' extension.
      return .init(fileURLWithPath: input)
        .deletingPathExtension()
        .appendingPathExtension("icns")
    }
  }
  
  func getImage(from path: String) throws -> NSImage {
    let url = URL(fileURLWithPath: path)
    do {
      let imageData = try Data(contentsOf: url)
      guard let image = NSImage(data: imageData) else {
        throw CreationError("File is not a valid image format.")
      }
      guard image.size.width == image.size.height else {
        throw CreationError("Image width and height must be equal.")
      }
      return image
    } catch let error as CreationError {
      throw error
    } catch {
      throw CreationError(error.localizedDescription)
    }
  }
}
