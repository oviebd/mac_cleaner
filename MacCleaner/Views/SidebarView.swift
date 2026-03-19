import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: SidebarTab

    var body: some View {
        List(selection: $selectedTab) {
            Section {
                ForEach([SidebarTab.dashboard, .cleanup, .diskMap]) { tab in
                    sidebarItem(tab)
                }
            } header: {
                Text("Overview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                ForEach([SidebarTab.largeFiles, .duplicates]) { tab in
                    sidebarItem(tab)
                }
            } header: {
                Text("Analyze")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                sidebarItem(.settings)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 4) {
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.blue)
                Text(AppConstants.appName)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
        }
    }

    private func sidebarItem(_ tab: SidebarTab) -> some View {
        Label(tab.rawValue, systemImage: tab.systemImage)
            .tag(tab)
            .foregroundStyle(selectedTab == tab ? tab.color : .primary)
    }
}
