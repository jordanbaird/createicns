//
// ImageContext.swift
// createicns
//

import CoreGraphics

protocol ImageContext {
    var size: CGSize { get }
    var bitsPerComponent: Int { get }
}

extension ImageContext {
    var bitsPerComponent: Int { 8 }
}

struct PDFContext: ImageContext {
    let size: CGSize
}
