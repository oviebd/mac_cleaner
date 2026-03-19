import Foundation

actor LargeFileDetector {
    private let fileManager = FileManager()

    struct DetectionProgress: Sendable {
        let filesScanned: Int
        let largeFilesFound: Int
        let currentPath: String
    }

    /// Find files above the given size threshold in the specified directories
    func findLargeFiles(
        in directories: [URL],
        threshold: Int64 = AppConstants.defaultLargeFileThreshold,
        onProgress: @Sendable @escaping (DetectionProgress) -> Void
    ) async throws -> [FileItem] {
        var largeFiles: [FileItem] = []

        await withTaskGroup(of: [FileItem].self) { group in
            for directory in directories {
                group.addTask { [self] in
                    await self.scanForLargeFiles(in: directory, threshold: threshold, onProgress: onProgress)
                }
            }

            for await files in group {
                largeFiles.append(contentsOf: files)
            }
        }

        return largeFiles.sorted { $0.size > $1.size }
    }

    private func scanForLargeFiles(
        in directory: URL,
        threshold: Int64,
        onProgress: @Sendable @escaping (DetectionProgress) -> Void
    ) -> [FileItem] {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: AppConstants.scanResourceKeys,
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else { return [] }

        var results: [FileItem] = []
        var scanned = 0

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: Set(AppConstants.scanResourceKeys.map { $0 })) else { continue }
            guard values.isRegularFile == true else { continue }

            scanned += 1
            let size = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)

            if size >= threshold {
                let item = FileItem(
                    url: fileURL,
                    size: size,
                    isDirectory: false,
                    lastModified: values.contentModificationDate,
                    fileExtension: fileURL.pathExtension
                )
                results.append(item)

                onProgress(DetectionProgress(
                    filesScanned: scanned,
                    largeFilesFound: results.count,
                    currentPath: fileURL.path
                ))
            } else if scanned % 500 == 0 {
                onProgress(DetectionProgress(
                    filesScanned: scanned,
                    largeFilesFound: results.count,
                    currentPath: fileURL.path
                ))
            }
        }

        return results
    }

    /// Get top N largest files from the given directories
    func topLargestFiles(
        in directories: [URL],
        count: Int = 20
    ) async -> [FileItem] {
        var allFiles: [FileItem] = []

        await withTaskGroup(of: [FileItem].self) { group in
            for directory in directories {
                group.addTask { [self] in
                    await self.collectAllFiles(in: directory)
                }
            }
            for await files in group {
                allFiles.append(contentsOf: files)
            }
        }

        return Array(allFiles.sorted { $0.size > $1.size }.prefix(count))
    }

    private func collectAllFiles(in directory: URL) -> [FileItem] {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .totalFileAllocatedSizeKey, .isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else { return [] }

        var files: [FileItem] = []
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .totalFileAllocatedSizeKey, .isRegularFileKey, .contentModificationDateKey]) else { continue }
            guard values.isRegularFile == true else { continue }
            let size = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            guard size > 0 else { continue }
            files.append(FileItem(
                url: fileURL,
                size: size,
                isDirectory: false,
                lastModified: values.contentModificationDate,
                fileExtension: fileURL.pathExtension
            ))
        }
        return files
    }
}
