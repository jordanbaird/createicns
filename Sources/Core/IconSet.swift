//
// IconSet.swift
// createicns
//

import Foundation

/// Represents an 'iconset' file.
public struct IconSet {
    public let icons: [Icon]

    public init(image: Image) {
        self.icons = Dimension.all.map { dimension in
            Icon(image: image, dimension: dimension)
        }
    }

    public func write(to url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        for icon in icons {
            try icon.writeInto(directory: url)
        }
    }
}

extension IconSet {
    public struct Dimension: CustomStringConvertible {
        public let length: Int
        public let scale: Int

        public var size: CGSize {
            CGSize(width: length * scale, height: length * scale)
        }

        public var scaleDescriptor: String {
            scale == 1 ? "" : "@\(scale)x"
        }

        public var description: String {
            "\(length)x\(length)\(scaleDescriptor)"
        }

        public init(length: Int, scale: Int) {
            self.length = length
            self.scale = scale
        }

        public static let all: [Self] = [16, 32, 128, 256, 512].reduce(into: []) { dimensions, length in
            dimensions.append(contentsOf: [
                Self(length: length, scale: 1),
                Self(length: length, scale: 2),
            ])
        }
    }
}

extension IconSet {
    public struct Icon {
        public let image: Image
        public let dimension: Dimension

        public init(image: Image, dimension: Dimension) {
            self.image = image
            self.dimension = dimension
        }

        public func writeInto(directory url: URL) throws {
            let verifier = FileVerifier(url: url)
            guard
                verifier.fileExists,
                verifier.isDirectory
            else {
                throw CreationError.directoryDoesNotExist(verifier)
            }
            guard let image = image.resized(to: dimension.size) else {
                throw CreationError.resizeFailure
            }
            try image.urlDestination(
                forURL: url.appendingPathComponent("icon_\(dimension).png"),
                type: .png
            ).write()
        }
    }
}
