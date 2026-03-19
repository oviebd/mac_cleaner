import Foundation

@Observable
class LargeFilesViewModel {
    var files: [FileItem] = []
    var isScanning = false
    var selectedFiles: Set<UUID> = []
    var threshold: Int64 = AppConstants.defaultLargeFileThreshold
    var showDeleteConfirmation = false
    var filesScanned = 0
    var currentPath = ""
    var isCleaning = false
    var cleanupResult: CleanupManager.CleanupResult?

    var sortedFiles: [FileItem] {
        files.sorted { $0.size > $1.size }
    }

    var totalSelectedSize: Int64 {
        files.filter { selectedFiles.contains($0.id) }.reduce(0) { $0 + $1.size }
    }

    var formattedSelectedSize: String {
        FileSizeFormatter.format(totalSelectedSize)
    }

    var thresholdOptions: [(String, Int64)] {
        [
            ("50 MB", 50 * 1024 * 1024),
            ("100 MB", 100 * 1024 * 1024),
            ("250 MB", 250 * 1024 * 1024),
            ("500 MB", 500 * 1024 * 1024),
            ("1 GB", 1024 * 1024 * 1024),
        ]
    }

    func scan() async {
        isScanning = true
        files = []
        selectedFiles = []

        let detector = LargeFileDetector()
        let home = FileManager.default.homeDirectoryForCurrentUser
        let directories = [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Movies"),
            home.appendingPathComponent("Music"),
            home.appendingPathComponent("Pictures"),
        ]

        do {
            let found = try await detector.findLargeFiles(
                in: directories,
                threshold: threshold
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.filesScanned = progress.filesScanned
                    self?.currentPath = progress.currentPath
                }
            }
            files = found
        } catch {
            print("Large file scan failed: \(error)")
        }

        isScanning = false
    }

    func toggleSelection(_ id: UUID) {
        if selectedFiles.contains(id) {
            selectedFiles.remove(id)
        } else {
            selectedFiles.insert(id)
        }
    }

    func selectAll() {
        selectedFiles = Set(files.map(\.id))
    }

    func deselectAll() {
        selectedFiles.removeAll()
    }

    func confirmDelete() {
        guard !selectedFiles.isEmpty else { return }
        showDeleteConfirmation = true
    }

    func deleteSelected() async {
        isCleaning = true
        showDeleteConfirmation = false

        let urls = files.filter { selectedFiles.contains($0.id) }.map(\.url)
        let manager = CleanupManager()

        do {
            let result = try await manager.moveToTrash(urls)
            cleanupResult = result
            files.removeAll { selectedFiles.contains($0.id) }
            selectedFiles.removeAll()
        } catch {
            print("Delete failed: \(error)")
        }

        isCleaning = false
    }
}
