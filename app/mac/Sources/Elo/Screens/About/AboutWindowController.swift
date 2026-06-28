import AppKit
import SwiftUI

/// Manages the About window. Elo is a background agent (no standard windows), so
/// we build the window lazily and bring the app forward to display it. The window
/// is reused: a second "About" click just re-focuses the existing one.
final class AboutWindowController {
    private var window: NSWindow?

    func show() {
        if window == nil {
            window = makeWindow()
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(rootView: AboutView()))
        window.title = "About \(AppInfo.name)"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false  // we keep our own reference and reuse it
        return window
    }
}
