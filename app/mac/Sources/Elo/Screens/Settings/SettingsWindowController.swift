import SwiftUI

/// The Settings window. Behavior (lazy build, size-to-content, center, focus)
/// comes from `AppWindowController`; this just supplies the title and content.
final class SettingsWindowController: AppWindowController {
    override var title: String { "\(AppInfo.name) Settings" }

    override func makeContentView() -> AnyView {
        AnyView(SettingsView())
    }
}
