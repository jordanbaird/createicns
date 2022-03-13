//===----------------------------------------------------------------------===//
//
// IconUtil.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Foundation

/// Wraps the `iconutil` command line utility.
class IconUtil {
  private let path = "/usr/bin/iconutil"
  
  let iconSetURL: URL
  
  var iconURL: URL? {
    _iconURL
  }
  
  private var _iconURL: URL?
  
  init(iconSet url: URL) {
    iconSetURL = url
  }
  
  func run() throws {
    let process = Process()
    let pipe = Pipe()
    
    process.standardOutput = pipe
    process.standardError = pipe
    process.arguments = ["-c", "icns", iconSetURL.lastPathComponent]
    
    if #available(macOS 10.13, *) {
      process.executableURL = URL(fileURLWithPath: path)
      process.currentDirectoryURL = iconSetURL.deletingLastPathComponent()
      do {
        try process.run()
      } catch {
        throw CreationError("Could not execute icon creation process.")
      }
    } else {
      process.launchPath = path
      process.currentDirectoryPath = iconSetURL.deletingLastPathComponent().path
      process.launch()
    }
    process.waitUntilExit()
    
    let data: Data? = {
      let fileHandle = pipe.fileHandleForReading
      if #available(macOS 10.15.4, *) {
        return try? fileHandle.readToEnd()
      } else {
        let data = fileHandle.readDataToEndOfFile()
        return data.isEmpty ? nil : data
      }
    }()
    
    // 'iconutil' only returns data if something went wrong.
    if let data = data {
      throw CreationError(.init(data: data, encoding: .utf8)!)
    }
    
    _iconURL = iconSetURL
      .deletingPathExtension()
      .appendingPathExtension("icns")
  }
}
