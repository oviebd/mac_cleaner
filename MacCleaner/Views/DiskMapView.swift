import SwiftUI

struct DiskMapView: View {
    @State private var viewModel = DiskMapViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if viewModel.isScanning {
                scanningOverlay
            } else if let currentNode = viewModel.currentNode {
                HSplitView {
                    chartPanel(node: currentNode)
                        .frame(minWidth: 400)
                    detailPanel(node: currentNode)
                        .frame(minWidth: 250, idealWidth: 300)
                }
            } else {
                emptyState
            }
        }
        .background(Color(.windowBackgroundColor).opacity(0.5))
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Disk Map")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Visualize how your disk space is used")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await viewModel.scan() }
            } label: {
                Label("Scan", systemImage: "magnifyingglass")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isScanning)
        }
        .padding(24)
    }

    // MARK: - Scanning Overlay

    private var scanningOverlay: some View {
        VStack(spacing: 24) {
            Spacer()
            ScanningAnimationView()
                .frame(width: 100, height: 100)
            VStack(spacing: 8) {
                Text("Scanning your disk...")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("\(viewModel.scanProgress.filesScanned) files scanned")
                    .foregroundStyle(.secondary)
                Text(FileSizeFormatter.format(viewModel.scanProgress.totalSize))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                Text(viewModel.scanProgress.currentPath)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sunburst Chart Panel

    private func chartPanel(node: DiskUsageNode) -> some View {
        VStack(spacing: 12) {
            breadcrumbBar

            SunburstChartView(
                node: node,
                onSelect: { selected in
                    withAnimation(.spring(duration: 0.4)) {
                        viewModel.navigateTo(selected)
                    }
                },
                onHover: { hovered in
                    viewModel.hoveredNode = hovered
                }
            )
            .padding(20)

            if let hovered = viewModel.hoveredNode {
                HStack {
                    Image(systemName: hovered.isDirectory ? "folder.fill" : "doc.fill")
                        .foregroundStyle(hovered.color)
                    Text(hovered.name)
                        .fontWeight(.medium)
                    Spacer()
                    Text(hovered.formattedSize)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .transition(.opacity)
            }
        }
    }

    private var breadcrumbBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(viewModel.breadcrumbs.enumerated()), id: \.element.id) { index, crumb in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Button(crumb.name) {
                        withAnimation(.spring(duration: 0.4)) {
                            viewModel.navigateTo(crumb)
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(index == viewModel.breadcrumbs.count - 1 ? .primary : .secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Detail Panel

    private func detailPanel(node: DiskUsageNode) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(node.name)
                    .font(.headline)
                Text(node.formattedSize)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                Text("\(node.children.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)

            Divider()

            List(node.sortedChildren) { child in
                Button {
                    if child.isDirectory && !child.children.isEmpty {
                        withAnimation(.spring(duration: 0.4)) {
                            viewModel.navigateTo(child)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: child.isDirectory ? "folder.fill" : "doc.fill")
                            .foregroundStyle(child.color)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(child.name)
                                .lineLimit(1)
                                .font(.subheadline)
                            if node.size > 0 {
                                ProgressView(value: Double(child.size), total: Double(node.size))
                                    .tint(child.color)
                            }
                        }
                        Spacer()
                        Text(child.formattedSize)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 60))
                .foregroundStyle(.purple.opacity(0.5))
            Text("No scan data yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Click Scan to visualize your disk usage")
                .foregroundStyle(.secondary)
            Button {
                Task { await viewModel.scan() }
            } label: {
                Label("Start Scan", systemImage: "magnifyingglass")
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
