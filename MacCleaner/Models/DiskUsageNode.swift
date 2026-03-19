import Foundation
import SwiftUI

struct DiskUsageNode: Identifiable, Sendable {
    let id: UUID
    let name: String
    let url: URL
    let isDirectory: Bool
    var size: Int64
    var children: [DiskUsageNode]
    var depth: Int

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var color: Color {
        let colors: [Color] = [
            .blue, .purple, .orange, .green, .pink,
            .cyan, .yellow, .indigo, .mint, .teal,
        ]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }

    var sortedChildren: [DiskUsageNode] {
        children.sorted { $0.size > $1.size }
    }

    init(
        name: String,
        url: URL,
        isDirectory: Bool,
        size: Int64 = 0,
        children: [DiskUsageNode] = [],
        depth: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.isDirectory = isDirectory
        self.size = size
        self.children = children
        self.depth = depth
    }
}
