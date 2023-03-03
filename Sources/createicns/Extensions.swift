//
// Extensions.swift
// createicns
//

import ArgumentParser
import Cocoa

// MARK: - NameSpecification

extension NameSpecification {
    static let iconSet: Self = [.customShort("s"), .customLong("iconset")]
}

// MARK: - NSImage

extension NSImage {
    func resized(to newSize: NSSize) -> NSImage {
        NSImage(size: newSize, flipped: false) { [self] dstRect in
            draw(
                in: dstRect,
                from: NSRect(origin: .zero, size: size),
                operation: .sourceOver,
                fraction: 1
            )
            return true
        }
    }
}
