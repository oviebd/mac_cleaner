import SwiftUI

struct SettingsView: View {
    @AppStorage("largeFileThreshold") private var threshold: Int = 100
    @AppStorage("skipHiddenFiles") private var skipHiddenFiles = true
    @AppStorage("moveToTrash") private var moveToTrash = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                generalSection
                scanSection
                cleanupSection
                aboutSection
            }
            .padding(24)
        }
        .background(Color(.windowBackgroundColor).opacity(0.5))
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Configure application preferences")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var generalSection: some View {
        settingsCard(title: "General", icon: "gearshape.fill", color: .gray) {
            VStack(spacing: 12) {
                settingRow(
                    title: "Skip Hidden Files",
                    description: "Ignore files and folders starting with a dot"
                ) {
                    Toggle("", isOn: $skipHiddenFiles)
                        .toggleStyle(.switch)
                }

                Divider()

                settingRow(
                    title: "Deletion Method",
                    description: moveToTrash ? "Files will be moved to Trash (recoverable)" : "Files will be permanently deleted"
                ) {
                    Toggle("Move to Trash", isOn: $moveToTrash)
                        .toggleStyle(.switch)
                }
            }
        }
    }

    private var scanSection: some View {
        settingsCard(title: "Scanning", icon: "magnifyingglass", color: .blue) {
            VStack(spacing: 12) {
                settingRow(
                    title: "Large File Threshold",
                    description: "Files above this size will appear in Large Files"
                ) {
                    Picker("", selection: $threshold) {
                        Text("50 MB").tag(50)
                        Text("100 MB").tag(100)
                        Text("250 MB").tag(250)
                        Text("500 MB").tag(500)
                        Text("1 GB").tag(1024)
                    }
                    .frame(width: 120)
                }
            }
        }
    }

    private var cleanupSection: some View {
        settingsCard(title: "Cleanup Targets", icon: "bubbles.and.sparkles.fill", color: .green) {
            VStack(alignment: .leading, spacing: 8) {
                Text("The following directories are scanned for cleanup:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(AppConstants.safeDirectories, id: \.self) { dir in
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Text("~/" + dir)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
        }
    }

    private var aboutSection: some View {
        settingsCard(title: "About", icon: "info.circle.fill", color: .purple) {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    Image(systemName: "externaldrive.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(AppConstants.appName)
                            .font(.headline)
                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("A fast, safe disk cleaner for macOS")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func settingsCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func settingRow<Trailing: View>(
        title: String,
        description: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            trailing()
        }
    }
}
