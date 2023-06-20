//
// Create.swift
// createicns
//

/// A runner that manages the creation and output of icns and iconset files.
struct Create: Runner {
    /// The output file type.
    let fileType: FileType

    /// The location of the initial image data.
    let inputInfo: FileInfo

    /// The location to write the created iconset.
    let outputInfo: FileInfo

    /// A message to print before the runner begins verification.
    let actionMessage: String

    /// A message to print after a successful run.
    let successMessage: String

    /// An object that writes an iconset to the runner's output.
    let writer: IconsetWriter

    /// Creates a runner with the given input path, output path, and output type.
    init(input: String, output: String?, type: OutputType) {
        let fileType: FileType
        let actionMessage: String
        let successMessage: String
        let writer: IconsetWriter

        let isIconset: Bool = {
            switch type {
            case .icns:
                return false
            case .iconset:
                return true
            case .infer:
                if
                    let output,
                    let fileType = FileInfo(path: output).fileType
                {
                    return fileType == .iconset
                }
                // TODO: Handle this instead of assuming false.
                return false
            }
        }()

        if isIconset {
            fileType = .iconset
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
                !isIconset,
                info.isDirectory
            {
                return info
                    .appending(component: inputInfo.lastPathComponent)
                    .withPathExtension(for: fileType)
            }
            return info
        }()

        self.fileType = fileType
        self.inputInfo = inputInfo
        self.outputInfo = outputInfo
        self.actionMessage = actionMessage
        self.successMessage = successMessage
        self.writer = writer
    }

    func validate() throws {
        let inputVerifier = FileVerifier(options: [
            .fileExists,
            .isDirectory.inverted,
        ])
        let outputVerifier = FileVerifier(options: [
            .fileExists.inverted,
            .isDirectory.inverted,
            .isFileType(fileType),
        ])
        try inputVerifier.verify(info: inputInfo)
        try outputVerifier.verify(info: outputInfo)
    }

    func run() throws {
        print(actionMessage)
        let image = try Image(url: inputInfo.url)
        let iconset = Iconset(image: image)
        try iconset.validateDimensions()
        try writer.write(iconset, to: outputInfo.url)
        print(successMessage.formatted(color: .green))
    }
}
