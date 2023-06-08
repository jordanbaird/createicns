//
// FileType.swift
// createicns
//

import Foundation
#if canImport(UniformTypeIdentifiers)
@_implementationOnly import UniformTypeIdentifiers
#endif

/// A structure that represents a file type.
struct FileType {
    /// The string that represents the type.
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

    /// Creates a type based on the given identifier.
    init(_ identifier: String) {
        self.identifier = identifier
    }

    /// Creates a type based on the path extension of the given url, ensuring that
    /// it conforms to the given supertype.
    ///
    /// If a type cannot be created from the path extension, or if a type can be created,
    /// but does not conform to the specified supertype, this initializer returns `nil`.
    /// If no supertype is specified, the requirement that the created type conform to a
    /// supertype is ignored.
    init?(url: URL, conformingTo supertype: Self? = nil) {
        if #available(macOS 11.0, *) {
            let tag = url.pathExtension
            let tagClass = UTTagClass.filenameExtension
            let supertype = supertype.flatMap { supertype in
                UTType(supertype.identifier)
            }
            guard let systemType = UTType(tag: tag, tagClass: tagClass, conformingTo: supertype) else {
                return nil
            }
            self.init(systemType.identifier)
        } else {
            let tag = url.pathExtension as CFString
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

    /// Creates a type based on the given system-defined type.
    @available(macOS 11.0, *)
    private init(utType: UTType) {
        self.init(utType.identifier)
    }
}

// MARK: FileType Constants
extension FileType {
    static let image: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .image)
        }
        return Self(kUTTypeImage as String)
    }()

    static let bmp: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .bmp)
        }
        return Self(kUTTypeBMP as String)
    }()

    static let gif: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .gif)
        }
        return Self(kUTTypeGIF as String)
    }()

    static let icns: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .icns)
        }
        return Self(kUTTypeAppleICNS as String)
    }()

    static let iconSet = Self("com.apple.iconset")

    static let ico: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .ico)
        }
        return Self(kUTTypeICO as String)
    }()

    static let jpeg: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .jpeg)
        }
        return Self(kUTTypeJPEG as String)
    }()

    static let pdf: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .pdf)
        }
        return Self(kUTTypePDF as String)
    }()

    static let png: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .png)
        }
        return Self(kUTTypePNG as String)
    }()

    static let rawImage: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .rawImage)
        }
        return Self(kUTTypeRawImage as String)
    }()

    static let svg: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .svg)
        }
        return Self(kUTTypeScalableVectorGraphics as String)
    }()

    static let tiff: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .tiff)
        }
        return Self(kUTTypeTIFF as String)
    }()

    static let webP: Self = {
        if #available(macOS 11.0, *) {
            return Self(utType: .webP)
        }
        return Self("org.webmproject.webp")
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
    var description: String {
        identifier
    }
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
