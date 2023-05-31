//
// IconSet.swift
// createicns
//

import Foundation

/// Represents an 'iconset' file.
struct IconSet {
    let icons: [Icon]

    init(image: Image) {
        self.icons = Dimension.all.map { dimension in
            Icon(image: image, dimension: dimension)
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
    struct Dimension: CustomStringConvertible {
        let length: Int
        let scale: Int

        var size: CGSize {
            CGSize(width: length * scale, height: length * scale)
        }

        var scaleDescriptor: String {
            scale == 1 ? "" : "@\(scale)x"
        }

        var description: String {
            "\(length)x\(length)\(scaleDescriptor)"
        }

        init(length: Int, scale: Int) {
            self.length = length
            self.scale = scale
        }

        static let all: [Self] = [16, 32, 128, 256, 512].reduce(into: []) { dimensions, length in
            dimensions.append(contentsOf: [
                Self(length: length, scale: 1),
                Self(length: length, scale: 2),
            ])
        }
    }
}

extension IconSet {
    struct Icon {
        enum IconError: String, LocalizedError {
            case resizeFailure = "Couldn't resize icon."

            var errorDescription: String? {
                rawValue
            }
        }

        let image: Image

        let dimension: Dimension

        init(image: Image, dimension: Dimension) {
            self.image = image
            self.dimension = dimension
        }

        func writeInto(directory url: URL) throws {
            let verifier = FileVerifier(url: url)
            guard
                verifier.fileExists,
                verifier.isDirectory
            else {
                throw verifier.directoryDoesNotExistError()
            }
            guard let image = image.resized(to: dimension.size) else {
                throw IconError.resizeFailure
            }
            try image.urlDestination(
                forURL: url.appendingPathComponent("icon_\(dimension).png"),
                type: .png
            ).write()
        }
    }
}
