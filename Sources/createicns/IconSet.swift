//
// IconSet.swift
// createicns
//

import Foundation

/// Represents an 'iconset' file.
struct IconSet {
    private static var dimensions: [Dimension] {
        [16, 32, 128, 256, 512].flatMap { dimension in
            [dimension, dimension * 2] // FIXME: What does this even mean?
        }
    }

    let icons: [Icon]

    init(image: Image) throws {
        self.icons = try Self.dimensions.map { dimension in
            try Icon(image: image, dimension: dimension)
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

        var size: CGSize {
            CGSize(width: d * scale, height: d * scale)
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
        Self(d: lhs.d, scale: lhs.scale * rhs)
    }
}

extension IconSet.Dimension: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        self.init(d: value, scale: 1)
    }
}

extension IconSet {
    struct Icon {
        let image: Image
        let suffix: String

        init(image: Image, dimension: Dimension) throws {
            guard let image = image.resized(to: dimension.size) else {
                throw CreationError.resizeFailure
            }
            self.image = image
            self.suffix = dimension.suffix
        }

        func writeInto(directory url: URL) throws {
            let verifier = FileVerifier(url: url)
            guard
                verifier.fileExists,
                verifier.isDirectory
            else {
                throw CreationError.directoryDoesNotExist(verifier)
            }
            try image.urlDestination(
                forURL: url.appendingPathComponent("icon_" + suffix + ".png"),
                type: .png
            ).write()
        }
    }
}
