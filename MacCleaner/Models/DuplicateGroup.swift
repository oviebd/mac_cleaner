import Foundation

struct DuplicateGroup: Identifiable, Sendable {
    let id: UUID
    let hash: String
    let fileSize: Int64
    var files: [FileItem]

    var totalWastedSpace: Int64 {
        fileSize * Int64(max(0, files.count - 1))
    }

    var formattedWastedSpace: String {
        ByteCountFormatter.string(fromByteCount: totalWastedSpace, countStyle: .file)
    }

    init(hash: String, fileSize: Int64, files: [FileItem]) {
        self.id = UUID()
        self.hash = hash
        self.fileSize = fileSize
        self.files = files
    }
}
