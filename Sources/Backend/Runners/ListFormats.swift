//
// ListFormats.swift
// createicns
//

/// A runner that lists the tool's valid input formats.
struct ListFormats: Runner {
    private typealias PaddedColumn = (cells: [String], length: Int, cellCount: Int)

    /// Creates a text table with the given header and columns.
    private func textTable(header: String?, columns: [[String]]) -> String {
        let pad = " "
        let (paddedColumns, maxCellCount) = columns.reduce(
            into: (paddedColumns: [PaddedColumn](), maxCellCount: 0)
        ) { outerState, column in
            // Get the max length of the column.
            let length = column.map { $0.count }.max() ?? 0

            // Produce an array of padded cells, keeping track of the total cell count.
            let (cells, cellCount) = column.reduce(
                into: (cells: [String](), cellCount: 0)
            ) { innerState, cell in
                let padded = cell.padding(toLength: length, withPad: pad, startingAt: 0)
                innerState.cells.append(padded)
                innerState.cellCount += 1
            }

            // Append a new padded column value, consisting of the padded cells,
            // the max length, and the cell count.
            outerState.paddedColumns.append((cells, length, cellCount))

            if cellCount > outerState.maxCellCount {
                // We have a new max cell count. Update it.
                outerState.maxCellCount = cellCount
            }
        }

        var lines = [String]()

        if let header {
            lines.append(header)
            // Add a dashed line between the header and the first row of the table.
            let headerBreak = paddedColumns
                .map { column in
                    String(repeating: "-", count: column.length)
                }
                .joined(separator: "-")
            lines.append(headerBreak)
        }

        for n in 0..<maxCellCount {
            var lineFragments = [String]()
            for column in paddedColumns {
                if column.cellCount > n {
                    lineFragments.append(column.cells[n])
                } else {
                    // We're past the end of this column. Append whitespace to prepare
                    // for the next column. Note that there may not _be_ a next column,
                    // but it's easier to just trim the excess once we're done instead
                    // of checking for the last column on every iteration.
                    lineFragments.append(String(repeating: pad, count: column.length))
                }
            }
            let line = lineFragments.joined(separator: pad)
            lines.append(line)
        }

        return lines.map { line in
            // Lazy hack: trim the whitespace that we appended earlier.
            line.trimmingCharacters(in: .whitespaces)
        }
        .joined(separator: "\n")
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
