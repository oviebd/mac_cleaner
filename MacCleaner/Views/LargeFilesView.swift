import SwiftUI

struct LargeFilesView: View {
    @State private var viewModel = LargeFilesViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if viewModel.isScanning {
                scanningSection
            } else if viewModel.files.isEmpty {
                emptyState
            } else {
                filesList
            }

            Divider()
            bottomBar
        }
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .sheet(isPresented: $viewModel.showDeleteConfirmation) {
            DeleteConfirmationView(
                title: "Delete Large Files",
                message: "You are about to move \(viewModel.selectedFiles.count) files (\(viewModel.formattedSelectedSize)) to Trash.",
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
                Text("Large Files")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Find and remove space-hogging files")
                    .foregroundStyle(.secondary)
            }
            Spacer()

            Picker("Threshold", selection: $viewModel.threshold) {
                ForEach(viewModel.thresholdOptions, id: \.1) { name, value in
                    Text(name).tag(value)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)

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
            Text("Scanning for large files...")
                .font(.title3)
                .fontWeight(.medium)
            Text("\(viewModel.filesScanned) files scanned")
                .foregroundStyle(.secondary)
            Text(viewModel.currentPath)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Files List

    private var filesList: some View {
        Table(viewModel.sortedFiles, selection: $viewModel.selectedFiles) {
            TableColumn("") { file in
                Image(systemName: file.icon)
                    .foregroundStyle(.orange)
            }
            .width(24)

            TableColumn("Name") { file in
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .lineLimit(1)
                    Text(file.url.deletingLastPathComponent().path)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .width(min: 200, ideal: 300)

            TableColumn("Size") { file in
                Text(file.formattedSize)
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
            }
            .width(80)

            TableColumn("Modified") { file in
                if let date = file.lastModified {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("--")
                        .foregroundStyle(.tertiary)
                }
            }
            .width(100)

            TableColumn("Type") { file in
                Text(file.fileExtension.uppercased())
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
            .width(60)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if !viewModel.files.isEmpty {
                Text("\(viewModel.files.count) large files found")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.isCleaning {
                ProgressView()
                    .controlSize(.small)
                Text("Moving to Trash...")
            } else if !viewModel.selectedFiles.isEmpty {
                Text("\(viewModel.selectedFiles.count) selected (\(viewModel.formattedSelectedSize))")
                    .foregroundStyle(.secondary)

                Button {
                    viewModel.confirmDelete()
                } label: {
                    Label("Move to Trash", systemImage: "trash.fill")
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
            Image(systemName: "doc.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange.opacity(0.5))
            Text("No large files found")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Click Scan to search for files above \(FileSizeFormatter.format(viewModel.threshold))")
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
