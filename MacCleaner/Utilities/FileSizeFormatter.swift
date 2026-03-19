import Foundation

nonisolated(unsafe) let sharedByteFormatter: ByteCountFormatter = {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter
}()

enum FileSizeFormatter {
    static func format(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    static func formatDetailed(_ bytes: Int64) -> String {
        sharedByteFormatter.string(fromByteCount: bytes)
    }

    static func percentage(used: Int64, total: Int64) -> Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total) * 100.0
    }
}
