import SwiftUI

/// The About window. Behavior (lazy build, size-to-content, center, focus) comes
/// from `AppWindowController`; this just supplies the title and content.
final class AboutWindowController: AppWindowController {
    override var title: String { "About \(AppInfo.name)" }

    override func makeContentView() -> AnyView {
        AnyView(AboutView())
    }
}
