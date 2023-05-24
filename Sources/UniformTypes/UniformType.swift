//
// UniformType.swift
// createicns
//

import Foundation
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

public struct UniformType {

    // MARK: Types

    /// A type that represents a tag class of a uniform type.
    public struct TagClass {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        @available(macOS 11.0, *)
        fileprivate init(_utTagClass: UTTagClass) {
            self.init(rawValue: _utTagClass.rawValue)
        }

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

        public static let filenameExtension: Self = {
            if #available(macOS 11.0, *) {
                return Self(_utTagClass: .filenameExtension)
            } else {
                return Self(rawValue: kUTTagClassFilenameExtension as String)
            }
        }()

        public static let mimeType: Self = {
            if #available(macOS 11.0, *) {
                return Self(_utTagClass: .mimeType)
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
            return UTType(identifier)?.isDeclared ?? false
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
            return UTType(identifier)?.isDynamic ?? false
        } else {
            return UTTypeIsDeclared(identifier as CFString)
        }
    }

    /// The tag specification dictionary of the type.
    public var tags: [TagClass: [String]] {
        if #available(macOS 11.0, *) {
            guard let utType = UTType(identifier) else {
                return [:]
            }
            return utType.tags.reduce(into: [:]) { spec, tag in
                spec[TagClass(_utTagClass: tag.key)] = tag.value
            }
        } else {
            guard
                let declaration = UTTypeCopyDeclaration(identifier as CFString),
                let keysAndValues = declaration.takeRetainedValue() as? [CFString: AnyObject],
                let spec = keysAndValues[kUTTypeTagSpecificationKey] as? [String: AnyObject]
            else {
                return [:]
            }
            return spec.reduce(into: [:]) { spec, tag in
                guard let tagClass = TagClass(normalized: tag.key) else {
                    return
                }
                if let value = tag.value as? [String] {
                    spec[tagClass] = value
                } else if let value = tag.value as? String {
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
            return UTType(identifier)?.localizedDescription
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

    /// Creates a type based on a tag, a tag class, and a supertype that it
    /// conforms to.
    public init?(tag: String, tagClass: TagClass, conformingTo supertype: Self?) {
        if #available(macOS 11.0, *) {
            guard let utType = UTType(tag: tag, tagClass: UTTagClass(rawValue: tagClass.rawValue), conformingTo: supertype.flatMap { UTType($0.identifier) }) else {
                return nil
            }
            self.init(utType.identifier)
        } else {
            guard let identifier = UTTypeCreatePreferredIdentifierForTag(tagClass.rawValue as CFString, tag as CFString, supertype?.identifier as CFString?) else {
                return nil
            }
            self.init(identifier.takeRetainedValue() as String)
        }
    }

    // MARK: Instance Methods

    /// Returns a Boolean value indicating whether this type conforms to
    /// another type.
    public func conforms(to type: Self) -> Bool {
        if #available(macOS 11.0, *) {
            guard
                let selfType = UTType(identifier),
                let otherType = UTType(type.identifier)
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
                return UTType(identifier)?.preferredFilenameExtension
            case .mimeType:
                return UTType(identifier)?.preferredMIMEType
            default:
                return nil
            }
        } else {
            guard let tag = UTTypeCopyPreferredTagWithClass(identifier as CFString, tagClass.rawValue as CFString) else {
                return nil
            }
            return tag.takeRetainedValue() as String
        }
    }

    /// Returns the tags for the given tag class.
    public func allTags(with tagClass: TagClass) -> [String]? {
        if #available(macOS 11.0, *) {
            return UTType(identifier)?.tags[UTTagClass(rawValue: tagClass.rawValue)]
        } else {
            guard let tags = UTTypeCopyAllTagsWithClass(identifier as CFString, tagClass.rawValue as CFString) else {
                return nil
            }
            return tags.takeRetainedValue() as? [String]
        }
    }
}

extension UniformType {
    public static let image: Self = {
        if #available(macOS 11.0, *) {
            return Self(UTType.image.identifier)
        }
        return Self(kUTTypeImage as String)
    }()

    public static let png: Self = {
        if #available(macOS 11.0, *) {
            return Self(UTType.png.identifier)
        }
        return Self(kUTTypePNG as String)
    }()

    public static let gif: Self = {
        if #available(macOS 11.0, *) {
            return Self(UTType.gif.identifier)
        }
        return Self(kUTTypeGIF as String)
    }()

    public static let jpeg: Self = {
        if #available(macOS 11.0, *) {
            return Self(UTType.jpeg.identifier)
        }
        return Self(kUTTypeJPEG as String)
    }()

    public static let webP: Self = {
        if #available(macOS 11.0, *) {
            return Self(UTType.webP.identifier)
        }
        return Self("org.webmproject.webp")
    }()

    public static let tiff: Self = {
        if #available(macOS 11.0, *) {
            return Self(UTType.tiff.identifier)
        }
        return Self(kUTTypeTIFF as String)
    }()

    public static let bmp: Self = {
        if #available(macOS 11.0, *) {
            return Self(UTType.bmp.identifier)
        }
        return Self(kUTTypeBMP as String)
    }()

    public static let svg: Self = {
        if #available(macOS 11.0, *) {
            return Self(UTType.svg.identifier)
        }
        return Self(kUTTypeScalableVectorGraphics as String)
    }()

    public static let rawImage: Self = {
        if #available(macOS 11.0, *) {
            return Self(UTType.rawImage.identifier)
        }
        return Self(kUTTypeRawImage as String)
    }()

    public static let pdf: Self = {
        if #available(macOS 11.0, *) {
            return Self(UTType.pdf.identifier)
        }
        return Self(kUTTypePDF as String)
    }()
}

// MARK: UniformType: CustomStringConvertible
extension UniformType: CustomStringConvertible {
    public var description: String {
        identifier
    }
}

// MARK: UniformType: Equatable
extension UniformType: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        if #available(macOS 11.0, *) {
            return UTType(lhs.identifier) == UTType(rhs.identifier)
        } else {
            return UTTypeEqual(lhs.identifier as CFString, rhs.identifier as CFString)
        }
    }
}

// MARK: UniformType: Hashable
extension UniformType: Hashable {
    public func hash(into hasher: inout Hasher) {
        if #available(macOS 11.0, *) {
            hasher.combine(UTType(identifier))
        } else {
            hasher.combine(identifier as CFString)
        }
    }
}

// MARK: TagClass: Equatable
extension UniformType.TagClass: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

// MARK: TagClass: Hashable
extension UniformType.TagClass: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

// MARK: TagClass: RawRepresentable
extension UniformType.TagClass: RawRepresentable { }
