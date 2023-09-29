//
//  FileType.swift
//  createicns
//

import Foundation
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// A structure that represents a file type.
struct FileType {
    /// The string that represents the type.
    ///
    /// The identifier uniquely identifies its type, represented by a reverse-DNS string,
    /// such as `public.jpeg` or `com.adobe.pdf`.
    let identifier: String

    /// The type's preferred filename extension.
    var preferredFilenameExtension: String? {
        if #available(macOS 11.0, *) {
            return UTType(identifier)?.preferredFilenameExtension
        } else {
            let tagClass = kUTTagClassFilenameExtension
            guard let tag = UTTypeCopyPreferredTagWithClass(identifier as CFString, tagClass) else {
                return nil
            }
            return tag.takeRetainedValue() as String
        }
    }

    /// Creates a file type based on the given identifier.
    init(_ identifier: String) {
        self.identifier = identifier
    }

    /// Creates a file type based on the given path extension, ensuring that it conforms to
    /// the given supertype.
    ///
    /// If a file type cannot be created from the path extension, or if a file type can be
    /// created, but does not conform to the specified supertype, this initializer returns
    /// `nil`. If no supertype is specified, the requirement that the created file type must
    /// conform to a supertype is ignored.
    init?(pathExtension: String, conformingTo supertype: Self? = nil) {
        if #available(macOS 11.0, *) {
            let tag = pathExtension
            let tagClass = UTTagClass.filenameExtension
            let supertype = supertype.flatMap { supertype in
                UTType(supertype.identifier)
            }
            guard let systemType = UTType(tag: tag, tagClass: tagClass, conformingTo: supertype) else {
                return nil
            }
            self.init(systemType.identifier)
        } else {
            let tag = pathExtension as CFString
            let tagClass = kUTTagClassFilenameExtension
            let supertype = supertype.flatMap { supertype in
                supertype.identifier as CFString
            }
            guard let identifier = UTTypeCreatePreferredIdentifierForTag(tagClass, tag, supertype) else {
                return nil
            }
            self.init(identifier.takeRetainedValue() as String)
        }
    }

    /// Creates a file type based on the path extension of the given url, ensuring that it
    /// conforms to the given supertype.
    ///
    /// If a file type cannot be created from the path extension, or if a file type can be
    /// created, but does not conform to the specified supertype, this initializer returns
    /// `nil`. If no supertype is specified, the requirement that the created file type must
    /// conform to a supertype is ignored.
    init?(url: URL, conformingTo supertype: Self? = nil) {
        self.init(pathExtension: url.pathExtension, conformingTo: supertype)
    }

    /// Creates a type based on the given system-defined type.
    @available(macOS 11.0, *)
    private init(utType: UTType) {
        self.init(utType.identifier)
    }
}

// MARK: Constants

extension FileType {
    /// A base type that represents image data.
    static let image: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .image)
        } else {
            return Self(kUTTypeImage as String)
        }
    }()

    /// A type that represents a Windows bitmap image.
    static let bmp: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .bmp)
        } else {
            return Self(kUTTypeBMP as String)
        }
    }()

    /// A type that represents a GIF image.
    static let gif: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .gif)
        } else {
            return Self(kUTTypeGIF as String)
        }
    }()

    /// A type that represents Apple icon data.
    static let icns: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .icns)
        } else {
            return Self(kUTTypeAppleICNS as String)
        }
    }()

    /// A type that represents an Apple iconset folder.
    static let iconset = Self("com.apple.iconset")

    /// A type that represents Windows icon data.
    static let ico: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .ico)
        } else {
            return Self(kUTTypeICO as String)
        }
    }()

    /// A type that represents a JPEG image.
    static let jpeg: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .jpeg)
        } else {
            return Self(kUTTypeJPEG as String)
        }
    }()

    /// A type that represents Adobe Portable Document Format (PDF) documents.
    static let pdf: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .pdf)
        } else {
            return Self(kUTTypePDF as String)
        }
    }()

    /// A type that represents a PNG image.
    static let png: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .png)
        } else {
            return Self(kUTTypePNG as String)
        }
    }()

    /// A base type that represents a raw image format that you use in digital photography.
    static let rawImage: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .rawImage)
        } else {
            return Self(kUTTypeRawImage as String)
        }
    }()

    /// A type that represents a scalable vector graphics (SVG) image.
    static let svg: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .svg)
        } else {
            return Self(kUTTypeScalableVectorGraphics as String)
        }
    }()

    /// A type that represents a TIFF image.
    static let tiff: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .tiff)
        } else {
            return Self(kUTTypeTIFF as String)
        }
    }()

    /// A type that represents a WebP image.
    static let webP: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .webP)
        } else {
            return Self("org.webmproject.webp")
        }
    }()
}

// MARK: FileType: Comparable
extension FileType: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier < rhs.identifier
    }
}

// MARK: FileType: CustomStringConvertible
extension FileType: CustomStringConvertible {
    var description: String { identifier }
}

// MARK: FileType: Equatable
extension FileType: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

// MARK: FileType: Hashable
extension FileType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
