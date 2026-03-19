import Foundation
import CryptoKit

actor DuplicateFinder {
    private let fileManager = FileManager()

    struct DuplicateProgress: Sendable {
        let phase: Phase
        let current: Int
        let total: Int

        enum Phase: Sendable {
            case groupingBySize
            case hashing
            case complete
        }
    }

    /// Find duplicate files using size-then-hash algorithm
    func findDuplicates(
        in directories: [URL],
        minSize: Int64 = 1024, // Skip tiny files
        onProgress: @Sendable @escaping (DuplicateProgress) -> Void
    ) async throws -> [DuplicateGroup] {
        onProgress(DuplicateProgress(phase: .groupingBySize, current: 0, total: 0))

        // Step 1: Collect all files and group by size
        var filesBySize: [Int64: [URL]] = [:]
        var totalFiles = 0

        for directory in directories {
            guard let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey, .isDirectoryKey],
                options: [.skipsHiddenFiles],
                errorHandler: nil
            ) else { continue }

            for case let fileURL as URL in enumerator {
                guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]) else { continue }
                guard values.isRegularFile == true else { continue }
                let size = Int64(values.fileSize ?? 0)
                guard size >= minSize else { continue }

                filesBySize[size, default: []].append(fileURL)
                totalFiles += 1

                if totalFiles % 1000 == 0 {
                    onProgress(DuplicateProgress(phase: .groupingBySize, current: totalFiles, total: 0))
                }
            }
        }

        // Filter to only sizes with multiple files
        let potentialDuplicates = filesBySize.filter { $0.value.count > 1 }
        let totalToHash = potentialDuplicates.values.reduce(0) { $0 + $1.count }
        var hashed = 0

        onProgress(DuplicateProgress(phase: .hashing, current: 0, total: totalToHash))

        // Step 2: Hash files with identical sizes
        var hashGroups: [String: [FileItem]] = [:]

        for (fileSize, urls) in potentialDuplicates {
            // First pass: compare first 4KB for quick rejection
            var partialHashGroups: [String: [URL]] = [:]
            for url in urls {
                if let partialHash = partialFileHash(url: url, maxBytes: 4096) {
                    partialHashGroups[partialHash, default: []].append(url)
                }
                hashed += 1
                if hashed % 50 == 0 {
                    onProgress(DuplicateProgress(phase: .hashing, current: hashed, total: totalToHash))
                }
            }

            // Second pass: full hash only for files with matching partial hashes
            for (_, matchingURLs) in partialHashGroups where matchingURLs.count > 1 {
                for url in matchingURLs {
                    if let fullHash = fullFileHash(url: url) {
                        let item = FileItem(
                            url: url,
                            size: fileSize,
                            isDirectory: false,
                            lastModified: (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate,
                            fileExtension: url.pathExtension
                        )
                        hashGroups[fullHash, default: []].append(item)
                    }
                }
            }
        }

        onProgress(DuplicateProgress(phase: .complete, current: totalToHash, total: totalToHash))

        // Step 3: Build duplicate groups
        return hashGroups
            .filter { $0.value.count > 1 }
            .map { (hash, files) in
                DuplicateGroup(hash: hash, fileSize: files.first?.size ?? 0, files: files)
            }
            .sorted { $0.totalWastedSpace > $1.totalWastedSpace }
    }

    // MARK: - Hashing

    private func partialFileHash(url: URL, maxBytes: Int) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        let data = handle.readData(ofLength: maxBytes)
        guard !data.isEmpty else { return nil }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func fullFileHash(url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        var hasher = SHA256()
        let bufferSize = AppConstants.hashBufferSize
        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: bufferSize)
            guard !data.isEmpty else { return false }
            hasher.update(data: data)
            return true
        }) {}

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
