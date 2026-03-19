import Foundation

enum AppConstants {
    static let appName = "Mac Storage Optimizer"
    static let defaultLargeFileThreshold: Int64 = 100 * 1024 * 1024 // 100 MB
    static let maxParallelScans = 8
    static let scanBatchSize = 500
    static let hashBufferSize = 64 * 1024 // 64 KB for hashing

    static let scanResourceKeys: [URLResourceKey] = [
        .fileSizeKey,
        .totalFileAllocatedSizeKey,
        .isDirectoryKey,
        .isRegularFileKey,
        .contentModificationDateKey,
        .typeIdentifierKey,
    ]

    static let safeDirectories: [String] = [
        "Library/Caches",
        "Library/Logs",
        ".Trash",
        "Library/Developer/Xcode/DerivedData",
        "Library/Developer/Xcode/Archives",
        "Library/Developer/CoreSimulator",
        "Library/Developer/Xcode/iOS DeviceSupport",
        "Library/Caches/org.swift.swiftpm",
        "Library/Caches/CocoaPods",
        ".gradle/caches",
        "Library/Caches/com.apple.Safari",
        "Library/Caches/Google/Chrome",
        "Library/Caches/Firefox/Profiles",
    ]

    nonisolated static let protectedPaths: Set<String> = [
        "/System",
        "/Library",
        "/usr",
        "/bin",
        "/sbin",
        "/private",
        "/Applications",
    ]

    static func isSafePath(_ url: URL) -> Bool {
        let path = url.path
        for protected in protectedPaths {
            if path.hasPrefix(protected) { return false }
        }
        return true
    }

    static func isWithinUserHome(_ url: URL) -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return url.path.hasPrefix(home)
    }
}
