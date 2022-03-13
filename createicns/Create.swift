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
    return configuration
  }()
  
  @Argument(help: """
    An image file from which to create an icon. The image's width and height \
    must be equal.
    
    """)
  var input: String
  
  @Argument(help: """
    The output path of the icon. The path must have the 'icns' file extension. \
    If no output is provided, the icon will be saved in the same parent directory \
    as the input.
    
    """)
  var output: String?
  
  @Flag(name: [.customShort("s"), .customLong("iconset")], help: """
    Convert the input into an iconset file instead of icns. If this option is \
    provided, the output path must have the 'iconset' extension instead of 'icns'.
    
    """)
  var convertToIconSet = false
  
  func run() throws {
    let output = getCorrectOutput()
    
    guard !FileManager.default.fileExists(atPath: output.path) else {
      throw CreationError("File '\(output.path)' already exists.")
    }
    
    if convertToIconSet {
      print("Creating iconset...")
    } else {
      print("Creating icon...")
    }
    
    let iconSet = try IconSet(image: try getImage(from: input))
    
    var successMessage: String
    
    if convertToIconSet {
      guard output.pathExtension == "iconset" else {
        throw CreationError("Output path must have '.iconset' extension.")
      }
      try iconSet.write(to: output)
      successMessage = "Iconset successfully created."
    } else {
      guard output.pathExtension == "icns" else {
        throw CreationError("Output path must have '.icns' extension.")
      }
      let iconUtil = IconUtil(iconSet: iconSet)
      try iconUtil.run(writingTo: output)
      successMessage = "Icon successfully created."
    }
    
    print(successMessage.ansiGreen)
  }
}

extension Create {
  func getCorrectOutput() -> URL {
    if let output = output {
      return .init(fileURLWithPath: output)
    } else if convertToIconSet {
      // Replace the input extension with the 'iconset' extension.
      return URL(fileURLWithPath: input)
        .deletingPathExtension()
        .appendingPathExtension("iconset")
    } else {
      // Replace the input extension with the 'icns' extension.
      return URL(fileURLWithPath: input)
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
