import SwiftUI

struct DashboardView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var topFolders: [DiskUsageNode] = []
    @State private var isLoadingFolders = false
    @State private var animateGauge = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                diskOverviewCard
                quickActionsSection
                topFoldersSection
            }
            .padding(24)
        }
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .onAppear {
            appViewModel.loadDiskInfo()
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateGauge = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Overview of your disk usage")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                appViewModel.loadDiskInfo()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
    }

    // MARK: - Disk Overview

    private var diskOverviewCard: some View {
        HStack(spacing: 32) {
            gaugeView
            diskStatsView
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var gaugeView: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 20)
                .frame(width: 160, height: 160)

            Circle()
                .trim(from: 0, to: animateGauge ? appViewModel.usagePercentage / 100 : 0)
                .stroke(
                    AngularGradient(
                        colors: [.green, .yellow, .orange, .red],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(Int(appViewModel.usagePercentage))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("Used")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var diskStatsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            statRow(title: "Total Capacity", value: appViewModel.formattedTotal, icon: "internaldrive.fill", color: .blue)
            Divider()
            statRow(title: "Used Space", value: appViewModel.formattedUsed, icon: "chart.bar.fill", color: .orange)
            Divider()
            statRow(title: "Free Space", value: appViewModel.formattedFree, icon: "checkmark.circle.fill", color: .green)

            StorageBarView(
                used: appViewModel.usedDiskSpace,
                total: appViewModel.totalDiskSpace,
                animate: animateGauge
            )
            .frame(height: 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                quickActionCard(
                    title: "Smart Cleanup",
                    subtitle: "Free up space quickly",
                    icon: "bubbles.and.sparkles.fill",
                    color: .green,
                    tab: .cleanup
                )
                quickActionCard(
                    title: "Disk Map",
                    subtitle: "Visualize disk usage",
                    icon: "chart.pie.fill",
                    color: .purple,
                    tab: .diskMap
                )
                quickActionCard(
                    title: "Large Files",
                    subtitle: "Find space hogs",
                    icon: "doc.circle.fill",
                    color: .orange,
                    tab: .largeFiles
                )
                quickActionCard(
                    title: "Duplicates",
                    subtitle: "Remove copies",
                    icon: "doc.on.doc.fill",
                    color: .pink,
                    tab: .duplicates
                )
            }
        }
    }

    private func quickActionCard(title: String, subtitle: String, icon: String, color: Color, tab: SidebarTab) -> some View {
        Button {
            appViewModel.selectedTab = tab
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(color.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Top Folders

    private var topFoldersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top 20 Largest Folders")
                    .font(.headline)
                Spacer()
                if isLoadingFolders {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button("Scan") {
                        Task { await loadTopFolders() }
                    }
                }
            }

            if topFolders.isEmpty && !isLoadingFolders {
                Text("Click Scan to discover your largest folders")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(Array(topFolders.enumerated()), id: \.element.id) { index, folder in
                        HStack(spacing: 12) {
                            Text("#\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .frame(width: 30)
                            Image(systemName: "folder.fill")
                                .foregroundStyle(folder.color)
                            VStack(alignment: .leading) {
                                Text(folder.name)
                                    .lineLimit(1)
                                Text(folder.url.path)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(folder.formattedSize)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func loadTopFolders() async {
        isLoadingFolders = true
        let scanner = DiskScanner()
        let home = FileManager.default.homeDirectoryForCurrentUser
        do {
            let tree = try await scanner.scanTree(at: home, maxDepth: 3) { _ in }
            topFolders = Array(tree.sortedChildren.filter(\.isDirectory).prefix(20))
        } catch {
            print("Failed to load top folders: \(error)")
        }
        isLoadingFolders = false
    }
}
