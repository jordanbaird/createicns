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
    configuration.version = "0.0.4"
    return configuration
  }()

  @Argument(help: .input)
  var input: String
  @Argument(help: .output)
  var output: String?
  @Flag(name: .iconSet, help: .isIconset)
  var isIconset = false

  private var correctExtension: String {
    isIconset ? "iconset" : "icns"
  }

  private var correctOutput: URL {
    if let output {
      return .init(fileURLWithPath: output)
    } else {
      return .init(fileURLWithPath: input)
        .deletingPathExtension()
        .appendingPathExtension(correctExtension)
    }
  }

  private var successMessage: Prism {
    Prism {
      ForegroundColor(.green) {
        if isIconset {
          "Iconset successfully created."
        } else {
          "Icon successfully created."
        }
      }
    }
  }

  func run() throws {
    let output = correctOutput

    do {
      try verifyOutput(output)

      let iconSet = try IconSet(image: getImage(from: input))

      if isIconset {
        try iconSet.write(to: output)
      } else {
        try IconUtil(iconSet: iconSet).run(writingTo: output)
      }
    } catch {
      throw CreationError(error)
    }

    print(successMessage)
  }
}

extension Create {
  func getImage(from path: String) throws -> NSImage {
    let url = URL(fileURLWithPath: path)
    let imageData = try Data(contentsOf: url)
    guard let image = NSImage(data: imageData) else {
      throw CreationError.invalidImageFormat
    }
    guard image.size.width == image.size.height else {
      throw CreationError.invalidDimensions
    }
    return image
  }

  func verifyPathExtension(for url: URL) throws {
    print("Creating '.\(correctExtension)' file...")
    guard url.pathExtension == correctExtension else {
      throw CreationError.missingOutputPathExtension(correctExtension)
    }
  }

  func verifyOutput(_ url: URL) throws {
    guard !FileManager.default.fileExists(atPath: url.path) else {
      throw CreationError.alreadyExists(url)
    }
    try verifyPathExtension(for: url)
  }
}
