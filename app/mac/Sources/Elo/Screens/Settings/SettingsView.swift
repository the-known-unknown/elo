import SwiftUI

/// Root of the Settings window. Hosts the three setting areas as tabs and
/// switches between their views. Each tab's content lives in its own view.
struct SettingsView: View {
    let hotkeyStore: HotkeyStore

    var body: some View {
        TabView {
            ApplicationSettingsView(hotkeyStore: hotkeyStore)
                .tabItem { Label("Application", systemImage: "macwindow") }

            AIModelsSettingsView()
                .tabItem { Label("AI Models", systemImage: "brain") }
        }
        .frame(width: 520, height: 560)
    }
}
