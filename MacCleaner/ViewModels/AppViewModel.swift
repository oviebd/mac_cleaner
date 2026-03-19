import Foundation
import SwiftUI

enum SidebarTab: String, CaseIterable, Identifiable, Sendable {
    case dashboard = "Dashboard"
    case cleanup = "Cleanup"
    case diskMap = "Disk Map"
    case largeFiles = "Large Files"
    case duplicates = "Duplicates"
    case settings = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .dashboard: "gauge.with.dots.needle.67percent"
        case .cleanup: "bubbles.and.sparkles.fill"
        case .diskMap: "chart.pie.fill"
        case .largeFiles: "doc.circle.fill"
        case .duplicates: "doc.on.doc.fill"
        case .settings: "gearshape.fill"
        }
    }

    var color: Color {
        switch self {
        case .dashboard: .blue
        case .cleanup: .green
        case .diskMap: .purple
        case .largeFiles: .orange
        case .duplicates: .pink
        case .settings: .gray
        }
    }
}

@Observable
class AppViewModel {
    var selectedTab: SidebarTab = .dashboard

    var totalDiskSpace: Int64 = 0
    var usedDiskSpace: Int64 = 0
    var freeDiskSpace: Int64 = 0

    var formattedTotal: String { FileSizeFormatter.format(totalDiskSpace) }
    var formattedUsed: String { FileSizeFormatter.format(usedDiskSpace) }
    var formattedFree: String { FileSizeFormatter.format(freeDiskSpace) }
    var usagePercentage: Double { FileSizeFormatter.percentage(used: usedDiskSpace, total: totalDiskSpace) }

    func loadDiskInfo() {
        let scanner = DiskScanner()
        let info = scanner.getDiskSpaceInfo()
        totalDiskSpace = info.total
        freeDiskSpace = info.free
        usedDiskSpace = info.used
    }
}
