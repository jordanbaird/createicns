//
// Image.swift
// createicns
//

import Foundation
import ImageIO
import UniformTypes

struct Image {

    // MARK: Instance Properties

    private let context: CGContext

    private let drawingPrep: (CGContext) -> Bool

    // MARK: Initializers

    private init(context: CGContext, drawingPrep: @escaping (CGContext) -> Bool) {
        self.context = context
        self.drawingPrep = drawingPrep
    }

    init(url: URL) throws {
        let type = TypeIdentifier(url: url)

        if !TypeIdentifier.validTypes.contains(type) {
            throw CreationError.invalidImageFormat
        }

        switch type {
        case .pdf:
            guard
                let document = CGPDFDocument(url as CFURL),
                let page = document.page(at: 1)
            else {
                throw CreationError.unknownError // FIXME: Need a better error.
            }

            let rect = page.getBoxRect(.mediaBox)

            let width = Int(rect.width)
            let height = Int(rect.height)

            let alphaInfo = CGImageAlphaInfo.premultipliedLast.rawValue

            guard
                let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                let context = CGContext(
                    data: nil,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: 0,
                    space: colorSpace,
                    bitmapInfo: alphaInfo
                )
            else {
                throw CreationError.unknownError // FIXME: Need a better error.
            }

            self.init(context: context, drawingPrep: { context in
                context.setAllowsAntialiasing(true)
                context.setShouldAntialias(true)
                context.interpolationQuality = .high
                context.clear(rect)
                context.drawPDFPage(page)
                return true
            })
        default:
            let options: [CFString: CFTypeRef] = [
                kCGImageSourceTypeIdentifierHint: type.rawValue as CFString,
                kCGImageSourceShouldCache: kCFBooleanTrue,
                kCGImageSourceShouldAllowFloat: kCFBooleanTrue,
            ]

            guard
                let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary),
                let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
            else {
                throw CreationError.unknownError // FIXME: Need a better error.
            }

            let width = cgImage.width
            let height = cgImage.height

            let bitmapInfo = CGBitmapInfo.byteOrderDefault.rawValue
            let alphaInfo = CGImageAlphaInfo.premultipliedLast.rawValue

            guard
                let colorSpace = cgImage.colorSpace,
                let context = CGContext(
                    data: nil,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: 0,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo | alphaInfo
                )
            else {
                throw CreationError.unknownError // FIXME: Need a better error.
            }

            self.init(context: context, drawingPrep: { context in
                context.setAllowsAntialiasing(true)
                context.setShouldAntialias(true)
                context.interpolationQuality = .high
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
                return true
            })
        }

        if context.width != context.height {
            throw CreationError.invalidDimensions
        }
    }

    // MARK: Instance Methods

    func dataDestination(forType type: TypeIdentifier) -> Destination<Data> {
        Destination.dataDestination(forImage: self, type: type)
    }

    func urlDestination(forURL url: URL, type: TypeIdentifier) -> Destination<URL> {
        Destination.urlDestination(forURL: url, image: self, type: type)
    }

    func makeCGImage() -> CGImage? {
        guard drawingPrep(context) else {
            return nil
        }
        return context.makeImage()
    }

    func resized(to size: CGSize) -> Self? {
        let width = Int(size.width)
        let height = Int(size.height)

        guard
            let colorSpace = context.colorSpace,
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: context.bitsPerComponent,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: context.bitmapInfo.rawValue | context.alphaInfo.rawValue
            )
        else {
            return nil
        }

        return Self(context: context, drawingPrep: { context in
            guard let cgImage = makeCGImage() else {
                return false
            }
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)
            context.interpolationQuality = .high
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        })
    }
}

// MARK: Image.TypeIdentifier
extension Image {
    struct TypeIdentifier {
        let rawValue: String

        init(rawValue: String) {
            self.rawValue = rawValue
        }

        init?(value: Any) {
            guard let rawValue = value as? String else {
                return nil
            }
            self.init(rawValue: rawValue)
        }

        init(pathExtension: String) {
            guard let type = UniformType(tag: pathExtension, tagClass: .filenameExtension, conformingTo: nil) else {
                self = .image
                return
            }
            self.init(rawValue: type.identifier)
        }

        init(url: URL) {
            self.init(pathExtension: url.pathExtension)
        }

        // MARK: Constants

        static let image = Self(rawValue: UniformType.image.identifier)

        static let bmp = Self(rawValue: UniformType.bmp.identifier)

        static let gif = Self(rawValue: UniformType.gif.identifier)

        static let jpeg = Self(rawValue: UniformType.jpeg.identifier)

        static let pdf = Self(rawValue: UniformType.pdf.identifier)

        static let png = Self(rawValue: UniformType.png.identifier)

        static let rawImage = Self(rawValue: UniformType.rawImage.identifier)

        // TODO: Try to figure out a good way to do SVG.
        // static let svg = Self(rawValue: UniformType.svg.identifier)

        static let tiff = Self(rawValue: UniformType.tiff.identifier)

        static let webP = Self(rawValue: UniformType.webP.identifier)

        static let validTypes: [Self] = {
            let prevalidatedTypes: [Self] = [
                .pdf,
                .png,
            ]
            let identifiers = CGImageSourceCopyTypeIdentifiers() as Array
            let validTypes = prevalidatedTypes + identifiers.compactMap { Self(value: $0) }
            var seen = Set<Self>()
            return validTypes.filter { seen.insert($0).inserted }
        }()
    }
}

// MARK: TypeIdentifier: Equatable
extension Image.TypeIdentifier: Equatable { }

// MARK: TypeIdentifier: Hashable
extension Image.TypeIdentifier: Hashable { }

// MARK: TypeIdentifier: RawRepresentable
extension Image.TypeIdentifier: RawRepresentable { }

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

        let type: TypeIdentifier

        private init(base: Base, image: Image, type: TypeIdentifier) {
            self.base = base
            self.image = image
            self.type = type
        }
    }
}

// MARK: Destination<Data>
extension Image.Destination<Data> {
    static func dataDestination(forImage image: Image, type: Image.TypeIdentifier) -> Self {
        Self(base: Base(data: NSMutableData()), image: image, type: type)
    }

    var data: Data? {
        let data = base.getData()
        guard data.isEmpty else {
            return data as Data
        }
        guard
            let destination = CGImageDestinationCreateWithData(data, type.rawValue as CFString, 1, nil),
            let cgImage = image.makeCGImage()
        else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return data as Data
    }
}

// MARK: Destination<URL>
extension Image.Destination<URL> {
    static func urlDestination(forURL url: URL, image: Image, type: Image.TypeIdentifier) -> Self {
        Self(base: Base(url: url), image: image, type: type)
    }

    func write() throws {
        let url = base.getURL()
        let verifier = FileVerifier(url: url)
        guard !verifier.fileExists else {
            throw CreationError.alreadyExists(verifier)
        }
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type.rawValue as CFString, 1, nil) else {
            throw CreationError.invalidDestination
        }
        guard let cgImage = image.makeCGImage() else {
            throw CreationError.unknownError // FIXME: Need a better error.
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        if !CGImageDestinationFinalize(destination) {
            throw CreationError.invalidDestination
        }
    }
}
