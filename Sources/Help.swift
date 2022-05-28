//===----------------------------------------------------------------------===//
//
// Help.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import ArgumentParser

extension ArgumentHelp {
  static let input: Self = """
    An image file from which to create an icon. The image's width and \
    height must be equal.\n
    """
  
  static let output: Self = """
    The output path of the icon. The path must have the 'icns' file \
    extension. If no output is provided, the icon will be saved in the \
    same parent directory as the input.\n
    """
  
  static let isIconset: Self = """
    Convert the input into an iconset file instead of icns. If this option \
    is provided, the output path must have the 'iconset' extension instead \
    of 'icns'.\n
    """
}
