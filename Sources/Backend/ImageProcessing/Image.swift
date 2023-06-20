//
// Image.swift
// createicns
//

import CoreGraphics
import Foundation
import ImageIO
import SwiftDraw

private func getScaleFactor(forSize size: CGSize, minDimension: CGFloat, maxDimension: CGFloat) -> CGFloat {
    let minDimension = max(min(size.width, size.height), minDimension)
    var scaleFactor = maxDimension / minDimension
    if scaleFactor > 2 {
        scaleFactor = CGFloat(Int(scaleFactor / 2)) * 2
    } else if scaleFactor > 1 {
        scaleFactor.round()
    } else {
        scaleFactor = CGFloat(Int(scaleFactor * 10)) / 10
    }
    return scaleFactor
}

/// A type that contains writable image data.
struct Image {

    // MARK: Types

    /// Default values used to create a graphics context.
    private enum ContextDefaults {
        static let bitsPerComponent: Int = 8
        static let colorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        static let bitmapInfo = CGBitmapInfo.byteOrderDefault
        static let alphaInfo = CGImageAlphaInfo.premultipliedLast

        /// Creates and returns a graphics context of the given size using the values
        /// defined on this type.
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

    /// An error that can be thrown during the creation of an image.
    private enum ImageCreationError: String, FormattedError {
        case graphicsContextError = "Error with graphics context."
        case pdfDocumentError = "Error with PDF document."
        case svgCreationError = "Error creating image data from SVG."
        case invalidImageFormat = "File is not a valid image format."
        case invalidData = "Invalid image data."
        case invalidSource = "Invalid image source."
        case invalidDestination = "Invalid image destination."

        var message: FormattedText {
            "\("Could not create image", color: .red) — \(rawValue, style: .bold)"
        }
    }

    // MARK: Static Properties

    /// The valid file types for an image.
    static let validTypes: Set<FileType> = {
        let prevalidatedTypes: Set<FileType> = [
            .pdf,
            .svg,
        ]
        guard let identifiers = CGImageSourceCopyTypeIdentifiers() as? [String] else {
            return prevalidatedTypes
        }
        return identifiers.reduce(into: prevalidatedTypes) { result, identifier in
            result.insert(FileType(identifier))
        }
    }()

    // MARK: Instance Properties

    private let cgImage: CGImage

    var width: CGFloat {
        CGFloat(cgImage.width)
    }

    var height: CGFloat {
        CGFloat(cgImage.height)
    }

    // MARK: Initializers

    private init(cgImage: CGImage) {
        self.cgImage = cgImage
    }

    /// Creates an image by reading data from the given url.
    init(url: URL) throws {
        guard
            let type = FileType(url: url),
            Self.validTypes.contains(type)
        else {
            throw ImageCreationError.invalidImageFormat
        }

        switch type {
        case .pdf:
            guard
                let document = CGPDFDocument(url as CFURL),
                let page = document.page(at: 1)
            else {
                throw ImageCreationError.pdfDocumentError
            }
            let mediaBox = page.getBoxRect(.mediaBox)
            // 1024x1024 is the size of the largest image we need to produce.
            // Scale down if more than 4 times larger.
            let scaleFactor = getScaleFactor(forSize: mediaBox.size, minDimension: 0, maxDimension: 1024 * 4)
            let destRect = mediaBox.applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
            let context = try ContextDefaults.makeContext(size: destRect.size)
            context.scaleBy(x: scaleFactor, y: scaleFactor)
            context.clear(destRect)
            context.drawPDFPage(page)
            guard let cgImage = context.makeImage() else {
                throw ImageCreationError.graphicsContextError
            }
            self.init(cgImage: cgImage)
        case .svg:
            let svg = try OutputHandle.standardError.redirect {
                guard let svg = SVG(fileURL: url) else {
                    throw ImageCreationError.svgCreationError
                }
                return svg
            }
            // 1024x1024 is the size of the largest image we need to produce.
            // Scale up if smaller. Scale down if more than 4 times larger.
            let scaleFactor = getScaleFactor(forSize: svg.size, minDimension: 1024, maxDimension: 1024 * 4)
            let data = try svg.pngData(size: svg.size, scale: scaleFactor)
            let options: [CFString: CFTypeRef] = [
                kCGImageSourceTypeIdentifierHint: FileType.png.identifier as CFString,
                kCGImageSourceShouldCache: kCFBooleanTrue,
                kCGImageSourceShouldAllowFloat: kCFBooleanTrue,
            ]
            guard
                let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary),
                let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary)
            else {
                throw ImageCreationError.invalidSource
            }
            self.init(cgImage: cgImage)
        default:
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
            self.init(cgImage: cgImage)
        }
    }

    // MARK: Instance Methods

    /// Returns an image destination for writing data of the given type to the given url.
    func urlDestination(forURL url: URL, type: FileType) -> URLDestination {
        URLDestination(url: url, image: self, type: type)
    }

    /// Returns an image that is resized to the given size when it is drawn.
    func resized(to size: CGSize) throws -> Self {
        let context = try ContextDefaults.makeContext(size: size)

        // Create a new size from the values in the context to be sure we don't
        // cut off the edges of the new image.
        let sizeIntegral = CGSize(width: context.width, height: context.height)

        let rect = CGRect(origin: .zero, size: sizeIntegral)
        context.draw(cgImage, in: rect)

        guard let cgImage = context.makeImage() else {
            throw ImageCreationError.graphicsContextError
        }

        return Self(cgImage: cgImage)
    }
}

// MARK: Image.URLDestination
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

        /// Writes the image's data to the destination's url.
        func write() throws {
            let url = try FileVerifier(options: [.fileExists.inverted])
                .verify(info: FileInfo(url: url))
                .url as CFURL
            let image = image.cgImage
            let type = type.identifier as CFString

            guard let destination = CGImageDestinationCreateWithURL(url, type, 1, nil) else {
                throw Image.ImageCreationError.invalidDestination
            }

            CGImageDestinationAddImage(destination, image, nil)
            if !CGImageDestinationFinalize(destination) {
                throw Image.ImageCreationError.invalidDestination
            }
        }
    }
}
