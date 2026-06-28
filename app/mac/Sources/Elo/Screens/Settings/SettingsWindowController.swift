import AppKit
import SwiftUI

/// Manages the Settings window. Elo is a background agent (no standard windows),
/// so we build the window lazily and bring the app forward to display it. The
/// window is reused: a second "Settings" click just re-focuses the existing one.
final class SettingsWindowController {
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
        let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
        window.title = "\(AppInfo.name) Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false  // we keep our own reference and reuse it
        return window
    }
}
