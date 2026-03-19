import SwiftUI

@main
struct MacCleanerApp: App {
    @State private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 720)
    }
}
