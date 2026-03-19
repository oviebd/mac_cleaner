import Foundation
import SwiftUI

struct CleanupCategory: Identifiable, Sendable {
    let id: UUID
    let name: String
    let systemImage: String
    let description: String
    let paths: [URL]
    let color: Color
    var totalSize: Int64
    var fileCount: Int
    var isSelected: Bool
    var isScanned: Bool

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    init(
        name: String,
        systemImage: String,
        description: String,
        paths: [URL],
        color: Color = .blue
    ) {
        self.id = UUID()
        self.name = name
        self.systemImage = systemImage
        self.description = description
        self.paths = paths
        self.color = color
        self.totalSize = 0
        self.fileCount = 0
        self.isSelected = false
        self.isScanned = false
    }

    nonisolated static var defaultCategories: [CleanupCategory] {
        let home = FileManager.default.homeDirectoryForCurrentUser

        return [
            CleanupCategory(
                name: "System Cache",
                systemImage: "internaldrive.fill",
                description: "Cached files from system and applications",
                paths: [home.appendingPathComponent("Library/Caches")],
                color: .orange
            ),
            CleanupCategory(
                name: "System Logs",
                systemImage: "doc.text.fill",
                description: "System and application log files",
                paths: [home.appendingPathComponent("Library/Logs")],
                color: .gray
            ),
            CleanupCategory(
                name: "Trash",
                systemImage: "trash.fill",
                description: "Files in the Trash",
                paths: [home.appendingPathComponent(".Trash")],
                color: .red
            ),
            CleanupCategory(
                name: "Xcode DerivedData",
                systemImage: "hammer.fill",
                description: "Xcode build artifacts and indexes",
                paths: [home.appendingPathComponent("Library/Developer/Xcode/DerivedData")],
                color: .blue
            ),
            CleanupCategory(
                name: "Xcode Archives",
                systemImage: "archivebox.fill",
                description: "Old Xcode archive builds",
                paths: [home.appendingPathComponent("Library/Developer/Xcode/Archives")],
                color: .indigo
            ),
            CleanupCategory(
                name: "iOS Simulators",
                systemImage: "iphone.gen3",
                description: "iOS Simulator data and runtimes",
                paths: [home.appendingPathComponent("Library/Developer/CoreSimulator")],
                color: .cyan
            ),
            CleanupCategory(
                name: "iOS Device Support",
                systemImage: "ipad.and.iphone",
                description: "Debug symbols for connected devices",
                paths: [home.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport")],
                color: .teal
            ),
            CleanupCategory(
                name: "Swift Package Cache",
                systemImage: "shippingbox.fill",
                description: "Swift Package Manager resolved packages",
                paths: [home.appendingPathComponent("Library/Caches/org.swift.swiftpm")],
                color: .orange
            ),
            CleanupCategory(
                name: "CocoaPods Cache",
                systemImage: "leaf.fill",
                description: "Cached CocoaPods dependencies",
                paths: [home.appendingPathComponent("Library/Caches/CocoaPods")],
                color: .green
            ),
            CleanupCategory(
                name: "Gradle Cache",
                systemImage: "square.stack.3d.up.fill",
                description: "Gradle build system cache",
                paths: [home.appendingPathComponent(".gradle/caches")],
                color: .mint
            ),
            CleanupCategory(
                name: "Browser Cache",
                systemImage: "globe",
                description: "Safari, Chrome, and Firefox caches",
                paths: [
                    home.appendingPathComponent("Library/Caches/com.apple.Safari"),
                    home.appendingPathComponent("Library/Caches/Google/Chrome"),
                    home.appendingPathComponent("Library/Caches/Firefox/Profiles"),
                ],
                color: .purple
            ),
        ]
    }
}
