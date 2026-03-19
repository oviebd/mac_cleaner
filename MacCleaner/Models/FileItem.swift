import Foundation

struct FileItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let url: URL
    let name: String
    let size: Int64
    let isDirectory: Bool
    let lastModified: Date?
    let fileExtension: String

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var icon: String {
        if isDirectory { return "folder.fill" }
        switch fileExtension.lowercased() {
        case "swift", "h", "m", "cpp", "py", "js", "ts": return "doc.text.fill"
        case "png", "jpg", "jpeg", "gif", "heic", "webp": return "photo.fill"
        case "mp4", "mov", "avi", "mkv": return "film.fill"
        case "mp3", "wav", "aac", "flac": return "music.note"
        case "zip", "tar", "gz", "rar", "7z": return "doc.zipper"
        case "pdf": return "doc.richtext.fill"
        case "dmg", "iso": return "externaldrive.fill"
        case "app": return "app.gift.fill"
        case "log": return "doc.text.fill"
        default: return "doc.fill"
        }
    }

    init(url: URL, size: Int64, isDirectory: Bool, lastModified: Date? = nil, fileExtension: String = "") {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.size = size
        self.isDirectory = isDirectory
        self.lastModified = lastModified
        self.fileExtension = fileExtension.isEmpty ? url.pathExtension : fileExtension
    }
}
