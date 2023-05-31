//
// UTType.swift
// createicns
//

import Foundation
#if canImport(UniformTypeIdentifiers)
@_implementationOnly import UniformTypeIdentifiers

@available(macOS 11.0, *)
private typealias SystemType = UniformTypeIdentifiers.UTType

@available(macOS 11.0, *)
private typealias SystemTagClass = UniformTypeIdentifiers.UTTagClass
#endif

/// A structure that represents a type of data to load, send, or receive.
public struct UTType {

    // MARK: Types

    /// A type that represents a tag class of a uniform type.
    public struct TagClass {
        /// The raw value of the tag class.
        public let rawValue: String

        /// Creates a tag class with the given raw value.
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        /// Creates a tag class from the given system-defined tag class.
        @available(macOS 11.0, *)
        fileprivate init(systemTagClass: SystemTagClass) {
            self.init(rawValue: systemTagClass.rawValue)
        }

        /// Creates a tag class by comparing the given string against the raw values of
        /// the tag classes defined by the system, returning `nil` if no match is found.
        fileprivate init?(normalized: String) {
            if normalized == Self.filenameExtension.rawValue {
                self = .filenameExtension
            } else if normalized == Self.mimeType.rawValue {
                self = .mimeType
            } else {
                return nil
            }
        }

        // MARK: Standard Tag Classes

        /// A type property that returns the tag class used to map a type to a filename extension.
        public static let filenameExtension: Self = {
            if #available(macOS 11.0, *) {
                return Self(systemTagClass: .filenameExtension)
            } else {
                return Self(rawValue: kUTTagClassFilenameExtension as String)
            }
        }()

        /// A type property that returns the tag class used to map a type to a MIME type.
        public static let mimeType: Self = {
            if #available(macOS 11.0, *) {
                return Self(systemTagClass: .mimeType)
            } else {
                return Self(rawValue: kUTTagClassMIMEType as String)
            }
        }()
    }

    // MARK: Instance Properties

    /// The string that represents the type.
    ///
    /// The identifier uniquely identifies its type, represented by a reverse-DNS
    /// string, such as `public.jpeg` or `com.adobe.pdf`.
    public let identifier: String

    /// A Boolean value that indicates whether the system declares the type.
    ///
    /// The system either declares a type, or dynamically generates a type, but
    /// not both.
    public var isDeclared: Bool {
        if #available(macOS 11.0, *) {
            return SystemType(identifier)?.isDeclared ?? false
        } else {
            return UTTypeIsDeclared(identifier as CFString)
        }
    }

    /// A Boolean value that indicates whether the system generates the type.
    ///
    /// The system recognizes dynamic types, but they may not be directly declared
    /// or claimed by an app. The system returns dynamic types when it encounters
    /// a file whose metadata doesn't have a corresponding type known to the system.
    ///
    /// The system either declares a type, or dynamically generates a type, but
    /// not both.
    public var isDynamic: Bool {
        if #available(macOS 11.0, *) {
            return SystemType(identifier)?.isDynamic ?? false
        } else {
            return UTTypeIsDeclared(identifier as CFString)
        }
    }

    /// The tag specification dictionary of the type.
    public var tags: [TagClass: [String]] {
        if #available(macOS 11.0, *) {
            guard let systemType = SystemType(identifier) else {
                return [:]
            }
            return systemType.tags.reduce(into: [:]) { spec, pair in
                spec[TagClass(systemTagClass: pair.key)] = pair.value
            }
        } else {
            guard
                let declaration = UTTypeCopyDeclaration(identifier as CFString),
                let keysAndValues = declaration.takeRetainedValue() as? [CFString: AnyObject],
                let spec = keysAndValues[kUTTypeTagSpecificationKey] as? [String: AnyObject]
            else {
                return [:]
            }
            return spec.reduce(into: [:]) { spec, pair in
                guard let tagClass = TagClass(normalized: pair.key) else {
                    return
                }
                if let value = pair.value as? [String] {
                    spec[tagClass] = value
                } else if let value = pair.value as? String {
                    spec[tagClass] = [value]
                } else {
                    preconditionFailure("Invalid type in tag specification.")
                }
            }
        }
    }

    /// A localized string that describes the type.
    public var localizedDescription: String? {
        if #available(macOS 11.0, *) {
            return SystemType(identifier)?.localizedDescription
        } else {
            guard let description = UTTypeCopyDescription(identifier as CFString) else {
                return nil
            }
            return description.takeRetainedValue() as String
        }
    }

    /// The type's preferred filename extension.
    public var preferredFilenameExtension: String? {
        preferredTag(with: .filenameExtension)
    }

    /// The type's preferred MIME type.
    public var preferredMIMEType: String? {
        preferredTag(with: .mimeType)
    }

    // MARK: Initializers

    /// Creates a type based on the given identifier.
    public init(_ identifier: String) {
        self.identifier = identifier
    }

    /// Creates a type based on a tag, a tag class, and a supertype that it conforms to.
    public init?(tag: String, tagClass: TagClass, conformingTo supertype: Self?) {
        if #available(macOS 11.0, *) {
            let tagClass = SystemTagClass(rawValue: tagClass.rawValue)
            let supertype = supertype.flatMap { supertype in
                SystemType(supertype.identifier)
            }
            guard let systemType = SystemType(tag: tag, tagClass: tagClass, conformingTo: supertype) else {
                return nil
            }
            self.init(systemType.identifier)
        } else {
            let tagClass = tagClass.rawValue as CFString
            let supertype = supertype.flatMap { supertype in
                supertype.identifier as CFString
            }
            guard let identifier = UTTypeCreatePreferredIdentifierForTag(tagClass, tag as CFString, supertype) else {
                return nil
            }
            self.init(identifier.takeRetainedValue() as String)
        }
    }

    /// Creates a type based on the path extension of the given url, ensuring that
    /// it conforms to the given supertype.
    ///
    /// If a type cannot be created from the path extension, or if a type can be created,
    /// but does not conform to the specified supertype, this initializer returns `nil`.
    /// If no supertype is specified, the requirement that the created type conform to a
    /// supertype is ignored.
    public init?(url: URL, conformingTo supertype: Self? = nil) {
        self.init(tag: url.pathExtension, tagClass: .filenameExtension, conformingTo: supertype)
    }

    /// Creates a type based on the given system-defined type.
    @available(macOS 11.0, *)
    private init(systemType: SystemType) {
        self.init(systemType.identifier)
    }

    // MARK: Instance Methods

    /// Returns a Boolean value indicating whether this type conforms to another type.
    public func conforms(to type: Self) -> Bool {
        if #available(macOS 11.0, *) {
            guard
                let selfType = SystemType(identifier),
                let otherType = SystemType(type.identifier)
            else {
                return false
            }
            return selfType.conforms(to: otherType)
        } else {
            return UTTypeConformsTo(identifier as CFString, type.identifier as CFString)
        }
    }

    /// Returns the preferred tag for the given tag class.
    public func preferredTag(with tagClass: TagClass) -> String? {
        if #available(macOS 11.0, *) {
            switch tagClass {
            case .filenameExtension:
                return SystemType(identifier)?.preferredFilenameExtension
            case .mimeType:
                return SystemType(identifier)?.preferredMIMEType
            default:
                return nil
            }
        } else {
            let tagClass = tagClass.rawValue as CFString
            guard let tag = UTTypeCopyPreferredTagWithClass(identifier as CFString, tagClass) else {
                return nil
            }
            return tag.takeRetainedValue() as String
        }
    }

    /// Returns the tags for the given tag class.
    public func allTags(with tagClass: TagClass) -> [String]? {
        if #available(macOS 11.0, *) {
            let tagClass = SystemTagClass(rawValue: tagClass.rawValue)
            return SystemType(identifier)?.tags[tagClass]
        } else {
            let tagClass = tagClass.rawValue as CFString
            guard let tags = UTTypeCopyAllTagsWithClass(identifier as CFString, tagClass) else {
                return nil
            }
            return tags.takeRetainedValue() as? [String]
        }
    }
}

