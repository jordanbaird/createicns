//
// Create.swift
// createicns
//

import Foundation

/// A runner that manages the creation and output of icns and iconset files.
struct Create: Runner {
    /// The location of the initial image data.
    let inputInfo: FileInfo

    /// The location to write the created iconset.
    let outputInfo: FileInfo

    /// A message to print before the runner begins verification.
    let actionMessage: String

    /// A message to print after a successful run.
    let successMessage: String

    /// An object that writes an iconset to the runner's output.
    let writer: IconSetWriter

    /// Creates a runner with the given input path, output path, and output type.
    init(input: String, output: String?, type: OutputType) throws {
        let fileType: FileType
        let actionMessage: String
        let successMessage: String
        let writer: IconSetWriter

        let isIconSet: Bool = {
            switch type {
            case .icns:
                return false
            case .iconSet:
                return true
            case .infer:
                if
                    let output,
                    let outputFileType = FileInfo(path: output).fileType
                {
                    return outputFileType == .iconSet
                }
                // FIXME: Should throw an error instead of assuming false.
                return false
            }
        }()

        if isIconSet {
            fileType = .iconSet
            actionMessage = "Creating iconset..."
            successMessage = "Iconset successfully created."
            writer = .direct
        } else {
            fileType = .icns
            actionMessage = "Creating icon..."
            successMessage = "Icon successfully created."
            writer = .iconUtil
        }

        let inputInfo = FileInfo(path: input)
        let outputInfo: FileInfo = {
            guard let output else {
                return inputInfo.withPathExtension(for: fileType)
            }
            let info = FileInfo(path: output)
            if
                !isIconSet,
                info.isDirectory
            {
                return info
                    .appending(component: inputInfo.lastPathComponent)
                    .withPathExtension(for: fileType)
            }
            return info
        }()

        let inputVerifier = FileVerifier(options: [
            .fileExists,
            .isDirectory.inverted,
        ])
        let outputVerifier = FileVerifier(options: [
            .fileExists.inverted,
            .isDirectory.inverted,
            .isFileType(fileType),
        ])

        self.inputInfo = try inputVerifier.verify(info: inputInfo)
        self.outputInfo = try outputVerifier.verify(info: outputInfo)
        self.actionMessage = actionMessage
        self.successMessage = successMessage
        self.writer = writer
    }

    func run() throws {
        print(actionMessage)
        let image = try Image(url: inputInfo.url)
        let iconSet = IconSet(image: image)
        try writer.write(iconSet, to: outputInfo.url)
        print(FormattedText(successMessage, color: .green))
    }
}
