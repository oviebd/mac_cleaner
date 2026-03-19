import SwiftUI

struct CleanupView: View {
    @State private var viewModel = CleanupViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isScanning {
                        scanningSection
                    }
                    categoriesGrid
                }
                .padding(24)
            }
            Divider()
            bottomBar
        }
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .task {
            if !viewModel.scanComplete {
                await viewModel.scan()
            }
        }
        .sheet(isPresented: $viewModel.showDeleteConfirmation) {
            DeleteConfirmationView(
                title: "Clean Selected Items",
                message: "You are about to remove \(viewModel.formattedCleanableSize) of files from \(viewModel.selectedCount) categories.",
                size: viewModel.totalCleanableSize,
                onConfirm: {
                    Task { await viewModel.performCleanup() }
                },
                onCancel: {
                    viewModel.showDeleteConfirmation = false
                }
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Smart Cleanup")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Identify and remove unnecessary files")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if viewModel.scanComplete {
                VStack(alignment: .trailing) {
                    Text("Total Found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(FileSizeFormatter.format(viewModel.totalScannedSize))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(24)
    }

    // MARK: - Scanning

    private var scanningSection: some View {
        HStack(spacing: 16) {
            ScanningAnimationView()
                .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 4) {
                Text("Scanning your disk...")
                    .font(.headline)
                Text("Analyzing cleanup targets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ProgressView()
        }
        .padding(16)
        .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Categories Grid

    private var categoriesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ], spacing: 12) {
            ForEach(viewModel.categories) { category in
                CategoryCardView(
                    category: category,
                    onToggle: { viewModel.toggleCategory(category.id) }
                )
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button("Select All") { viewModel.selectAll() }
                .disabled(!viewModel.scanComplete)
            Button("Deselect All") { viewModel.deselectAll() }
                .disabled(!viewModel.scanComplete)

            Spacer()

            if viewModel.isCleaning {
                ProgressView()
                    .controlSize(.small)
                Text("Cleaning...")
            } else {
                if viewModel.totalCleanableSize > 0 {
                    Text("\(viewModel.formattedCleanableSize) selected")
                        .foregroundStyle(.secondary)
                }
                Button {
                    viewModel.confirmCleanup()
                } label: {
                    Label("Clean Now", systemImage: "trash.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(viewModel.totalCleanableSize == 0)
            }

            Button {
                Task { await viewModel.scan() }
            } label: {
                Label("Rescan", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isScanning)
        }
        .padding(16)
    }
}
