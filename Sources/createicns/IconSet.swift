//
// IconSet.swift
// createicns
//

import Cocoa

/// Represents an 'iconset' file.
struct IconSet {
    private static var dimensions: [Dimension] {
        [16, 32, 128, 256, 512].flatMap { dimension in
            [dimension, dimension * 2]
        }
    }

    let icons: [Icon]

    init(image: NSImage) throws {
        icons = try Self.dimensions.map { dimension in
            try .init(image: image, dimension: dimension)
        }
    }

    func write(to url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        for icon in icons {
            try icon.writeInto(directory: url)
        }
    }
}

extension IconSet {
    struct Dimension {
        let d: Int
        let scale: Int

        var size: NSSize {
            .init(width: d * scale, height: d * scale)
        }

        var suffix: String {
            "\(d)x\(d)\(scale == 1 ? "" : "@\(scale)x")"
        }

        init(d: Int, scale: Int) {
            self.d = d
            self.scale = scale
        }
    }
}

extension IconSet.Dimension {
    static func * (lhs: Self, rhs: Int) -> Self {
        .init(d: lhs.d, scale: lhs.scale * rhs)
    }
}

extension IconSet.Dimension: ExpressibleByIntegerLiteral {
    init(integerLiteral value: IntegerLiteralType) {
        self.init(d: value, scale: 1)
    }
}

extension IconSet {
    struct Icon {
        let data: Data
        let suffix: String

        init(image: NSImage, dimension: Dimension) throws {
            guard
                let tiffRep = image.resized(to: dimension.size).tiffRepresentation,
                let bitmapRep = NSBitmapImageRep(data: tiffRep),
                let pngData = bitmapRep.representation(using: .png, properties: [:])
            else {
                throw CreationError.invalidData
            }
            data = pngData
            suffix = dimension.suffix
        }

        func writeInto(directory url: URL) throws {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
                throw CreationError.doesNotExist(url)
            }
            guard isDirectory.boolValue else {
                throw CreationError.notADirectory(url)
            }
            try data.write(to: url.appendingPathComponent("icon_" + suffix + ".png"))
        }
    }
}
