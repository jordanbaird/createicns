//
//  ImageProcessingError.swift
//  createicns
//

/// An error that can be thrown during image processing.
enum ImageProcessingError: String, FormattedError {
    case graphicsContextError = "Error with graphics context."
    case invalidColorSpace = "Invalid color space."
    case invalidData = "Invalid image data."
    case invalidDestination = "Invalid image destination."
    case invalidImageFormat = "File is not a valid image format."
    case invalidSource = "Invalid image source."
    case pdfDocumentError = "Error with PDF document."
    case svgCreationError = "Error creating image data from SVG."

    var errorMessage: String {
        "Could not process image".formatted(color: .red) + " - " + rawValue.formatted(style: .bold)
    }
}
