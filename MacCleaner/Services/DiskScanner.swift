import Foundation

struct ScanProgress: Sendable {
    let filesScanned: Int
    let directoriesScanned: Int
    let totalSize: Int64
    let currentPath: String
}

actor DiskScanner {
    private let fileManager = FileManager()
    private let resourceKeys: [URLResourceKey] = AppConstants.scanResourceKeys
    private let maxParallel = AppConstants.maxParallelScans

    // MARK: - Multi-Stage High-Performance Scan

    /// Stage 1: Discover top-level directories for parallel scanning
    func discoverTopDirectories(at url: URL) throws -> [URL] {
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        return contents.filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        }
    }

    /// Stage 2+3+4: Parallel scan with incremental aggregation and streaming results
    func scanTree(
        at rootURL: URL,
        maxDepth: Int = 6,
        onProgress: @Sendable @escaping (ScanProgress) -> Void
    ) async throws -> DiskUsageNode {
        var filesScanned = 0
        var dirsScanned = 0
        var accumulatedSize: Int64 = 0

        func reportProgress(path: String) {
            onProgress(ScanProgress(
                filesScanned: filesScanned,
                directoriesScanned: dirsScanned,
                totalSize: accumulatedSize,
                currentPath: path
            ))
        }

        let topDirs: [URL]
        do {
            topDirs = try discoverTopDirectories(at: rootURL)
        } catch {
            return DiskUsageNode(name: rootURL.lastPathComponent, url: rootURL, isDirectory: true)
        }

        // Scan top-level files (non-directories)
        var rootFiles: [DiskUsageNode] = []
        let allContents = try? fileManager.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        )
        for item in allContents ?? [] {
            guard let values = try? item.resourceValues(forKeys: Set(resourceKeys)) else { continue }
            if values.isDirectory != true {
                let size = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
                rootFiles.append(DiskUsageNode(
                    name: item.lastPathComponent,
                    url: item,
                    isDirectory: false,
                    size: size,
                    depth: 1
                ))
                filesScanned += 1
                accumulatedSize += size
            }
        }

        // Parallel scan of top-level directories using TaskGroup
        let children = try await withThrowingTaskGroup(of: DiskUsageNode.self, returning: [DiskUsageNode].self) { group in
            for dir in topDirs {
                group.addTask { [self] in
                    try await self.scanDirectoryRecursive(
                        url: dir,
                        currentDepth: 1,
                        maxDepth: maxDepth,
                        filesCount: &filesScanned,
                        dirsCount: &dirsScanned,
                        totalSize: &accumulatedSize,
                        progressCallback: { path in reportProgress(path: path) }
                    )
                }
            }

            var results: [DiskUsageNode] = []
            for try await node in group {
                results.append(node)
                reportProgress(path: node.url.path)
            }
            return results
        }

        let allChildren = (children + rootFiles).sorted { $0.size > $1.size }
        let totalSize = allChildren.reduce(Int64(0)) { $0 + $1.size }

        return DiskUsageNode(
            name: rootURL.lastPathComponent,
            url: rootURL,
            isDirectory: true,
            size: totalSize,
            children: allChildren,
            depth: 0
        )
    }

    /// Core recursive directory scanner using FileManager enumerator
    private func scanDirectoryRecursive(
        url: URL,
        currentDepth: Int,
        maxDepth: Int,
        filesCount: inout Int,
        dirsCount: inout Int,
        totalSize: inout Int64,
        progressCallback: (String) -> Void
    ) throws -> DiskUsageNode {
        dirsCount += 1

        guard currentDepth <= maxDepth else {
            let size = fastDirectorySize(url)
            totalSize += size
            return DiskUsageNode(name: url.lastPathComponent, url: url, isDirectory: true, size: size, depth: currentDepth)
        }

        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles]
            )
        } catch {
            return DiskUsageNode(name: url.lastPathComponent, url: url, isDirectory: true, depth: currentDepth)
        }

        var children: [DiskUsageNode] = []
        var dirSize: Int64 = 0

        for item in contents {
            guard let values = try? item.resourceValues(forKeys: Set(resourceKeys)) else { continue }

            if values.isDirectory == true {
                let childNode = try scanDirectoryRecursive(
                    url: item,
                    currentDepth: currentDepth + 1,
                    maxDepth: maxDepth,
                    filesCount: &filesCount,
                    dirsCount: &dirsCount,
                    totalSize: &totalSize,
                    progressCallback: progressCallback
                )
                children.append(childNode)
                dirSize += childNode.size
            } else {
                let fileSize = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
                children.append(DiskUsageNode(
                    name: item.lastPathComponent,
                    url: item,
                    isDirectory: false,
                    size: fileSize,
                    depth: currentDepth + 1
                ))
                dirSize += fileSize
                filesScanned(count: &filesCount, total: &totalSize, size: fileSize)
            }

            if filesCount % AppConstants.scanBatchSize == 0 {
                progressCallback(item.path)
            }
        }

        children.sort { $0.size > $1.size }

        return DiskUsageNode(
            name: url.lastPathComponent,
            url: url,
            isDirectory: true,
            size: dirSize,
            children: children,
            depth: currentDepth
        )
    }

    private func filesScanned(count: inout Int, total: inout Int64, size: Int64) {
        count += 1
        total += size
    }

    /// Fast directory size using enumerator (avoids building tree)
    func fastDirectorySize(_ url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileSizeKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else { return 0 }

        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey]) else { continue }
            totalSize += Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
        }
        return totalSize
    }

    /// Scan a single cleanup category path and return its size and file count
    func scanCategoryPath(_ url: URL) -> (size: Int64, count: Int) {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileSizeKey, .isRegularFileKey],
            options: [],
            errorHandler: nil
        ) else { return (0, 0) }

        var totalSize: Int64 = 0
        var fileCount = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey, .isRegularFileKey]) else { continue }
            if values.isRegularFile == true {
                totalSize += Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
                fileCount += 1
            }
        }
        return (totalSize, fileCount)
    }

    /// Scan all cleanup categories in parallel
    func scanCleanupCategories(_ categories: [CleanupCategory]) async -> [CleanupCategory] {
        await withTaskGroup(of: (UUID, Int64, Int).self, returning: [CleanupCategory].self) { group in
            for category in categories {
                group.addTask { [self] in
                    var totalSize: Int64 = 0
                    var totalCount = 0
                    for path in category.paths {
                        let (size, count) = await self.scanCategoryPath(path)
                        totalSize += size
                        totalCount += count
                    }
                    return (category.id, totalSize, totalCount)
                }
            }

            var updatedCategories = categories
            for await (id, size, count) in group {
                if let index = updatedCategories.firstIndex(where: { $0.id == id }) {
                    updatedCategories[index].totalSize = size
                    updatedCategories[index].fileCount = count
                    updatedCategories[index].isScanned = true
                }
            }
            return updatedCategories
        }
    }

    // MARK: - Disk Space Info

    nonisolated func getDiskSpaceInfo() -> (total: Int64, free: Int64, used: Int64) {
        do {
            let values = try URL(fileURLWithPath: "/").resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey,
            ])
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free = values.volumeAvailableCapacityForImportantUsage ?? 0
            let used = total - free
            return (total, free, used)
        } catch {
            return (0, 0, 0)
        }
    }
}
