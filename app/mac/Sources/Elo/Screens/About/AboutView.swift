import SwiftUI

/// Simple About screen: app name, version, and copyright. All values come from
/// `AppInfo` (sourced from Info.plist).
struct AboutView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

            Text(AppInfo.name)
                .font(.title2)
                .fontWeight(.semibold)

            Text("Version \(AppInfo.version) (\(AppInfo.build))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !AppInfo.copyright.isEmpty {
                Text(AppInfo.copyright)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(28)
        .frame(width: 320, height: 220)
    }
}