extension UTType {
    public static let image: Self = {
        if #available(macOS 11.0, *) {
            return Self(systemType: .image)
        }
        return Self(kUTTypeImage as String)
    }()

    public static let bmp: Self = {
        if #available(macOS 11.0, *) {
            return Self(systemType: .bmp)
        }
        return Self(kUTTypeBMP as String)
    }()

    public static let gif: Self = {
        if #available(macOS 11.0, *) {
            return Self(systemType: .gif)
        }
        return Self(kUTTypeGIF as String)
    }()

    public static let icns: Self = {
        if #available(macOS 11.0, *) {
            return Self(systemType: .icns)
        }
        return Self(kUTTypeAppleICNS as String)
    }()

    public static let iconSet = Self("com.apple.iconset")

    public static let ico: Self = {
        if #available(macOS 11.0, *) {
            return Self(systemType: .ico)
        }
        return Self(kUTTypeICO as String)
    }()

    public static let jpeg: Self = {
        if #available(macOS 11.0, *) {
            return Self(systemType: .jpeg)
        }
        return Self(kUTTypeJPEG as String)
    }()

    public static let pdf: Self = {
        if #available(macOS 11.0, *) {
            return Self(systemType: .pdf)
        }
        return Self(kUTTypePDF as String)
    }()

    public static let png: Self = {
        if #available(macOS 11.0, *) {
            return Self(systemType: .png)
        }
        return Self(kUTTypePNG as String)
    }()

    public static let rawImage: Self = {
        if #available(macOS 11.0, *) {
            return Self(systemType: .rawImage)
        }
        return Self(kUTTypeRawImage as String)
    }()

    public static let svg: Self = {
        if #available(macOS 11.0, *) {
            return Self(systemType: .svg)
        }
        return Self(kUTTypeScalableVectorGraphics as String)
    }()

    public static let tiff: Self = {
        if #available(macOS 11.0, *) {
            return Self(systemType: .tiff)
        }
        return Self(kUTTypeTIFF as String)
    }()

    public static let webP: Self = {
        if #available(macOS 11.0, *) {
            return Self(systemType: .webP)
        }
        return Self("org.webmproject.webp")
    }()
}

// MARK: UTType: CustomStringConvertible
extension UTType: CustomStringConvertible {
    public var description: String {
        identifier
    }
}

// MARK: UTType: Equatable
extension UTType: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        if #available(macOS 11.0, *) {
            return SystemType(lhs.identifier) == SystemType(rhs.identifier)
        } else {
            return UTTypeEqual(lhs.identifier as CFString, rhs.identifier as CFString)
        }
    }
}

// MARK: UTType: Hashable
extension UTType: Hashable {
    public func hash(into hasher: inout Hasher) {
        if #available(macOS 11.0, *) {
            hasher.combine(SystemType(identifier))
        } else {
            hasher.combine(identifier as CFString)
        }
    }
}

// MARK: TagClass: Equatable
extension UTType.TagClass: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

// MARK: TagClass: Hashable
extension UTType.TagClass: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

// MARK: TagClass: RawRepresentable
extension UTType.TagClass: RawRepresentable { }
