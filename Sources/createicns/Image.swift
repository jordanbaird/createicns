//
// Image.swift
// createicns
//

import ImageIO
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

struct Image {

    // MARK: Instance Properties

    let cgImage: CGImage

    var width: CGFloat {
        CGFloat(cgImage.width)
    }

    var height: CGFloat {
        CGFloat(cgImage.height)
    }

    var colorSpace: CGColorSpace? {
        cgImage.colorSpace
    }

    var pngData: Data {
        get throws {
            guard let data = dataDestination(forType: .png).data else {
                throw CreationError.invalidData
            }
            return data
        }
    }

    // MARK: Initializers

    init(cgImage: CGImage) {
        self.cgImage = cgImage
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
            guard
                let context = CGContext(
                    data: nil,
                    width: Int(rect.width),
                    height: Int(rect.height),
                    bitsPerComponent: 8,
                    bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            else {
                throw CreationError.unknownError // FIXME: Need a better error.
            }

            context.clear(rect)
            context.drawPDFPage(page)

            guard let image = context.makeImage() else {
                throw CreationError.unknownError // FIXME: Need a better error.
            }

            self.init(cgImage: image)
        default:
            let options: [CFString: CFTypeRef] = [
                kCGImageSourceTypeIdentifierHint: type.cfString,
                kCGImageSourceShouldCache: kCFBooleanTrue,
                kCGImageSourceShouldAllowFloat: kCFBooleanTrue,
            ]

            guard
                let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary),
                let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
            else {
                throw CreationError.unknownError // FIXME: Need a better error.
            }

            self.init(cgImage: cgImage)
        }
    }

    // MARK: Instance Methods

    func dataDestination(forType type: TypeIdentifier) -> Destination<Data> {
        Destination.dataDestination(forImage: self, type: type)
    }

    func urlDestination(forURL url: URL, type: TypeIdentifier) -> Destination<URL> {
        Destination.urlDestination(forURL: url, image: self, type: type)
    }

    func resized(to size: CGSize) -> Self? {
        let width = Int(size.width)
        let height = Int(size.height)

        let bitmapInfo = CGBitmapInfo.byteOrderDefault.rawValue
        let alphaInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard
            let colorSpace,
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
            return nil
        }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let resizedImage = context.makeImage() else {
            return nil
        }

        return Self(cgImage: resizedImage)
    }
}

// MARK: Image.TypeIdentifier
extension Image {
    struct TypeIdentifier: RawRepresentable {

        // MARK: Static Properties

        static let image: Self = {
            if #available(macOS 11.0, *) {
                return Self(rawValue: UTType.image.identifier)
            }
            return Self(rawValue: kUTTypeImage as String)
        }()

        static let png: Self = {
            if #available(macOS 11.0, *) {
                return Self(rawValue: UTType.png.identifier)
            }
            return Self(rawValue: kUTTypePNG as String)
        }()

        static let pdf: Self = {
            if #available(macOS 11.0, *) {
                return Self(rawValue: UTType.pdf.identifier)
            }
            return Self(rawValue: kUTTypePDF as String)
        }()

        // TODO: Try to figure out a good way to do SVG.
        // static let svg: Self = {
        //     if #available(macOS 11.0, *) {
        //         return Self(rawValue: UTType.svg.identifier)
        //     }
        //     return Self(rawValue: kUTTypeScalableVectorGraphics as String)
        // }()

        static var validTypes: [Self] {
            let prevalidatedTypes: [Self] = [
                .png,
                .pdf,
            ]
            let identifiers = CGImageSourceCopyTypeIdentifiers() as Array
            let validTypes = prevalidatedTypes + identifiers.compactMap { Self(value: $0) }
            var seen = Set<Self>()
            return validTypes.filter { seen.insert($0).inserted }
        }

        // MARK: Instance Properties

        let rawValue: String

        var cfString: CFString {
            rawValue as CFString
        }

        // MARK: Initializers

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
            #if canImport(UniformTypeIdentifiers)
            if #available(macOS 11.0, *) {
                guard let type = UTType(tag: pathExtension, tagClass: .filenameExtension, conformingTo: nil) else {
                    self = .image
                    return
                }
                self.init(rawValue: type.identifier)
                return
            }
            #endif
            let tagClass = kUTTagClassFilenameExtension
            guard let type = UTTypeCreatePreferredIdentifierForTag(tagClass, pathExtension as CFString, nil) else {
                self = .image
                return
            }
            self.init(rawValue: type.takeRetainedValue() as String)
        }

        init(url: URL) {
            self.init(pathExtension: url.pathExtension)
        }
    }
}

// MARK: TypeIdentifier: Equatable
extension Image.TypeIdentifier: Equatable { }

// MARK: TypeIdentifier: Hashable
extension Image.TypeIdentifier: Hashable { }

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
        guard let destination = CGImageDestinationCreateWithData(data, type.cfString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image.cgImage, nil)
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
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type.cfString, 1, nil) else {
            throw CreationError.invalidDestination
        }
        CGImageDestinationAddImage(destination, image.cgImage, nil)
        if !CGImageDestinationFinalize(destination) {
            throw CreationError.invalidDestination
        }
    }
}
