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

        var components: [any FormattingComponent] {
            [
                Passthrough("Could not create image"),
                StripFormatting(components: [
                    Passthrough(" — "),
                    Bold(rawValue),
                ]),
            ]
        }
    }

    private class Context {
        var cgImage: CGImage?
    }

    // MARK: Static Properties

    private static let validTypes: [UTType] = {
        let prevalidatedTypes: [UTType] = [
            .pdf,
            .png,
        ]
        let identifiers = CGImageSourceCopyTypeIdentifiers() as Array
        let validTypes = prevalidatedTypes + identifiers.compactMap { value in
            guard let identifier = value as? String else {
                return nil
            }
            return UTType(identifier)
        }
        var seen = Set<UTType>()
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
        let type = UTType(url: url) ?? .image

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
                let rect = page.getBoxRect(.mediaBox)
                let context = try ContextDefaults.makeContext(size: rect.size)
                context.clear(rect)
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

    func dataDestination(forType type: UTType) -> Destination<Data> {
        Destination.dataDestination(forImage: self, type: type)
    }

    func urlDestination(forURL url: URL, type: UTType) -> Destination<URL> {
        Destination.urlDestination(forURL: url, image: self, type: type)
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
            // CGContext will have converted size's width and height into integers.
            // Create a new size based on the values in the context to be sure we
            // don't cut off the edges of the new image.
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
    struct Destination<Kind> {
        private struct Base {
            private let value: Kind

            init(data: NSMutableData) where Kind == Data {
                self.value = data as Data
            }

            init(url: URL) where Kind == URL {
                self.value = url
            }

            func getData() -> NSMutableData where Kind == Data {
                if let data = value as? NSMutableData {
                    return data
                }
                return NSMutableData(data: value)
            }

            func getURL() -> URL where Kind == URL {
                return value
            }
        }

        private let base: Base

        let image: Image

        let type: UTType

        private var typeIdentifier: CFString {
            type.identifier as CFString
        }

        private init(base: Base, image: Image, type: UTType) {
            self.base = base
            self.image = image
            self.type = type
        }
    }
}

// MARK: Destination<Data>
extension Image.Destination<Data> {
    static func dataDestination(forImage image: Image, type: UTType) -> Self {
        Self(base: Base(data: NSMutableData()), image: image, type: type)
    }

    func makeData() throws -> Data {
        let data = base.getData()
        guard data.isEmpty else {
            throw Image.ImageCreationError.invalidData
        }
        guard let destination = CGImageDestinationCreateWithData(data, typeIdentifier, 1, nil) else {
            throw Image.ImageCreationError.invalidDestination
        }
        let cgImage = try image.makeCGImage()
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw Image.ImageCreationError.invalidDestination
        }
        return data as Data
    }
}

// MARK: Destination<URL>
extension Image.Destination<URL> {
    static func urlDestination(forURL url: URL, image: Image, type: UTType) -> Self {
        Self(base: Base(url: url), image: image, type: type)
    }

    func write() throws {
        let url = base.getURL()
        let verifier = FileVerifier(url: url)
        guard !verifier.fileExists else {
            throw verifier.fileAlreadyExistsError()
        }
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, typeIdentifier, 1, nil) else {
            throw Image.ImageCreationError.invalidDestination
        }
        let cgImage = try image.makeCGImage()
        CGImageDestinationAddImage(destination, cgImage, nil)
        if !CGImageDestinationFinalize(destination) {
            throw Image.ImageCreationError.invalidDestination
        }
    }
}
