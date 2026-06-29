import SwiftUI

/// Root of the Settings window. Hosts the three setting areas as tabs and
/// switches between their views. Each tab's content lives in its own view.
struct SettingsView: View {
    var body: some View {
        TabView {
            ApplicationSettingsView()
                .tabItem { Label("Application", systemImage: "macwindow") }

            FunctionsSettingsView()
                .tabItem { Label("Functions", systemImage: "function") }

            AIModelsSettingsView()
                .tabItem { Label("AI Models", systemImage: "brain") }
        }
        .frame(width: 520, height: 560)
    }
}
