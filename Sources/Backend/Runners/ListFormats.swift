//
//  ListFormats.swift
//  createicns
//

/// A runner that lists the tool's valid input formats.
struct ListFormats: Runner {
    /// Creates a text table with the given header and columns.
    private func textTable(header: String, columns: [[String]]) -> String {
        typealias PaddedColumn = (cells: [String], length: Int, cellCount: Int)

        let pad = " "

        let (paddedColumns, maxCellCount) = columns.reduce(
            into: (paddedColumns: [PaddedColumn](), maxCellCount: 0)
        ) { outerState, column in
            // get the max length of the column
            let length = column.map { $0.count }.max() ?? 0

            // produce an array of padded cells, keeping track of the total cell count
            let (cells, cellCount) = column.reduce(
                into: (cells: [String](), cellCount: 0)
            ) { innerState, cell in
                let padded = cell.padding(toLength: length, withPad: pad, startingAt: 0)
                innerState.cells.append(padded)
                innerState.cellCount += 1
            }

            // append a new padded column value consisting of the padded cells, max
            // length, and cell count
            outerState.paddedColumns.append((cells, length, cellCount))

            if cellCount > outerState.maxCellCount {
                // we have a new max cell count; update it
                outerState.maxCellCount = cellCount
            }
        }

        let headerLines: [String] = {
            // divide the header and body with a dashed line
            let divider: String = {
                let dash = "-"
                return paddedColumns.map { column in
                    String(repeating: dash, count: column.length)
                }
                .joined(separator: dash)
            }()
            return [header, divider]
        }()

        let lines = headerLines + (0..<maxCellCount).map { cellIndex in
            paddedColumns.map { column in
                guard cellIndex < column.cellCount else {
                    // we're past the end of this column; pad with whitespace to the start
                    // of the next column (note that there might not actually _be_ a next
                    // column, but it's easier to just trim the result once we're finished
                    // instead of checking the column index on every iteration)
                    return String(repeating: pad, count: column.length)
                }
                return column.cells[cellIndex]
            }
            .joined(separator: pad)
            .trimmingSuffix { $0.isWhitespace } // lazy hack (see above)
        }

        // finally, join the lines into a single string.
        return lines.joined(separator: "\n")
    }

    func run() {
        let sortedTypes = Image.validTypes.sorted()
        let table = textTable(
            header: "Valid Input Formats:",
            columns: [
                sortedTypes.map { $0.identifier },
                sortedTypes.map { $0.preferredFilenameExtension ?? "--" },
            ]
        )
        print(table)
    }
}
