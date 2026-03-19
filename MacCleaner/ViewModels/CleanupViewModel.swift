import Foundation

@Observable
class CleanupViewModel {
    var categories: [CleanupCategory] = CleanupCategory.defaultCategories
    var isScanning = false
    var isCleaning = false
    var scanComplete = false
    var showDeleteConfirmation = false
    var cleanupResult: CleanupManager.CleanupResult?

    var totalCleanableSize: Int64 {
        categories.filter(\.isSelected).reduce(0) { $0 + $1.totalSize }
    }

    var totalScannedSize: Int64 {
        categories.reduce(0) { $0 + $1.totalSize }
    }

    var selectedCount: Int {
        categories.filter(\.isSelected).count
    }

    var formattedCleanableSize: String {
        FileSizeFormatter.format(totalCleanableSize)
    }

    func scan() async {
        isScanning = true
        scanComplete = false

        let scanner = DiskScanner()
        let scanned = await scanner.scanCleanupCategories(categories)

        categories = scanned
        isScanning = false
        scanComplete = true
    }

    func toggleCategory(_ id: UUID) {
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories[index].isSelected.toggle()
        }
    }

    func selectAll() {
        for i in categories.indices where categories[i].totalSize > 0 {
            categories[i].isSelected = true
        }
    }

    func deselectAll() {
        for i in categories.indices {
            categories[i].isSelected = false
        }
    }

    func confirmCleanup() {
        guard totalCleanableSize > 0 else { return }
        showDeleteConfirmation = true
    }

    func performCleanup() async {
        isCleaning = true
        showDeleteConfirmation = false

        let manager = CleanupManager()
        let selectedCategories = categories.filter(\.isSelected)
        let result = await manager.cleanCategories(selectedCategories)

        cleanupResult = result
        isCleaning = false

        await scan()
    }
}
