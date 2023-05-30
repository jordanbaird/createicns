//
// IconSetWriter.swift
// createicns
//

import Core
import Foundation

enum IconSetWriter {
    case direct
    case iconUtil

    func write(iconSet: IconSet, outputURL: URL) throws {
        switch self {
        case .direct:
            try iconSet.write(to: outputURL)
        case .iconUtil:
            try IconUtil(iconSet: iconSet).run(writingTo: outputURL)
        }
    }
}
