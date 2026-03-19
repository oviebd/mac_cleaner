import Foundation

actor CleanupManager {
    private let fileManager = FileManager()

    enum CleanupError: LocalizedError, Sendable {
        case unsafePath(String)
        case deletionFailed(String)
        case accessDenied(String)

        var errorDescription: String? {
            switch self {
            case .unsafePath(let path): "Refusing to delete protected path: \(path)"
            case .deletionFailed(let msg): "Deletion failed: \(msg)"
            case .accessDenied(let path): "Access denied for: \(path)"
            }
        }
    }

    struct CleanupResult: Sendable {
        let freedSpace: Int64
        let deletedCount: Int
        let failedCount: Int
        let errors: [String]
    }

    /// Move files to Trash (safer than permanent deletion)
    func moveToTrash(_ urls: [URL]) async throws -> CleanupResult {
        var freedSpace: Int64 = 0
        var deletedCount = 0
        var failedCount = 0
        var errors: [String] = []

        for url in urls {
            guard validatePath(url) else {
                errors.append("Skipped protected path: \(url.path)")
                failedCount += 1
                continue
            }

            do {
                let size = fileSize(at: url)
                var resultURL: NSURL?
                try fileManager.trashItem(at: url, resultingItemURL: &resultURL)
                freedSpace += size
                deletedCount += 1
            } catch {
                errors.append("Failed to trash \(url.lastPathComponent): \(error.localizedDescription)")
                failedCount += 1
            }
        }

        return CleanupResult(freedSpace: freedSpace, deletedCount: deletedCount, failedCount: failedCount, errors: errors)
    }

    /// Permanently delete files
    func deleteFiles(_ urls: [URL]) async throws -> CleanupResult {
        var freedSpace: Int64 = 0
        var deletedCount = 0
        var failedCount = 0
        var errors: [String] = []

        for url in urls {
            guard validatePath(url) else {
                errors.append("Skipped protected path: \(url.path)")
                failedCount += 1
                continue
            }

            do {
                let size = fileSize(at: url)
                try fileManager.removeItem(at: url)
                freedSpace += size
                deletedCount += 1
            } catch {
                errors.append("Failed to delete \(url.lastPathComponent): \(error.localizedDescription)")
                failedCount += 1
            }
        }

        return CleanupResult(freedSpace: freedSpace, deletedCount: deletedCount, failedCount: failedCount, errors: errors)
    }

    /// Delete contents of a directory without removing the directory itself
    func cleanDirectory(_ url: URL) async throws -> CleanupResult {
        guard validatePath(url) else {
            throw CleanupError.unsafePath(url.path)
        }

        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
        } catch {
            throw CleanupError.accessDenied(url.path)
        }

        return try await deleteFiles(contents)
    }

    /// Clean multiple category paths
    func cleanCategories(_ categories: [CleanupCategory]) async -> CleanupResult {
        var totalFreed: Int64 = 0
        var totalDeleted = 0
        var totalFailed = 0
        var allErrors: [String] = []

        for category in categories where category.isSelected {
            for path in category.paths {
                guard fileManager.fileExists(atPath: path.path) else { continue }
                do {
                    let result = try await cleanDirectory(path)
                    totalFreed += result.freedSpace
                    totalDeleted += result.deletedCount
                    totalFailed += result.failedCount
                    allErrors.append(contentsOf: result.errors)
                } catch {
                    allErrors.append("Error cleaning \(category.name): \(error.localizedDescription)")
                    totalFailed += 1
                }
            }
        }

        return CleanupResult(freedSpace: totalFreed, deletedCount: totalDeleted, failedCount: totalFailed, errors: allErrors)
    }

    // MARK: - Validation

    private func validatePath(_ url: URL) -> Bool {
        let path = url.path
        for protected in AppConstants.protectedPaths {
            if path == protected || (path.hasPrefix(protected + "/") && !path.contains(FileManager.default.homeDirectoryForCurrentUser.path)) {
                return false
            }
        }
        return AppConstants.isWithinUserHome(url)
    }

    private func fileSize(at url: URL) -> Int64 {
        guard let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey, .isDirectoryKey]) else {
            return 0
        }
        if values.isDirectory == true {
            return directorySize(at: url)
        }
        return Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
    }

    private func directorySize(at url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileSizeKey],
            options: [],
            errorHandler: nil
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey]) {
                total += Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            }
        }
        return total
    }
}
