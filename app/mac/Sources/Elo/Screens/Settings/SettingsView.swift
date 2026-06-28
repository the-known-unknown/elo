import SwiftUI

/// Settings screen. Intentionally empty for now — content to be added later.
struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Coming soon.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(width: 420, height: 300)
    }
}
