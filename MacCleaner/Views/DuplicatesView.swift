import SwiftUI

struct DuplicatesView: View {
    @State private var viewModel = DuplicatesViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if viewModel.isScanning {
                scanningSection
            } else if viewModel.groups.isEmpty {
                emptyState
            } else {
                duplicatesList
            }

            Divider()
            bottomBar
        }
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .sheet(isPresented: $viewModel.showDeleteConfirmation) {
            DeleteConfirmationView(
                title: "Remove Duplicates",
                message: "You are about to move \(viewModel.formattedSelectedSize) of duplicate files to Trash.",
                size: viewModel.totalSelectedSize,
                onConfirm: {
                    Task { await viewModel.deleteSelected() }
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
                Text("Duplicate Files")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Find and remove duplicate files")
                    .foregroundStyle(.secondary)
            }
            Spacer()

            if !viewModel.groups.isEmpty {
                VStack(alignment: .trailing) {
                    Text("Wasted Space")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.formattedWastedSpace)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.pink)
                }
            }

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

    // MARK: - Scanning

    private var scanningSection: some View {
        VStack(spacing: 20) {
            Spacer()
            ScanningAnimationView()
                .frame(width: 80, height: 80)
            Text(viewModel.progressPhase)
                .font(.title3)
                .fontWeight(.medium)
            if viewModel.progressTotal > 0 {
                ProgressView(value: Double(viewModel.progressCurrent), total: Double(viewModel.progressTotal))
                    .frame(width: 200)
            } else {
                ProgressView()
            }
            Text("\(viewModel.progressCurrent) files processed")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Duplicates List

    private var duplicatesList: some View {
        List {
            ForEach(viewModel.groups) { group in
                Section {
                    ForEach(group.files) { file in
                        duplicateFileRow(group: group, file: file)
                    }
                } header: {
                    HStack {
                        Label("\(group.files.count) copies", systemImage: "doc.on.doc.fill")
                            .foregroundStyle(.pink)
                        Spacer()
                        Text("Each: \(FileSizeFormatter.format(group.fileSize))")
                            .foregroundStyle(.secondary)
                        Text("Wasted: \(group.formattedWastedSpace)")
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)
                    }
                    .font(.caption)
                }
            }
        }
    }

    private func duplicateFileRow(group: DuplicateGroup, file: FileItem) -> some View {
        let isSelected = viewModel.selectedForDeletion[group.id]?.contains(file.id) == true
        return HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .red : .secondary)
                .onTapGesture {
                    viewModel.toggleFileSelection(groupID: group.id, fileID: file.id)
                }

            Image(systemName: file.icon)
                .foregroundStyle(.pink)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .lineLimit(1)
                    .strikethrough(isSelected, color: .red)
                Text(file.url.deletingLastPathComponent().path)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let date = file.lastModified {
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Button("Keep Only") {
                viewModel.keepOnly(groupID: group.id, fileID: file.id)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 2)
        .opacity(isSelected ? 0.6 : 1.0)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if !viewModel.groups.isEmpty {
                Text("\(viewModel.groups.count) duplicate groups found")
                    .foregroundStyle(.secondary)
            }
            Spacer()

            if viewModel.isCleaning {
                ProgressView()
                    .controlSize(.small)
                Text("Moving to Trash...")
            } else if viewModel.totalSelectedSize > 0 {
                Text("\(viewModel.formattedSelectedSize) selected for removal")
                    .foregroundStyle(.secondary)

                Button {
                    viewModel.confirmDelete()
                } label: {
                    Label("Remove Duplicates", systemImage: "trash.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding(16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.on.doc.fill")
                .font(.system(size: 60))
                .foregroundStyle(.pink.opacity(0.5))
            Text("No duplicates found")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Click Scan to search for duplicate files")
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
