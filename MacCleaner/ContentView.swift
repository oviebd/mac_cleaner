import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        @Bindable var vm = appViewModel

        NavigationSplitView {
            SidebarView(selectedTab: $vm.selectedTab)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            Group {
                switch appViewModel.selectedTab {
                case .dashboard:
                    DashboardView()
                case .cleanup:
                    CleanupView()
                case .diskMap:
                    DiskMapView()
                case .largeFiles:
                    LargeFilesView()
                case .duplicates:
                    DuplicatesView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
