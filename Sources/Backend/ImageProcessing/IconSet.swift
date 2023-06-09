//
// IconSet.swift
// createicns
//

import Foundation

/// Represents an iconset file.
struct IconSet {
    /// The individual icons contained within the iconset.
    let icons: [Icon]

    /// Creates an iconset for the given image.
    init(image: Image) {
        self.icons = Dimension.all.map { dimension in
            Icon(image: image, dimension: dimension)
        }
    }

    /// Writes the contents of the iconset to the given output url, creating it if necessary.
    func write(to outputURL: URL) throws {
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
        for icon in icons {
            try icon.urlDestination(for: outputURL).write()
        }
    }
}

extension IconSet {
    /// Sizing and scaling information used to create the various icons in an iconset.
    struct Dimension: CustomStringConvertible {
        /// The length of each side of the icon.
        let length: Int

        /// The scaling factor of the icon.
        let scale: Int

        /// A size calculated by multiplying `length` by `scale`.
        var size: CGSize {
            CGSize(width: length * scale, height: length * scale)
        }

        /// A description of `scale`, used when constructing the icon's filename.
        var scaleDescription: String {
            scale == 1 ? "" : "@\(scale)x"
        }

        /// A description of the sizing and scaling information contained in this instance,
        /// used when constructing the icon's filename.
        var description: String {
            "\(length)x\(length)\(scaleDescription)"
        }

        /// Creates an instance with the given length and scaling factor.
        init(length: Int, scale: Int) {
            self.length = length
            self.scale = scale
        }

        /// An array of all required sizes and scales for the icons in an iconset.
        static let all: [Self] = [16, 32, 128, 256, 512].reduce(into: []) { dimensions, length in
            dimensions.append(contentsOf: [
                Self(length: length, scale: 1),
                Self(length: length, scale: 2),
            ])
        }
    }
}

extension IconSet {
    /// An individual icon in an iconset.
    struct Icon {
        /// The image used to create the icon.
        let image: Image

        /// Sizing and scaling information used to draw the icon's image at the required size.
        let dimension: Dimension

        /// Creates an icon with the given image and dimension.
        init(image: Image, dimension: Dimension) {
            self.image = image
            self.dimension = dimension
        }

        /// Returns the appropriate output url for the icon, in relation to the given directory.
        ///
        /// The icon's `dimension` is used to construct the icon's filename.
        func outputURL(for directory: URL) -> URL {
            directory.appendingPathComponent("icon_\(dimension).png")
        }

        /// Returns an image destination for writing the icon's data into the given directory.
        func urlDestination(for directory: URL) -> Image.URLDestination {
            image
                .resized(to: dimension.size)
                .urlDestination(forURL: outputURL(for: directory), type: .png)
        }
    }
}