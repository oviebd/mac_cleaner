import Foundation

@Observable
class DiskMapViewModel {
    var rootNode: DiskUsageNode?
    var currentNode: DiskUsageNode?
    var breadcrumbs: [DiskUsageNode] = []
    var isScanning = false
    var scanProgress = ScanProgress(filesScanned: 0, directoriesScanned: 0, totalSize: 0, currentPath: "")
    var hoveredNode: DiskUsageNode?
    var topFolders: [DiskUsageNode] = []

    func scan() async {
        isScanning = true
        let scanner = DiskScanner()
        let home = FileManager.default.homeDirectoryForCurrentUser

        do {
            let node = try await scanner.scanTree(at: home, maxDepth: 5) { [weak self] progress in
                Task { @MainActor in
                    self?.scanProgress = progress
                }
            }
            rootNode = node
            currentNode = node
            breadcrumbs = [node]
            topFolders = Array(node.sortedChildren.prefix(20))
        } catch {
            print("Scan failed: \(error)")
        }

        isScanning = false
    }

    func navigateTo(_ node: DiskUsageNode) {
        guard node.isDirectory, !node.children.isEmpty else { return }
        currentNode = node
        if let idx = breadcrumbs.firstIndex(where: { $0.id == node.id }) {
            breadcrumbs = Array(breadcrumbs.prefix(through: idx))
        } else {
            breadcrumbs.append(node)
        }
    }

    func navigateUp() {
        guard breadcrumbs.count > 1 else { return }
        breadcrumbs.removeLast()
        currentNode = breadcrumbs.last
    }

    func navigateToRoot() {
        guard let root = rootNode else { return }
        currentNode = root
        breadcrumbs = [root]
    }
}
