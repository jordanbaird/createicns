//
//  Iconset.swift
//  createicns
//

import Foundation

/// A representation of an iconset file.
struct Iconset {
    /// The individual icons contained within the iconset.
    let icons: [Icon]

    /// Creates an iconset for the given image.
    init(image: Image) {
        self.icons = Dimension.all.map { dimension in
            Icon(image: image, dimension: dimension)
        }
    }

    /// Validates the dimensions of every icon in the iconset, ensuring that the widths
    /// and heights are equal.
    func validateDimensions() throws {
        for icon in icons {
            try icon.validateDimensions()
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

extension Iconset {
    /// Sizing and scaling information used to create the icons in an iconset.
    struct Dimension: CustomStringConvertible {
        /// The length of each side of the icon.
        var length: Int

        /// The scaling factor of the icon.
        var scale: Int

        /// A size calculated by multiplying the dimension's length by its scale.
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

        /// An array of all required sizes and scales for the icons in an iconset.
        static let all: [Self] = [16, 32, 128, 256, 512].reduce(into: []) { dimensions, length in
            dimensions.append(contentsOf: [
                Self(length: length, scale: 1),
                Self(length: length, scale: 2),
            ])
        }
    }
}

extension Iconset {
    /// An individual icon in an iconset.
    struct Icon {
        /// An error that can occur during the validation of an icon.
        enum ValidationError: String, FormattedError {
            case invalidDimensions = "Image width and height must be equal."

            var errorMessage: String {
                "Invalid icon".formatted(color: .red) + " - " + rawValue.formatted(style: .bold)
            }
        }

        /// The image used to create the icon.
        var image: Image

        /// Sizing and scaling information used to draw the icon's image at the required size.
        var dimension: Dimension

        /// Validates the dimensions of the icon, ensuring that the width and height are equal.
        func validateDimensions() throws {
            guard image.width == image.height else {
                throw ValidationError.invalidDimensions
            }
        }

        /// Returns the appropriate output url for the icon, in relation to the given directory.
        ///
        /// The icon's `dimension` is used to construct the icon's filename.
        func outputURL(for directory: URL) -> URL {
            directory.appendingPathComponent("icon_\(dimension).png")
        }

        /// Returns an image destination for writing the icon's data into the given directory.
        func urlDestination(for directory: URL) throws -> Image.URLDestination {
            try image
                .resized(to: dimension.size)
                .urlDestination(forURL: outputURL(for: directory), type: .png)
        }
    }
}
