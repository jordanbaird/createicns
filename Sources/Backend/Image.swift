//
// Image.swift
// createicns
//

import Foundation
import ImageIO

struct Image {

    // MARK: Types

    private enum ContextDefaults {
        static let bitsPerComponent: Int = 8
        static let colorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        static let bitmapInfo = CGBitmapInfo.byteOrderDefault
        static let alphaInfo = CGImageAlphaInfo.premultipliedLast
        static func makeContext(size: CGSize) throws -> CGContext {
            guard let context = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue | alphaInfo.rawValue)
            else {
                throw ImageCreationError.graphicsContextError
            }
            return context
        }
    }

    private enum ImageCreationError: String, FormattedError {
        case graphicsContextError = "Error with graphics context."
        case pdfDocumentError = "Error with PDF document."
        case invalidImageFormat = "File is not a valid image format."
        case invalidDimensions = "Image width and height must be equal."
        case invalidData = "Invalid image data."
        case invalidSource = "Invalid image source."
        case invalidDestination = "Invalid image destination."

        var message: FormattedText {
            "\("Could not create image", color: .red) — \(rawValue, style: .bold)"
        }
    }

    private class Context {
        var cgImage: CGImage?
    }

    // MARK: Static Properties

    private static let validTypes: [FileType] = {
        let prevalidatedTypes: [FileType] = [
            .pdf,
            .png,
        ]
        let identifiers = CGImageSourceCopyTypeIdentifiers() as Array
        let validTypes = prevalidatedTypes + identifiers.compactMap { value in
            guard let identifier = value as? String else {
                return nil
            }
            return FileType(identifier)
        }
        var seen = Set<FileType>()
        return validTypes.filter { seen.insert($0).inserted }
    }()

    // MARK: Instance Properties

    private let context = Context()

    private let _makeCGImage: () throws -> CGImage

    // MARK: Initializers

    private init(makeCGImage: @escaping () throws -> CGImage) {
        self._makeCGImage = makeCGImage
    }

    init(url: URL) throws {
        let type = FileType(url: url) ?? .image

        if !Self.validTypes.contains(type) {
            throw ImageCreationError.invalidImageFormat
        }

        switch type {
        case .pdf:
            self.init(makeCGImage: {
                guard
                    let document = CGPDFDocument(url as CFURL),
                    let page = document.page(at: 1)
                else {
                    throw ImageCreationError.pdfDocumentError
                }
                let mediaBox = page.getBoxRect(.mediaBox)
                // Scale down images that are > 4x the size of the largest image we need to produce.
                let maxDimension: CGFloat = 1024 * 4
                var scaleFactor = maxDimension / min(mediaBox.width, mediaBox.height)
                if scaleFactor > 2 {
                    scaleFactor = CGFloat(Int(scaleFactor / 2)) * 2
                } else if scaleFactor > 1 {
                    scaleFactor.round()
                } else {
                    scaleFactor = CGFloat(Int(scaleFactor * 10)) / 10
                }
                let destRect = mediaBox.applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
                let context = try ContextDefaults.makeContext(size: destRect.size)
                context.scaleBy(x: scaleFactor, y: scaleFactor)
                context.clear(destRect)
                context.drawPDFPage(page)
                guard let image = context.makeImage() else {
                    throw ImageCreationError.graphicsContextError
                }
                return image
            })
        default:
            self.init(makeCGImage: {
                let options: [CFString: CFTypeRef] = [
                    kCGImageSourceTypeIdentifierHint: type.identifier as CFString,
                    kCGImageSourceShouldCache: kCFBooleanTrue,
                    kCGImageSourceShouldAllowFloat: kCFBooleanTrue,
                ]
                guard
                    let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary),
                    let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary)
                else {
                    throw ImageCreationError.invalidSource
                }
                return cgImage
            })
        }
    }

    // MARK: Instance Methods

    func urlDestination(forURL url: URL, type: FileType) -> URLDestination {
        URLDestination(url: url, image: self, type: type)
    }

    private func makeCGImage() throws -> CGImage {
        let cgImage: CGImage = try {
            if let cgImage = context.cgImage {
                return cgImage
            } else {
                let cgImage = try _makeCGImage()
                context.cgImage = cgImage
                return cgImage
            }
        }()
        guard cgImage.width == cgImage.height else {
            throw ImageCreationError.invalidDimensions
        }
        return cgImage
    }

    func resized(to size: CGSize) -> Self {
        Self(makeCGImage: {
            let context = try ContextDefaults.makeContext(size: size)
            let oldImage = try makeCGImage()

            // Create a new size from the values in the context to be sure we don't
            // cut off the edges of the new image.
            let sizeIntegral = CGSize(width: context.width, height: context.height)

            let rect = CGRect(origin: .zero, size: sizeIntegral)
            context.draw(oldImage, in: rect)

            guard let cgImage = context.makeImage() else {
                throw ImageCreationError.graphicsContextError
            }

            return cgImage
        })
    }
}

// MARK: Image.Destination
extension Image {
    /// An image destination that writes an image to a url.
    struct URLDestination {
        /// The url to write the image to.
        let url: URL
        /// The image to write.
        let image: Image
        /// An identifier specifying the type of image data to write.
        let type: FileType

        /// Creates an image destination that writes the given image to the given
        /// url, using the data type specified by the given type identifier.
        init(url: URL, image: Image, type: FileType) {
            self.url = url
            self.image = image
            self.type = type
        }

        /// Writes the data to the destination's url.
        func write() throws {
            let url = try FileVerifier(options: [!.fileExists]).verify(url: url) as CFURL
            let type = type.identifier as CFString
            guard let destination = CGImageDestinationCreateWithURL(url, type, 1, nil) else {
                throw Image.ImageCreationError.invalidDestination
            }
            let cgImage = try image.makeCGImage()
            CGImageDestinationAddImage(destination, cgImage, nil)
            if !CGImageDestinationFinalize(destination) {
                throw Image.ImageCreationError.invalidDestination
            }
        }
    }
}
