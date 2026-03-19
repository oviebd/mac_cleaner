import Foundation

@Observable
class DuplicatesViewModel {
    var groups: [DuplicateGroup] = []
    var isScanning = false
    var progressPhase = ""
    var progressCurrent = 0
    var progressTotal = 0
    var selectedForDeletion: [UUID: Set<UUID>] = [:]
    var showDeleteConfirmation = false
    var isCleaning = false
    var cleanupResult: CleanupManager.CleanupResult?

    var totalWastedSpace: Int64 {
        groups.reduce(0) { $0 + $1.totalWastedSpace }
    }

    var totalSelectedSize: Int64 {
        var total: Int64 = 0
        for group in groups {
            guard let selected = selectedForDeletion[group.id] else { continue }
            for file in group.files where selected.contains(file.id) {
                total += file.size
            }
        }
        return total
    }

    var formattedWastedSpace: String {
        FileSizeFormatter.format(totalWastedSpace)
    }

    var formattedSelectedSize: String {
        FileSizeFormatter.format(totalSelectedSize)
    }

    func scan() async {
        isScanning = true
        groups = []
        selectedForDeletion = [:]

        let finder = DuplicateFinder()
        let home = FileManager.default.homeDirectoryForCurrentUser
        let directories = [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Pictures"),
        ]

        do {
            let found = try await finder.findDuplicates(
                in: directories
            ) { [weak self] progress in
                Task { @MainActor in
                    switch progress.phase {
                    case .groupingBySize:
                        self?.progressPhase = "Grouping files by size..."
                    case .hashing:
                        self?.progressPhase = "Computing file hashes..."
                    case .complete:
                        self?.progressPhase = "Complete"
                    }
                    self?.progressCurrent = progress.current
                    self?.progressTotal = progress.total
                }
            }
            groups = found
            autoSelectDuplicates()
        } catch {
            print("Duplicate scan failed: \(error)")
        }

        isScanning = false
    }

    /// Auto-select all but the first (oldest) file in each group for deletion
    private func autoSelectDuplicates() {
        for group in groups {
            let sorted = group.files.sorted { ($0.lastModified ?? .distantPast) < ($1.lastModified ?? .distantPast) }
            let toDelete = Set(sorted.dropFirst().map(\.id))
            selectedForDeletion[group.id] = toDelete
        }
    }

    func toggleFileSelection(groupID: UUID, fileID: UUID) {
        if selectedForDeletion[groupID]?.contains(fileID) == true {
            selectedForDeletion[groupID]?.remove(fileID)
        } else {
            selectedForDeletion[groupID, default: []].insert(fileID)
        }
    }

    func keepOnly(groupID: UUID, fileID: UUID) {
        guard let group = groups.first(where: { $0.id == groupID }) else { return }
        selectedForDeletion[groupID] = Set(group.files.map(\.id).filter { $0 != fileID })
    }

    func confirmDelete() {
        guard totalSelectedSize > 0 else { return }
        showDeleteConfirmation = true
    }

    func deleteSelected() async {
        isCleaning = true
        showDeleteConfirmation = false

        var urlsToDelete: [URL] = []
        for group in groups {
            guard let selected = selectedForDeletion[group.id] else { continue }
            for file in group.files where selected.contains(file.id) {
                urlsToDelete.append(file.url)
            }
        }

        let manager = CleanupManager()
        do {
            let result = try await manager.moveToTrash(urlsToDelete)
            cleanupResult = result
            // Remove deleted files from groups
            for i in groups.indices {
                let deleted = selectedForDeletion[groups[i].id] ?? []
                groups[i].files.removeAll { deleted.contains($0.id) }
            }
            groups.removeAll { $0.files.count <= 1 }
            selectedForDeletion.removeAll()
        } catch {
            print("Delete failed: \(error)")
        }

        isCleaning = false
    }
}
