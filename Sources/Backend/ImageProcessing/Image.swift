//
//  Image.swift
//  createicns
//

import CoreGraphics
import Foundation
import ImageIO
import SwiftDraw

/// A container for writable image data.
struct Image {

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

    /// The underlying Core Graphics image.
    private let cgImage: CGImage

    /// The image's width in pixels.
    var width: CGFloat { CGFloat(cgImage.width) }

    /// The image's height in pixels.
    var height: CGFloat { CGFloat(cgImage.height) }

    // MARK: Initializers

    /// Creates an image from the given Core Graphics image.
    private init(cgImage: CGImage) {
        self.cgImage = cgImage
    }

    /// Creates an image using data from the given url.
    init(url: URL) throws {
        guard
            let type = FileType(url: url),
            Self.validTypes.contains(type)
        else {
            throw ImageProcessingError.invalidImageFormat
        }

        switch type {
        case .pdf:
            guard
                let document = CGPDFDocument(url as CFURL),
                let page = document.page(at: 1)
            else {
                throw ImageProcessingError.pdfDocumentError
            }
            let mediaBox = page.getBoxRect(.mediaBox)
            // 1024x1024 is the size of the largest image we need to produce;
            // scale down if more than 4 times larger
            let scaleFactor = Self.getScaleFactor(forSize: mediaBox.size, minDimension: 0, maxDimension: 1024 * 4)
            let destRect = mediaBox.applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
            let context = try Self.makeGraphicsContext(size: destRect.size)
            context.scaleBy(x: scaleFactor, y: scaleFactor)
            context.clear(destRect)
            context.drawPDFPage(page)
            guard let cgImage = context.makeImage() else {
                throw ImageProcessingError.graphicsContextError
            }
            self.init(cgImage: cgImage)
        case .svg:
            // HACK: SwiftDraw logs some implementation details to stderr when it finds
            // something in an SVG file it doesn't like; temporarily redirect stderr to
            // an empty file and throw our own error on failure
            let svg = try OutputHandle.standardError.redirect {
                guard let svg = SVG(fileURL: url) else {
                    throw ImageProcessingError.svgCreationError
                }
                return svg
            }
            // 1024x1024 is the size of the largest image we need to produce;
            // scale up if smaller; scale down if more than 4 times larger
            let scaleFactor = Self.getScaleFactor(forSize: svg.size, minDimension: 1024, maxDimension: 1024 * 4)
            let data = try svg.pngData(size: svg.size, scale: scaleFactor)
            let options = Self.getImageSourceOptions(type: .png)
            guard
                let source = CGImageSourceCreateWithData(data as CFData, options),
                let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options)
            else {
                throw ImageProcessingError.invalidSource
            }
            self.init(cgImage: cgImage)
        default:
            let options = Self.getImageSourceOptions(type: type)
            guard
                let source = CGImageSourceCreateWithURL(url as CFURL, options),
                let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options)
            else {
                throw ImageProcessingError.invalidSource
            }
            self.init(cgImage: cgImage)
        }
    }

    // MARK: Static Methods

    /// Returns the appropriate scale factor for an image of the given size, using the
    /// given minimum and maximum dimensions.
    private static func getScaleFactor(forSize size: CGSize, minDimension: CGFloat, maxDimension: CGFloat) -> CGFloat {
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

    /// Returns the appropriate options for a creating `CGImageSource`, using a hint
    /// derived from the given file type.
    private static func getImageSourceOptions(type: FileType) -> CFDictionary {
        let options: [CFString: CFTypeRef] = [
            kCGImageSourceTypeIdentifierHint: type.identifier as CFString,
            kCGImageSourceShouldCache: kCFBooleanTrue,
            kCGImageSourceShouldAllowFloat: kCFBooleanTrue,
        ]
        return options as CFDictionary
    }

    /// Creates and returns a graphics context of the given size.
    private static func makeGraphicsContext(size: CGSize) throws -> CGContext {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            throw ImageProcessingError.invalidColorSpace
        }

        let bitmapInfo = CGBitmapInfo.byteOrderDefault
        let alphaInfo = CGImageAlphaInfo.premultipliedLast

        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue | alphaInfo.rawValue
        ) else {
            throw ImageProcessingError.graphicsContextError
        }

        return context
    }

    // MARK: Instance Methods

    /// Returns an image destination for writing data of the given type to the given url.
    func urlDestination(forURL url: URL, type: FileType) -> URLDestination {
        URLDestination(url: url, image: self, type: type)
    }

    /// Returns an image that is resized to the given size when it is drawn.
    func resized(to size: CGSize) throws -> Self {
        let context = try Self.makeGraphicsContext(size: size)

        // create a new size from the values in the context to be sure we don't
        // cut off the edges of the new image
        let sizeIntegral = CGSize(width: context.width, height: context.height)

        let rect = CGRect(origin: .zero, size: sizeIntegral)
        context.draw(cgImage, in: rect)

        guard let cgImage = context.makeImage() else {
            throw ImageProcessingError.graphicsContextError
        }

        return Self(cgImage: cgImage)
    }
}

// MARK: - URLDestination
extension Image {
    /// An image destination that writes an image to a url.
    struct URLDestination {
        /// The url to write the image to.
        var url: URL

        /// The image to write.
        var image: Image

        /// An identifier specifying the type of image data to write.
        var type: FileType

        /// Writes the image's data to the destination's url.
        func write() throws {
            let info = FileInfo(url: url)

            guard !info.fileExists else {
                throw FileVerificationError.alreadyExists(info.path)
            }

            let url = info.url as CFURL
            let image = image.cgImage
            let type = type.identifier as CFString

            guard let destination = CGImageDestinationCreateWithURL(url, type, 1, nil) else {
                throw ImageProcessingError.invalidDestination
            }

            CGImageDestinationAddImage(destination, image, nil)
            if !CGImageDestinationFinalize(destination) {
                throw ImageProcessingError.invalidDestination
            }
        }
    }
}
